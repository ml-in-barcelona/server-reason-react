open Ppxlib
module Builder = Ast_builder.Default
module String_set = Set.Make (String)

type target = Native | Js

let mode = ref Native
let browser_ppx = "browser_ppx"
let browser_only = "browser_only"
let platform_tag = "platform"
let is_platform_tag str = String.equal str browser_ppx || String.equal str browser_only || String.equal str platform_tag

(* Pre-scans the structure for top-level names declared under `[@platform js]`
   (or `[@@platform js]` / `[@@browser_only]`). These names exist only on the
   JavaScript build, so on Native they are dropped by [Preprocess.traverse].
   When [Browser_only.make_new_body] collects body identifiers to reference
   via `let _ = ident`, names in this set must be excluded \u2014 referencing
   them would fail to compile on native because the binding was dropped.

   The set is populated by an [Instrument] hook that runs BEFORE the
   context-free rules. *)
module Platform_js_scope = struct
  let restricted_names : String_set.t ref = ref String_set.empty
  let reset () = restricted_names := String_set.empty
  let add name = restricted_names := String_set.add name !restricted_names
  let mem name = String_set.mem name !restricted_names

  (* True when [attrs] contains an attribute that drops the item on Native. *)
  let attrs_drop_on_native (attrs : attributes) : bool =
    List.exists
      (fun attr ->
        match (attr.attr_name.txt, attr.attr_payload) with
        | "browser_only", _ -> true
        | "platform", PStr [ { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_ident { txt = Lident "js"; _ }; _ }, []); _ } ]
          ->
            true
        | _ -> false)
      attrs

  let rec collect_pattern_names (pat : Parsetree.pattern) : string list =
    match pat.ppat_desc with
    | Ppat_var { txt; _ } -> [ txt ]
    | Ppat_alias (p, { txt; _ }) -> txt :: collect_pattern_names p
    | Ppat_tuple ps | Ppat_array ps -> List.concat_map collect_pattern_names ps
    | Ppat_record (fs, _) -> List.concat_map (fun (_, p) -> collect_pattern_names p) fs
    | Ppat_construct (_, Some (_, p)) -> collect_pattern_names p
    | Ppat_variant (_, Some p) -> collect_pattern_names p
    | Ppat_or (p1, p2) -> collect_pattern_names p1 @ collect_pattern_names p2
    | Ppat_constraint (p, _) | Ppat_lazy p | Ppat_open (_, p) | Ppat_exception p -> collect_pattern_names p
    | _ -> []

  (* Walks a pattern collecting names that have `[@browser_only]` or
     `[@platform js]` attached anywhere in the pattern tree. These names
     exist only on JS and must be excluded from the let-chain. *)
  let rec scan_pattern_for_restricted (pat : Parsetree.pattern) : unit =
    if attrs_drop_on_native pat.ppat_attributes then List.iter add (collect_pattern_names pat);
    match pat.ppat_desc with
    | Ppat_alias (p, _) | Ppat_constraint (p, _) | Ppat_lazy p | Ppat_open (_, p) | Ppat_exception p ->
        scan_pattern_for_restricted p
    | Ppat_tuple ps | Ppat_array ps -> List.iter scan_pattern_for_restricted ps
    | Ppat_record (fs, _) -> List.iter (fun (_, p) -> scan_pattern_for_restricted p) fs
    | Ppat_construct (_, Some (_, p)) -> scan_pattern_for_restricted p
    | Ppat_variant (_, Some p) -> scan_pattern_for_restricted p
    | Ppat_or (p1, p2) ->
        scan_pattern_for_restricted p1;
        scan_pattern_for_restricted p2
    | _ -> ()

  (* Walks expressions inside the structure to find inner [@browser_only]
     pattern attributes (e.g. `let (a, [@browser_only] b) = ...` inside a
     function body). *)
  class restricted_pattern_collector =
    object
      inherit Ast_traverse.iter as super

      method! pattern p =
        scan_pattern_for_restricted p;
        super#pattern p
    end

  let pattern_collector = new restricted_pattern_collector

  let rec scan_structure (str : structure) : unit = List.iter scan_structure_item str

  and scan_structure_item (stri : structure_item) : unit =
    match stri.pstr_desc with
    | Pstr_value (_rec_flag, vbs) ->
        List.iter
          (fun vb -> if attrs_drop_on_native vb.pvb_attributes then List.iter add (collect_pattern_names vb.pvb_pat))
          vbs
    | Pstr_primitive { pval_name = { txt; _ }; pval_attributes = attrs; _ } ->
        if attrs_drop_on_native attrs then add txt
    | Pstr_module { pmb_attributes = attrs; pmb_expr; _ } -> (
        if attrs_drop_on_native attrs then ()
          (* The module binding is dropped on native, so its top-level name is
             still visible as a Ldot path \u2014 we don't add it. But if the user
             does `open M` and then uses `foo` from inside M, we'd need to
             know about M's contents. We don't try to handle that case;
             users opening JS-only modules at module scope would already have
             other compile issues. *)
        else
          (* Scan inside the module for nested [@platform js] declarations. *)
          match pmb_expr.pmod_desc with
          | Pmod_structure str -> scan_structure str
          | _ -> ())
    | Pstr_recmodule mbs ->
        List.iter
          (fun mb ->
            if not (attrs_drop_on_native mb.pmb_attributes) then
              match mb.pmb_expr.pmod_desc with Pmod_structure str -> scan_structure str | _ -> ())
          mbs
    | Pstr_attribute attr when is_platform_tag attr.attr_name.txt ->
        (* [@@@platform js] floating attribute drops everything until the next
           floating attribute. We do NOT model this scope because nested
           floating-attribute regions are unusual and not present in the
           codebase we're targeting. *)
        let _ = attr in
        ()
    | Pstr_extension (({ txt = "browser_only"; _ }, payload), _attrs) -> (
        (* `let%browser_only name = ...` at structure level. The name still
           exists on native (as a stub that raises at runtime), but referencing
           it would trip the `(alert browser_only)` attached to its pattern.
           Treat such names as restricted so [Body_free_idents.collect] omits
           them from any generated `let _ = ident` chain. *)
        match payload with
        | PStr [ { pstr_desc = Pstr_value (_, vbs); _ } ] ->
            List.iter (fun vb -> List.iter add (collect_pattern_names vb.pvb_pat)) vbs
        | _ -> ())
    | _ -> ()

  let instrument_pre_pass (_ctx : Expansion_context.Base.t) (str : structure) : structure =
    reset ();
    (match !mode with
    | Native ->
        scan_structure str;
        (* Also walk all expressions for inner pattern attributes like
           `let (a, [@browser_only] b) = ...` *)
        pattern_collector#structure str
    | Js -> ());
    str
end

(* Helpers used by [make_native_replacement] to produce the let-chain that
   references function arguments and free body identifiers, and to preserve
   local `let open` declarations from the original body. *)
module Argument_references = struct
  let rec extract_pattern_names (pattern : Parsetree.pattern) : string list =
    match pattern.ppat_desc with
    | Ppat_var { txt; _ } -> [ txt ]
    | Ppat_alias (pat, { txt; _ }) -> txt :: extract_pattern_names pat
    | Ppat_tuple patterns -> List.concat_map extract_pattern_names patterns
    | Ppat_array patterns -> List.concat_map extract_pattern_names patterns
    | Ppat_record (fields, _) -> List.concat_map (fun (_, pat) -> extract_pattern_names pat) fields
    | Ppat_construct (_, Some (_, pat)) -> extract_pattern_names pat
    | Ppat_variant (_, Some pat) -> extract_pattern_names pat
    | Ppat_or (p1, p2) -> extract_pattern_names p1 @ extract_pattern_names p2
    | Ppat_constraint (pat, _) -> extract_pattern_names pat
    | Ppat_lazy pat -> extract_pattern_names pat
    | Ppat_open (_, pat) -> extract_pattern_names pat
    | Ppat_exception pat -> extract_pattern_names pat
    | Ppat_any | Ppat_constant _ | Ppat_interval _
    | Ppat_construct (_, None)
    | Ppat_variant (_, None)
    | Ppat_type _ | Ppat_unpack _ | Ppat_extension _ ->
        []

  (* Walks the expression collecting `Pexp_open` nodes (in source order) so they
     can be re-emitted around the generated let-chain. *)
  let rec extract_local_opens (expr : Parsetree.expression) : open_declaration list =
    match expr.pexp_desc with
    | Pexp_open (decl, body) -> decl :: extract_local_opens body
    | Pexp_let (_, _, body) -> extract_local_opens body
    | Pexp_sequence (e1, e2) -> extract_local_opens e1 @ extract_local_opens e2
    | Pexp_constraint (e, _) -> extract_local_opens e
    | Pexp_newtype (_, e) -> extract_local_opens e
    | _ -> []

  let starts_with_underscore (name : string) : bool = String.length name > 0 && Char.equal name.[0] '_'

  let is_operator_name (name : string) : bool =
    String.length name > 0
    &&
    let c = name.[0] in
    not (Char.equal c '_' || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'))

  (* Names to skip from the let-chain:
     - Underscore-prefixed (idiomatic "intentionally unused", don't trigger 27).
     - Operator names (always Stdlib functions, never trigger 26/27).
     - Names declared under `[@platform js]` (would not exist on native). *)
  let should_skip (name : string) : bool =
    starts_with_underscore name || is_operator_name name || Platform_js_scope.mem name
end

(* Walks an expression collecting unqualified `Lident` references that are
   free in the expression (not bound by enclosing lets/funs/match/try/for/
   letmodule/letexception/letop). Qualified `Ldot` paths are skipped because
   they often reference platform-restricted modules that may not exist on
   native; the resulting let-chain only references the local Lidents the
   user is most likely to want silenced.

   Treats `Pexp_extension` and `Pexp_open` as opaque (does not recurse). *)
module Body_free_idents = struct
  type state = { used : string list; bound : String_set.t }

  let empty = { used = []; bound = String_set.empty }
  let add_used name s = if String_set.mem name s.bound then s else { s with used = name :: s.used }
  let add_bound names s = { s with bound = String_set.add_seq (List.to_seq names) s.bound }

  let with_bound names s f =
    let saved = s.bound in
    let s = add_bound names s in
    let s = f s in
    { s with bound = saved }

  let extract_pattern_names = Argument_references.extract_pattern_names

  let rec extract_param_names (expr : Parsetree.expression) : string list =
    match expr.pexp_desc with
    | Pexp_function (params, _, body_or_cases) ->
        let from_params =
          List.concat_map
            (fun (p : Parsetree.function_param) ->
              match p.pparam_desc with
              | Pparam_val (_, _, pat) -> extract_pattern_names pat
              | Pparam_newtype { txt; _ } -> [ txt ])
            params
        in
        let from_body =
          match body_or_cases with Pfunction_body body -> extract_param_names body | Pfunction_cases _ -> []
        in
        from_params @ from_body
    | Pexp_constraint (e, _) -> extract_param_names e
    | Pexp_newtype ({ txt; _ }, e) -> txt :: extract_param_names e
    | _ -> []

  let rec collect_expr (expr : Parsetree.expression) (s : state) : state =
    match expr.pexp_desc with
    | Pexp_ident { txt = Lident name; _ } -> add_used name s
    | Pexp_ident _ -> s (* Skip qualified Ldot/Lapply paths *)
    | Pexp_constant _ -> s
    | Pexp_let (rec_flag, vbs, body) ->
        let new_names = List.concat_map (fun vb -> extract_pattern_names vb.pvb_pat) vbs in
        let s_with_rec = match rec_flag with Recursive -> add_bound new_names s | Nonrecursive -> s in
        let s_after_rhs =
          List.fold_left
            (fun acc vb ->
              let rhs_params = extract_param_names vb.pvb_expr in
              with_bound rhs_params acc (fun acc -> collect_expr vb.pvb_expr acc))
            s_with_rec vbs
        in
        let s_for_body =
          match rec_flag with Recursive -> s_after_rhs | Nonrecursive -> add_bound new_names s_after_rhs
        in
        let after = collect_expr body s_for_body in
        { after with bound = s.bound }
    | Pexp_function (params, _, body_or_cases) ->
        let pnames, s' =
          List.fold_left
            (fun (names, acc) (p : Parsetree.function_param) ->
              match p.pparam_desc with
              | Pparam_val (_, default_arg, pat) ->
                  let pat_names = extract_pattern_names pat in
                  let acc = match default_arg with None -> acc | Some e -> collect_expr e acc in
                  (names @ pat_names, acc)
              | Pparam_newtype { txt; _ } -> (names @ [ txt ], acc))
            ([], s) params
        in
        let after =
          with_bound pnames s' (fun acc ->
              match body_or_cases with
              | Pfunction_body body -> collect_expr body acc
              | Pfunction_cases (cases, _, _) -> collect_cases cases acc)
        in
        { after with bound = s.bound }
    | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Lident "##"; _ }; _ }, [ (Nolabel, obj); (Nolabel, _method_name) ])
      ->
        (* `obj##method_name` (melange JS object access). The method name is
           syntactically a `Pexp_ident` but semantically it's a label, not a
           value reference. Walk only the object part. *)
        collect_expr obj s
    | Pexp_apply (fn, args) ->
        let s = collect_expr fn s in
        List.fold_left (fun acc (_, e) -> collect_expr e acc) s args
    | Pexp_match (e, cases) | Pexp_try (e, cases) -> collect_cases cases (collect_expr e s)
    | Pexp_tuple es | Pexp_array es -> List.fold_left (fun acc e -> collect_expr e acc) s es
    | Pexp_construct (_, None) | Pexp_variant (_, None) -> s
    | Pexp_construct (_, Some e) | Pexp_variant (_, Some e) -> collect_expr e s
    | Pexp_record (fields, base) ->
        let s = match base with None -> s | Some e -> collect_expr e s in
        List.fold_left (fun acc (_, e) -> collect_expr e acc) s fields
    | Pexp_field (e, _) -> collect_expr e s
    | Pexp_setfield (e1, _, e2) -> collect_expr e2 (collect_expr e1 s)
    | Pexp_ifthenelse (c, t, None) -> collect_expr t (collect_expr c s)
    | Pexp_ifthenelse (c, t, Some e) -> collect_expr e (collect_expr t (collect_expr c s))
    | Pexp_sequence (e1, e2) -> collect_expr e2 (collect_expr e1 s)
    | Pexp_while (c, body) -> collect_expr body (collect_expr c s)
    | Pexp_for (pat, e1, e2, _, body) ->
        let loop_names = extract_pattern_names pat in
        let s = collect_expr e1 s in
        let s = collect_expr e2 s in
        with_bound loop_names s (fun acc -> collect_expr body acc)
    | Pexp_constraint (e, _) | Pexp_coerce (e, _, _) | Pexp_send (e, _) -> collect_expr e s
    | Pexp_setinstvar (_, e) -> collect_expr e s
    | Pexp_override fields -> List.fold_left (fun acc (_, e) -> collect_expr e acc) s fields
    | Pexp_letmodule ({ txt; _ }, _, body) ->
        let names = match txt with Some n -> [ n ] | None -> [] in
        with_bound names s (fun acc -> collect_expr body acc)
    | Pexp_letexception (ext, body) -> with_bound [ ext.pext_name.txt ] s (fun acc -> collect_expr body acc)
    | Pexp_assert e | Pexp_lazy e | Pexp_poly (e, _) -> collect_expr e s
    | Pexp_newtype ({ txt; _ }, e) -> with_bound [ txt ] s (fun acc -> collect_expr e acc)
    (* Local opens are re-emitted around the let-chain (see [extract_local_opens]).
       Don't recurse into the open body for free-ident collection because names
       brought into scope by the open can't be referenced via let _ = on the
       outside without the surrounding open. *)
    | Pexp_open (_, _) -> s
    | Pexp_letop { let_; ands; body } ->
        let s = collect_expr let_.pbop_exp s in
        let s = List.fold_left (fun acc a -> collect_expr a.pbop_exp acc) s ands in
        let names =
          extract_pattern_names let_.pbop_pat @ List.concat_map (fun a -> extract_pattern_names a.pbop_pat) ands
        in
        with_bound names s (fun acc -> collect_expr body acc)
    | Pexp_extension (_, payload) -> (
        (* Recurse into extension payloads to find free idents. Extension
           payloads frequently contain user code (e.g. `[%mel.obj { foo;
           bar = baz }]` references `foo`, `baz` as free idents). We don't
           know in advance which extensions are "code" vs. which are
           "data", but recursing into the payload's expression form is
           safe \u2014 we just walk what's there. *)
        match payload with
        | PStr items ->
            List.fold_left
              (fun acc item -> match item.pstr_desc with Pstr_eval (e, _) -> collect_expr e acc | _ -> acc)
              s items
        | _ -> s)
    | Pexp_pack _ | Pexp_unreachable | Pexp_object _ | Pexp_new _ -> s

  and collect_cases (cases : Parsetree.case list) (s : state) : state =
    List.fold_left
      (fun acc case ->
        let case_names = extract_pattern_names case.pc_lhs in
        with_bound case_names acc (fun acc ->
            let acc = match case.pc_guard with None -> acc | Some g -> collect_expr g acc in
            collect_expr case.pc_rhs acc))
      s cases

  (* Returns free-ident names in source order, deduped, with skip filters
     applied (operators, underscore-prefixed, [@platform js]-restricted). *)
  let collect ~bound_initial (expr : Parsetree.expression) : string list =
    let initial = add_bound bound_initial empty in
    let final = collect_expr expr initial in
    let used_in_source_order = List.rev final.used in
    (* Dedupe while preserving order, applying skip filters. *)
    let seen = Hashtbl.create 16 in
    let out = ref [] in
    List.iter
      (fun name ->
        if (not (Hashtbl.mem seen name)) && not (Argument_references.should_skip name) then begin
          Hashtbl.add seen name ();
          out := name :: !out
        end)
      used_in_source_order;
    List.rev !out
end

module Platform = struct
  let pattern = Ast_pattern.(__')

  let collect_expressions ~loc first second =
    match (first.pc_lhs.ppat_desc, second.pc_lhs.ppat_desc) with
    | ( Ppat_construct ({ txt = Lident "Server" | Ldot (Lident "Runtime", "Server"); _ }, _),
        Ppat_construct ({ txt = Lident "Client" | Ldot (Lident "Runtime", "Client"); _ }, _) ) ->
        Ok (first.pc_rhs, second.pc_rhs)
    | ( Ppat_construct ({ txt = Lident "Client" | Ldot (Lident "Runtime", "Client"); _ }, _),
        Ppat_construct ({ txt = Lident "Server" | Ldot (Lident "Runtime", "Server"); _ }, _) ) ->
        Ok (second.pc_rhs, first.pc_rhs)
    | _ -> Error [%expr [%ocaml.error "[browser_only] switch%platform requires 2 cases: `Server` and `Client`"]]

  let switch_platform_requires_a_match ~loc =
    [%expr [%ocaml.error "[browser_ppx] switch%platform requires a match expression"]]

  (* Prepends `let _ = ident in ...` references for each free unqualified
     Lident in the dropped branch, so outer let-bindings or function
     arguments whose only consumer was inside that branch don't trigger
     warnings 26/27 on the surviving side.

     Skip filters (via [Body_free_idents.collect]):
     - Operators and underscore-prefixed names.
     - Names declared under `[@platform js]` or `let%browser_only` in the
       same structure: these either don't exist on native or carry an
       `(alert browser_only)` on their pattern, so referencing them would
       break compilation. Their own bindings already suppress unused-warnings
       via [@@warning ...].

     The generated chain is wrapped with `[@alert "-browser_only"]` as a
     safety net for cases the skip filter cannot catch: names brought into
     scope via `open` from a module exporting `let%browser_only` bindings,
     or any other identifier the user has manually annotated with the
     `browser_only` alert. *)
  let wrap_with_dropped_branch_refs ~loc ~dropped_expr ~kept_expr =
    let body_idents = Body_free_idents.collect ~bound_initial:[] dropped_expr in
    let chain =
      List.fold_right
        (fun name acc ->
          let id = Builder.pexp_ident ~loc { txt = Lident name; loc } in
          [%expr
            let _ = [%e id] in
            [%e acc]])
        body_idents kept_expr
    in
    match body_idents with
    | [] -> chain
    | _ ->
        let suppress_attr =
          Builder.attribute ~loc ~name:{ txt = "alert"; loc } ~payload:(PStr [ [%stri "-browser_only"] ])
        in
        { chain with pexp_attributes = suppress_attr :: chain.pexp_attributes }

  let handler ~ctxt:_ { txt = payload; loc } =
    match payload with
    | PStr [ { pstr_desc = Pstr_eval (expression, _); _ } ] -> (
        match expression.pexp_desc with
        | Pexp_match (_expression, cases) -> (
            match cases with
            | [ first; second ] -> (
                match collect_expressions ~loc first second with
                | Ok (server_expr, client_expr) -> (
                    match !mode with
                    | Js -> wrap_with_dropped_branch_refs ~loc ~dropped_expr:server_expr ~kept_expr:client_expr
                    | Native -> wrap_with_dropped_branch_refs ~loc ~dropped_expr:client_expr ~kept_expr:server_expr)
                | Error error_msg_expr -> error_msg_expr)
            | _ -> switch_platform_requires_a_match ~loc)
        | _ -> switch_platform_requires_a_match ~loc)
    | _ -> switch_platform_requires_a_match ~loc

  let rule = Context_free.Rule.extension (Extension.V3.declare "platform" Extension.Context.expression pattern handler)
end

module Browser_only = struct
  let get_function_name pattern = match pattern with Ppat_var { txt = name; _ } -> name | _ -> "<unknown>"

  (* Compile-time error returned for [%browser_only ...] / let%browser_only
     RHSes that aren't functions or simple identifier re-exports. The user
     should reach for [switch%platform] or [\[@platform js\]] instead. *)
  let error_only_works_on ~loc =
    [%expr
      [%ocaml.error
        "[browser_ppx] browser_only only works on function definitions or simple identifier re-exports. For other \
         cases, use switch%platform or [@platform js] to conditionally include the binding based on the platform."]]

  (* Build the `let _ = arg1 in let _ = arg2 in ... raise` chain. *)
  let build_let_chain ~loc ~name (arg_names : string list) =
    let raise_expr = [%expr Runtime.fail_impossible_action_in_ssr [%e Builder.estring ~loc name]] in
    List.fold_right
      (fun arg_name acc ->
        let ident_expr = Builder.pexp_ident ~loc { txt = Lident arg_name; loc } in
        [%expr
          let _ = [%e ident_expr] in
          [%e acc]])
      arg_names raise_expr

  (* Wrap with re-emitted local opens. *)
  let wrap_with_local_opens ~loc opens body =
    List.fold_right (fun decl acc -> Builder.pexp_open ~loc decl acc) opens body

  (* Compute the list of names to reference via `let _ = name`, in order:
       1. Args (declaration order)
       2. Body free idents (source order)
     Deduped across both categories. Underscore-prefixed, operator-named,
     and [@platform js]-restricted names are filtered out. *)
  let compute_references ~(arg_names : string list) ~(body_idents : string list) : string list =
    let seen = Hashtbl.create 16 in
    let out = ref [] in
    let push name =
      if (not (Hashtbl.mem seen name)) && not (Argument_references.should_skip name) then begin
        Hashtbl.add seen name ();
        out := name :: !out
      end
    in
    List.iter push arg_names;
    List.iter push body_idents;
    List.rev !out

  (* Walks the original RHS expression peeling Pexp_function / Pexp_newtype /
     Pexp_constraint layers. Returns:
       - the list of function_params (to preserve as arguments)
       - the innermost body expression (to replace)
       - whether at least one Pexp_function layer was peeled
     The "shape rebuilder" function is composed during walking so we can
     rebuild the same structure with a new body. Outer Pexp_constraint
     layers are dropped (return type / outer binding annotation). *)
  type peeled = {
    rebuild : Parsetree.expression -> Parsetree.expression;
    body : Parsetree.expression;
    arg_patterns : Parsetree.pattern list;
    has_function_layer : bool;
  }

  let peel_layers (expr : Parsetree.expression) : peeled =
    let rec loop expr ~rebuild ~arg_patterns ~has_fn =
      match expr.pexp_desc with
      | Pexp_constraint (inner, _) ->
          (* Drop outer constraints (return type / outer binding annotation). *)
          loop inner ~rebuild ~arg_patterns ~has_fn
      | Pexp_function (params, _constraint_, Pfunction_body body) ->
          let attrs = expr.pexp_attributes in
          let pexp_loc = expr.pexp_loc in
          let new_arg_patterns =
            arg_patterns
            @ List.filter_map
                (fun (p : Parsetree.function_param) ->
                  match p.pparam_desc with Pparam_val (_, _, pat) -> Some pat | Pparam_newtype _ -> None)
                params
          in
          let rebuild' new_body =
            let fn_expr =
              {
                pexp_desc = Pexp_function (params, None, Pfunction_body new_body);
                pexp_loc;
                pexp_loc_stack = expr.pexp_loc_stack;
                pexp_attributes = attrs;
              }
            in
            rebuild fn_expr
          in
          loop body ~rebuild:rebuild' ~arg_patterns:new_arg_patterns ~has_fn:true
      | Pexp_function (_, _, Pfunction_cases _) ->
          (* `function | A -> ... | B x -> ...`: no further peeling, body is the cases themselves.
             We'll synthesize a `fun _ -> raise` shape, dropping the cases entirely. *)
          { rebuild; body = expr; arg_patterns; has_function_layer = has_fn }
      | Pexp_newtype (name, inner) ->
          let attrs = expr.pexp_attributes in
          let pexp_loc = expr.pexp_loc in
          let rebuild' new_body =
            let nt_expr =
              {
                pexp_desc = Pexp_newtype (name, new_body);
                pexp_loc;
                pexp_loc_stack = expr.pexp_loc_stack;
                pexp_attributes = attrs;
              }
            in
            rebuild nt_expr
          in
          loop inner ~rebuild:rebuild' ~arg_patterns ~has_fn
      | _ -> { rebuild; body = expr; arg_patterns; has_function_layer = has_fn }
    in
    loop expr ~rebuild:(fun e -> e) ~arg_patterns:[] ~has_fn:false

  (* Build the new body that replaces the original.

     References:
     - Each function argument via `let _ = arg` (silences warning 27).
     - Each free unqualified Lident in the original body (silences warnings
       26/27/32 on outer let-bindings whose only consumers are inside this
       browser_only context).

     Skipped:
     - Qualified Ldot paths (e.g. `Webapi.Dom.fetch`): may not exist on native.
     - Names declared `[@platform js]`: dropped on native (referencing them
       would break compilation).
     - Operators and underscore-prefixed names.

     Local opens from the original body are re-emitted around the let-chain
     to preserve any scope the user introduced. *)
  let make_new_body ~loc ~name ~(peeled : peeled) : Parsetree.expression =
    let arg_names = List.concat_map Argument_references.extract_pattern_names peeled.arg_patterns in
    let body_idents = Body_free_idents.collect ~bound_initial:arg_names peeled.body in
    let refs = compute_references ~arg_names ~body_idents in
    let local_opens = Argument_references.extract_local_opens peeled.body in
    let chain = build_let_chain ~loc ~name refs in
    wrap_with_local_opens ~loc local_opens chain

  (* The main entry point: takes the original RHS and produces the native
     replacement.

     Valid shapes:
     - Functions (Pexp_function with body or cases, possibly wrapped in
       Pexp_constraint/Pexp_newtype): preserve args, replace body with a
       let-chain ending in a runtime raise.
     - Simple identifier re-exports (Pexp_ident, e.g.
       `let%browser_only ofElement = Webapi.X.asHtmlElement`): replace the
       whole RHS with a runtime raise (the original ident is browser-only
       and may not exist on native).

     Anything else (record literals, applications, tuples, control flow,
     etc.) is rejected at compile-time via `error_only_works_on`. The user
     should reach for `switch%platform` or `[@platform js]` instead. *)
  let make_native_replacement ~loc ~name (expr : Parsetree.expression) : Parsetree.expression =
    let peeled = peel_layers expr in
    match peeled.body.pexp_desc with
    | Pexp_function (_, _, Pfunction_cases _) ->
        (* Either bare `function | A -> ... | B x -> ...` (no outer fun layer)
           or `fun a -> function | ...` (outer layers already peeled). In both
           cases, drop the cases and synthesize a wildcard arg. *)
        let new_body = make_new_body ~loc ~name ~peeled in
        peeled.rebuild (Builder.pexp_fun ~loc Nolabel None [%pat? _] new_body)
    | _ when peeled.has_function_layer ->
        let new_body = make_new_body ~loc ~name ~peeled in
        peeled.rebuild new_body
    | Pexp_ident _ ->
        (* Simple identifier re-export: the user wrote
           `let%browser_only x = some_browser_only_ident`. Replace with a
           runtime raise of type `'a` so the binding exists on native (as a
           stub that fails when used) without referencing the original ident
           (which may not exist on native). *)
        [%expr Runtime.fail_impossible_action_in_ssr [%e Builder.estring ~loc name]]
    | _ ->
        (* Anything else is rejected. *)
        error_only_works_on ~loc

  (* The alert attribute we attach to the LHS pattern of generated bindings. *)
  let browser_only_alert_attr ~loc =
    Builder.attribute ~loc ~name:{ txt = "alert"; loc }
      ~payload:
        (PStr
           [
             {
               pstr_desc =
                 Pstr_eval
                   ( {
                       pexp_desc =
                         Pexp_apply
                           ( Builder.pexp_ident ~loc { txt = Lident "browser_only"; loc },
                             [
                               ( Nolabel,
                                 Builder.estring ~loc
                                   "This expression is marked to only run on the browser where JavaScript can run. You \
                                    can only use it inside a let%browser_only function." );
                             ] );
                       pexp_loc = loc;
                       pexp_loc_stack = [];
                       pexp_attributes = [];
                     },
                     [] );
               pstr_loc = loc;
             };
           ])

  let suppress_browser_only_alert ~loc =
    Builder.attribute ~loc ~name:{ txt = "alert"; loc } ~payload:(PStr [ [%stri "-browser_only"] ])

  (* Suppresses warnings on the generated value binding:
     - 26 (unused-var): the binding itself may be unused on native because
       all its references in user code are inside browser_only contexts
       that get dropped. Most common in `let%browser_only` inside a
       function body.
     - 27 (unused-var-strict): the `let _ = arg` chain handles arguments,
       but in some edge cases (like `function | A -> ...` where we
       synthesize a `fun _ -> ...` wrapper) we still want a safety net.
     - 32 (unused-value-declaration): the GENERATED binding itself is
       unused on native if not exported via .mli \u2014 always the case for
       browser-only definitions \u2014 so this fires unconditionally.
     - 33 (unused-open-statement): re-emitted local opens in the body
       may be unused since the body is replaced by a let-chain + raise. *)
  let warnings_attr ~loc =
    Builder.attribute ~loc ~name:{ txt = "warning"; loc } ~payload:(PStr [ [%stri "-26-27-32-33"] ])

  let extractor_single_payload = Ast_pattern.(single_expr_payload __)

  (* For `let%browser_only ... in ...` (a let-binding inside an expression),
     we transform each binding's RHS via make_native_replacement. The body of
     the let-in is preserved unchanged. *)
  let transform_let_in_value_binding (vb : Parsetree.value_binding) : Parsetree.value_binding =
    let loc = vb.pvb_loc in
    let pattern = vb.pvb_pat in
    match pattern with
    | [%pat? ()] -> Builder.value_binding ~loc ~pat:pattern ~expr:[%expr ()]
    | _ ->
        let name = get_function_name pattern.ppat_desc in
        let new_expr = make_native_replacement ~loc ~name vb.pvb_expr in
        let vb' = Builder.value_binding ~loc ~pat:pattern ~expr:new_expr in
        (* The let-in binding may itself be unused on native (the body
           that referenced it is replaced or dropped). Suppress warnings
           26 (unused-var), 27 (unused-var-strict), 32 (unused-value-decl),
           and 33 (unused-open) for the generated binding. *)
        { vb' with pvb_attributes = [ suppress_browser_only_alert ~loc; warnings_attr ~loc ] }

  let expression_handler ~ctxt payload =
    match !mode with
    | Js -> payload
    | Native -> (
        let loc = Expansion_context.Extension.extension_point_loc ctxt in
        match payload.pexp_desc with
        | Pexp_let (rec_flag, value_bindings, body) ->
            (* `let%browser_only ... in body` form: transform each binding's
               RHS individually, but preserve the body untouched. *)
            let new_bindings = List.map transform_let_in_value_binding value_bindings in
            Builder.pexp_let ~loc rec_flag new_bindings body
        | _ ->
            let stringified = Ppxlib.Pprintast.string_of_expression payload in
            make_native_replacement ~loc ~name:stringified payload)

  let expression_rule =
    Context_free.Rule.extension
      (Extension.V3.declare "browser_only" Extension.Context.expression extractor_single_payload expression_handler)

  (* Structure-item form: `let%browser_only fname args = body` (possibly with `rec` and `and`). *)
  let extractor_vb =
    let open Ast_pattern in
    pstr (pstr_value __ __ ^:: nil)

  let structure_item_handler ~ctxt rec_flag value_bindings =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    match !mode with
    | Js ->
        (* Strip the extension and emit the bindings unchanged. *)
        Builder.pstr_value ~loc rec_flag value_bindings
    | Native ->
        let new_bindings =
          List.map
            (fun (vb : Parsetree.value_binding) ->
              let pattern = vb.pvb_pat in
              let name = get_function_name pattern.ppat_desc in
              let new_expr = make_native_replacement ~loc ~name vb.pvb_expr in
              let pattern_with_alert =
                { pattern with ppat_attributes = browser_only_alert_attr ~loc :: pattern.ppat_attributes }
              in
              let expr_with_suppress =
                { new_expr with pexp_attributes = suppress_browser_only_alert ~loc :: new_expr.pexp_attributes }
              in
              let vb' = Builder.value_binding ~loc ~pat:pattern_with_alert ~expr:expr_with_suppress in
              { vb' with pvb_attributes = [ warnings_attr ~loc ] })
            value_bindings
        in
        Builder.pstr_value ~loc rec_flag new_bindings

  let structure_item_rule =
    Context_free.Rule.extension
      (Extension.V3.declare "browser_only" Extension.Context.structure_item extractor_vb structure_item_handler)

  let has_browser_only_attribute expr =
    match expr.pexp_desc with Pexp_extension ({ txt = "browser_only"; _ }, _) -> true | _ -> false

  let use_effect (expr : expression) =
    let add_browser_only_extension expr =
      match expr.pexp_desc with
      | (Pexp_apply (_, [ (Nolabel, effect_body) ]) | Pexp_apply (_, [ (Nolabel, effect_body); _ ]))
        when has_browser_only_attribute effect_body ->
          None
      | Pexp_apply (apply_expr, [ (Nolabel, effect_body); second_arg ]) ->
          let loc = expr.pexp_loc in
          let new_effect_body = [%expr [%browser_only [%e effect_body]]] in
          let new_effect_fun = Builder.pexp_apply ~loc apply_expr [ (Nolabel, new_effect_body); second_arg ] in
          Some new_effect_fun
      | Pexp_apply (apply_expr, [ (Nolabel, effect_body) ]) ->
          let loc = expr.pexp_loc in
          let new_effect_body = [%expr [%browser_only [%e effect_body]]] in
          let new_effect_fun = Builder.pexp_apply ~loc apply_expr [ (Nolabel, new_effect_body) ] in
          Some new_effect_fun
      | _ -> None
    in
    match !mode with Js -> None | Native -> add_browser_only_extension expr

  let use_effects =
    [
      Context_free.Rule.special_function "React.useEffect" use_effect;
      Context_free.Rule.special_function "React.useEffect0" use_effect;
      Context_free.Rule.special_function "React.useEffect1" use_effect;
      Context_free.Rule.special_function "React.useEffect2" use_effect;
      Context_free.Rule.special_function "React.useEffect3" use_effect;
      Context_free.Rule.special_function "React.useEffect4" use_effect;
      Context_free.Rule.special_function "React.useEffect5" use_effect;
      Context_free.Rule.special_function "React.useEffect6" use_effect;
      Context_free.Rule.special_function "React.useEffect7" use_effect;
      Context_free.Rule.special_function "React.useLayoutEffect" use_effect;
      Context_free.Rule.special_function "React.useLayoutEffect0" use_effect;
      Context_free.Rule.special_function "React.useLayoutEffect1" use_effect;
      Context_free.Rule.special_function "React.useLayoutEffect2" use_effect;
      Context_free.Rule.special_function "React.useLayoutEffect3" use_effect;
      Context_free.Rule.special_function "React.useLayoutEffect4" use_effect;
      Context_free.Rule.special_function "React.useLayoutEffect5" use_effect;
      Context_free.Rule.special_function "React.useLayoutEffect6" use_effect;
      Context_free.Rule.special_function "React.useLayoutEffect7" use_effect;
    ]
end

module Preprocess = struct
  (* This module is heavily based on leostera `config.ml` PPX:
     https://github.com/ocaml-sys/config.ml/blob/d248987cc1795de99d3735c06635dbd355d4d642/config/cfg_ppx.ml*)

  let eval_attr attr =
    if not (is_platform_tag attr.attr_name.txt) then `keep
    else
      match (attr.attr_name.txt, attr.attr_payload, !mode) with
      | "browser_only", _, Native
      | ( "platform",
          PStr [ { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_ident { txt = Lident "js"; _ }; _ }, []); _ } ],
          Native )
      | ( "platform",
          PStr [ { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_ident { txt = Lident "native"; _ }; _ }, []); _ } ],
          Js ) ->
          `drop
      | _ -> `keep

  let rec should_keep attrs =
    match attrs with [] -> `keep | attr :: attrs -> if eval_attr attr = `drop then `drop else should_keep attrs

  let rec should_keep_many list fn =
    match list with
    | [] -> `keep
    | item :: list -> if should_keep (fn item) = `drop then `drop else should_keep_many list fn

  let apply_config_on_types (tds : type_declaration list) =
    List.filter_map
      (fun td ->
        match td with
        | {
         ptype_kind = Ptype_abstract;
         ptype_manifest = Some ({ ptyp_desc = Ptyp_variant (rows, closed_flag, labels); _ } as manifest);
         _;
        } ->
            let rows =
              List.filter_map (fun row -> if should_keep row.prf_attributes = `keep then Some row else None) rows
            in

            if rows = [] then None
            else
              Some
                { td with ptype_manifest = Some { manifest with ptyp_desc = Ptyp_variant (rows, closed_flag, labels) } }
        | { ptype_kind = Ptype_variant cstrs; _ } ->
            let cstrs =
              List.filter_map (fun cstr -> if should_keep cstr.pcd_attributes = `keep then Some cstr else None) cstrs
            in

            if cstrs = [] then None else Some { td with ptype_kind = Ptype_variant cstrs }
        | { ptype_kind = Ptype_record labels; _ } ->
            let labels =
              List.filter_map
                (fun label -> if should_keep label.pld_attributes = `keep then Some label else None)
                labels
            in

            if labels = [] then None else Some { td with ptype_kind = Ptype_record labels }
        | _ -> Some td)
      tds

  let apply_config_on_structure_item stri =
    match stri.pstr_desc with
    | Pstr_typext { ptyext_attributes = attrs; _ }
    | Pstr_modtype { pmtd_attributes = attrs; _ }
    | Pstr_open { popen_attributes = attrs; _ }
    | Pstr_include { pincl_attributes = attrs; _ }
    | Pstr_exception { ptyexn_attributes = attrs; _ }
    | Pstr_primitive { pval_attributes = attrs; _ }
    | Pstr_eval (_, attrs)
    | Pstr_module { pmb_attributes = attrs; _ } ->
        if should_keep attrs = `keep then Some stri else None
    | Pstr_value (_, vbs) -> if should_keep_many vbs (fun vb -> vb.pvb_attributes) = `keep then Some stri else None
    | Pstr_type (recflag, tds) ->
        if should_keep_many tds (fun td -> td.ptype_attributes) = `keep then
          let tds = apply_config_on_types tds in
          Some { stri with pstr_desc = Pstr_type (recflag, tds) }
        else None
    | Pstr_recmodule md -> if should_keep_many md (fun md -> md.pmb_attributes) = `keep then Some stri else None
    | Pstr_class cds -> if should_keep_many cds (fun cd -> cd.pci_attributes) = `keep then Some stri else None
    | Pstr_class_type ctds -> if should_keep_many ctds (fun ctd -> ctd.pci_attributes) = `keep then Some stri else None
    | Pstr_extension _ | Pstr_attribute _ -> Some stri

  let apply_config_on_signature_item sigi =
    match sigi.psig_desc with
    | Psig_typext { ptyext_attributes = attrs; _ }
    | Psig_modtype { pmtd_attributes = attrs; _ }
    | Psig_open { popen_attributes = attrs; _ }
    | Psig_include { pincl_attributes = attrs; _ }
    | Psig_exception { ptyexn_attributes = attrs; _ }
    | Psig_value { pval_attributes = attrs; _ }
    | Psig_modtypesubst { pmtd_attributes = attrs; _ }
    | Psig_modsubst { pms_attributes = attrs; _ }
    | Psig_module { pmd_attributes = attrs; _ } ->
        if should_keep attrs = `keep then Some sigi else None
    | Psig_typesubst tds ->
        if should_keep_many tds (fun td -> td.ptype_attributes) = `keep then
          let tds = apply_config_on_types tds in
          Some { sigi with psig_desc = Psig_typesubst tds }
        else None
    | Psig_type (recflag, tds) ->
        if should_keep_many tds (fun td -> td.ptype_attributes) = `keep then
          let tds = apply_config_on_types tds in
          Some { sigi with psig_desc = Psig_type (recflag, tds) }
        else None
    | Psig_recmodule md -> if should_keep_many md (fun md -> md.pmd_attributes) = `keep then Some sigi else None
    | Psig_class cds -> if should_keep_many cds (fun cd -> cd.pci_attributes) = `keep then Some sigi else None
    | Psig_class_type ctds -> if should_keep_many ctds (fun ctd -> ctd.pci_attributes) = `keep then Some sigi else None
    | Psig_extension _ | Psig_attribute _ -> Some sigi

  let traverse =
    object (_ : Ast_traverse.map)
      inherit Ast_traverse.map as super

      method! structure str =
        let str = super#structure str in
        match str with
        | { pstr_desc = Pstr_attribute attr; _ } :: rest when is_platform_tag attr.attr_name.txt ->
            if eval_attr attr = `keep then rest else []
        | str -> List.filter_map apply_config_on_structure_item str

      method! signature sigi =
        let sigi = super#signature sigi in
        match sigi with
        | { psig_desc = Psig_attribute attr; _ } :: rest when is_platform_tag attr.attr_name.txt ->
            if eval_attr attr = `keep then rest else []
        | _ -> List.filter_map apply_config_on_signature_item sigi

      method! expression expr =
        let expr = super#expression expr in
        let loc = expr.pexp_loc in
        match expr.pexp_desc with
        | Pexp_let (rec_flag, bindings, body)
          when List.exists (fun vb -> should_keep vb.pvb_attributes = `drop) bindings ->
            (* Some binding had [@@browser_only] or similar drop-attr. Transform
               those bindings via [transform_let_in_value_binding]. *)
            let new_bindings =
              List.map
                (fun vb ->
                  if should_keep vb.pvb_attributes = `drop then Browser_only.transform_let_in_value_binding vb else vb)
                bindings
            in
            { expr with pexp_desc = Pexp_let (rec_flag, new_bindings, body) }
        | Pexp_let (_, [ { pvb_attributes = attrs; _ } ], _) ->
            if should_keep attrs = `keep then expr
            else [%expr [%ocaml.error "Don't use browser_only on expressions, use switch%platform instead"]]
        | _ ->
            if should_keep expr.pexp_attributes = `keep then expr
            else [%expr [%ocaml.error "Don't use browser_only on expressions, use switch%platform instead"]]

      method! pattern pat =
        match pat.ppat_desc with
        | Ppat_constraint (inner_pat, _) ->
            let loc = pat.ppat_loc in
            if should_keep inner_pat.ppat_attributes = `keep then super#pattern pat else [%pat? _]
        | _ ->
            let pat = super#pattern pat in
            let loc = pat.ppat_loc in
            if should_keep pat.ppat_attributes = `keep then pat else [%pat? _]
    end
end

let () =
  Driver.add_arg "-js" (Unit (fun () -> mode := Js)) ~doc:"preprocess for js build";
  let rules =
    [ Browser_only.expression_rule; Browser_only.structure_item_rule; Platform.rule ] @ Browser_only.use_effects
  in
  (* Pre-scan the structure for [@platform js] declarations BEFORE the
     context-free rules fire. The scan populates [Platform_js_scope.restricted_names],
     which is then consulted by [Body_free_idents.collect] to skip names that
     would not exist on native. *)
  let prescan_instrument = Driver.Instrument.V2.make Platform_js_scope.instrument_pre_pass ~position:Before in
  Driver.V2.register_transformation browser_ppx ~rules ~instrument:prescan_instrument
    ~impl:(fun _ -> Preprocess.traverse#structure)
    ~intf:(fun _ -> Preprocess.traverse#signature)
