open Ppxlib
module Builder = Ast_builder.Default

type target = Native | Js

let mode = ref Native
let browser_ppx = "browser_ppx"
let platform_tag = "platform"
let is_platform_tag str = String.equal str browser_ppx || String.equal str platform_tag

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
    | _ -> Error [%expr [%ocaml.error "[browser_only] switch%%platform requires 2 cases: `Server` and `Client`"]]

  let switch_platform_requires_a_match ~loc =
    [%expr [%ocaml.error "[browser_ppx] switch%%platform requires a match expression"]]

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
                    (* When it's -js keep the client_expr *)
                    | Js -> client_expr
                    (* When it's isn't -js keep the server_expr *)
                    | Native -> server_expr)
                | Error error_msg_expr -> error_msg_expr)
            | _ -> switch_platform_requires_a_match ~loc)
        | _ -> switch_platform_requires_a_match ~loc)
    | _ -> switch_platform_requires_a_match ~loc

  let rule = Context_free.Rule.extension (Extension.V3.declare "platform" Extension.Context.expression pattern handler)
end

let remove_type_constraint pattern =
  match pattern with { ppat_desc = Ppat_constraint (pattern, _); _ } -> pattern | _ -> pattern

let rec last_expr_to_raise_impossible ~loc original_name expr =
  match expr.pexp_desc with
  | Pexp_constraint (expr, _) -> last_expr_to_raise_impossible ~loc original_name expr
  | Pexp_fun (arg_label, _arg_expression, fun_pattern, expression) ->
      let new_fun_pattern = remove_type_constraint fun_pattern in
      let fn =
        Builder.pexp_fun ~loc arg_label None new_fun_pattern
          (last_expr_to_raise_impossible ~loc original_name expression)
      in
      { fn with pexp_attributes = expr.pexp_attributes }
  | _ -> [%expr Runtime.fail_impossible_action_in_ssr [%e Builder.estring ~loc original_name]]

module Browser_only = struct
  let get_function_name pattern = match pattern with Ppat_var { txt = name; _ } -> name | _ -> "<unkwnown>"

  let error_only_works_on ~loc =
    [%expr
      [%ocaml.error
        "[browser_ppx] browser_only works on function definitions. For other cases, use switch%platform or feel free \
         to open an issue in https://github.com/ml-in-barcelona/server-reason-react."]]

  let remove_alert_browser_only ~loc =
    Builder.attribute ~loc ~name:{ txt = "alert"; loc } ~payload:(PStr [ [%stri "-browser_only"] ])

  let browser_only_fun ~loc arg_label pattern expression =
    let stringified = Ppxlib.Pprintast.string_of_expression expression in
    let message = Builder.estring ~loc stringified in
    let fn = Builder.pexp_fun ~loc arg_label None pattern [%expr Runtime.fail_impossible_action_in_ssr [%e message]] in
    { fn with pexp_attributes = expression.pexp_attributes }

  let browser_only_value_binding pattern expression =
    let loc = pattern.ppat_loc in
    match pattern with
    | [%pat? ()] -> Builder.value_binding ~loc ~pat:pattern ~expr:[%expr ()]
    | _ -> (
        match expression.pexp_desc with
        | Pexp_constraint
            ({ pexp_desc = Pexp_fun (_arg_label, _arg_expression, _fun_pattern, _expr); _ }, _type_constraint) ->
            let function_name = get_function_name pattern.ppat_desc in
            let expr = last_expr_to_raise_impossible ~loc function_name expression in
            let vb = Builder.value_binding ~loc ~pat:pattern ~expr in
            { vb with pvb_attributes = [ remove_alert_browser_only ~loc ] }
        | Pexp_fun (_arg_label, _arg_expression, _fun_pattern, _expr) ->
            let function_name = get_function_name pattern.ppat_desc in
            let expr = last_expr_to_raise_impossible ~loc function_name expression in
            let vb = Builder.value_binding ~loc ~pat:pattern ~expr in
            { vb with pvb_attributes = [ remove_alert_browser_only ~loc ] }
        | _ -> Builder.value_binding ~loc ~pat:pattern ~expr:(error_only_works_on ~loc))

  let extractor_single_payload = Ast_pattern.(single_expr_payload __)

  let expression_handler ~ctxt payload =
    let replace_fun_body_with_raise_impossible ~loc pexp_desc =
      match pexp_desc with
      | Pexp_constraint ({ pexp_desc = Pexp_fun (arg_label, _arg_expression, pattern, expression) }, type_constraint) ->
          let fn = browser_only_fun ~loc arg_label pattern expression in
          Builder.pexp_constraint ~loc { fn with pexp_attributes = expression.pexp_attributes } type_constraint
      | Pexp_fun (arg_label, _arg_expression, pattern, expr) ->
          let function_name = get_function_name pattern.ppat_desc in
          let new_fun_pattern = remove_type_constraint pattern in
          Builder.pexp_fun ~loc arg_label None new_fun_pattern (last_expr_to_raise_impossible ~loc function_name expr)
      | Pexp_let (rec_flag, value_bindings, expression) ->
          let pexp_let =
            Builder.pexp_let ~loc rec_flag
              (List.map (fun binding -> browser_only_value_binding binding.pvb_pat binding.pvb_expr) value_bindings)
              expression
          in
          [%expr [%e pexp_let]]
      | _ -> error_only_works_on ~loc
    in
    match !mode with
    | Js -> payload
    | Native ->
        let loc = Expansion_context.Extension.extension_point_loc ctxt in
        replace_fun_body_with_raise_impossible ~loc payload.pexp_desc

  let expression_rule =
    Context_free.Rule.extension
      (Extension.V3.declare "browser_only" Extension.Context.expression extractor_single_payload expression_handler)

  (* Generates a structure_item with a value binding with a pattern and an expression with all the alerts and warnings *)
  let make_vb_with_browser_only ~loc ?type_constraint pattern expression =
    match type_constraint with
    | Some type_constraint ->
        [%stri
          let[@warning "-27-32"] ([%p pattern] :
                                   ([%t type_constraint]
                                   [@alert
                                     browser_only
                                       "This expression is marked to only run on the browser where JavaScript can run. \
                                        You can only use it inside a let%browser_only function."])) =
            ([%e expression] [@alert "-browser_only"])]
    | None ->
        [%stri
          let[@warning "-27-32"] ([%p pattern]
              [@alert
                browser_only
                  "This expression is marked to only run on the browser where JavaScript can run. You can only use it \
                   inside a let%browser_only function."]) =
            ([%e expression] [@alert "-browser_only"])]

  let extractor_vb =
    let open Ast_pattern in
    let extractor_in_let = pstr_value __ (value_binding ~pat:__ ~expr:__ ^:: nil) in
    pstr @@ extractor_in_let ^:: nil

  let structure_item_handler ~ctxt rec_flag pattern expression =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let do_nothing rec_flag =
      match rec_flag with
      | Recursive -> [%stri let rec [%p pattern] = [%e expression]]
      | Nonrecursive -> [%stri let [%p pattern] = [%e expression]]
    in

    let add_browser_only_alert expression =
      match expression.pexp_desc with
      | Pexp_constraint ({ pexp_desc = Pexp_fun (arg_label, _arg_expression, fun_pattern, expr); _ }, type_constraint)
        ->
          let original_function_name = get_function_name pattern.ppat_desc in
          let new_fun_pattern = remove_type_constraint fun_pattern in
          let fn =
            Builder.pexp_fun ~loc arg_label None new_fun_pattern
              (last_expr_to_raise_impossible ~loc original_function_name expr)
          in
          let item = { fn with pexp_attributes = expr.pexp_attributes } in
          make_vb_with_browser_only ~loc ~type_constraint pattern item
      | Pexp_fun (arg_label, _arg_expression, fun_pattern, expr) ->
          let original_function_name = get_function_name pattern.ppat_desc in
          let new_fun_pattern = remove_type_constraint fun_pattern in
          let fn =
            Builder.pexp_fun ~loc arg_label None new_fun_pattern
              (last_expr_to_raise_impossible ~loc original_function_name expr)
          in
          let item = { fn with pexp_attributes = expr.pexp_attributes } in
          make_vb_with_browser_only ~loc pattern item
      | Pexp_function _cases ->
          (* Because pexp_function doesn't have a pattern, neither a label, we construct an empty pattern and use it to generate the vb *)
          let original_function_name = get_function_name pattern.ppat_desc in
          let fn =
            Builder.pexp_fun ~loc Nolabel None
              [%pat? _]
              (last_expr_to_raise_impossible ~loc original_function_name expression)
          in
          let item = { fn with pexp_attributes = expression.pexp_attributes } in
          make_vb_with_browser_only ~loc pattern item
      | Pexp_ident { txt = _longident; loc } ->
          let item = [%expr Obj.magic ()] in
          make_vb_with_browser_only ~loc pattern item
      | Pexp_newtype (name, expr) ->
          let original_function_name = name.txt in
          let item = last_expr_to_raise_impossible ~loc original_function_name expr in
          make_vb_with_browser_only ~loc pattern item
      | _expr -> do_nothing rec_flag
    in

    match !mode with
    (* When it's -js, keep item as it is *)
    | Js -> do_nothing rec_flag
    | Native -> add_browser_only_alert expression

  let structure_item_rule =
    Context_free.Rule.extension
      (Extension.V3.declare "browser_only" Extension.Context.structure_item extractor_vb structure_item_handler)

  let has_browser_only_attribute expr =
    match expr.pexp_desc with Pexp_extension ({ txt = "browser_only" }, _) -> true | _ -> false

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
    match !mode with (* When it's -js, keep item as it is *)
    | Js -> None | Native -> add_browser_only_extension expr

  let use_effects =
    [
      (* useEffect *)
      Context_free.Rule.special_function "React.useEffect" use_effect;
      Context_free.Rule.special_function "React.useEffect0" use_effect;
      Context_free.Rule.special_function "React.useEffect1" use_effect;
      Context_free.Rule.special_function "React.useEffect2" use_effect;
      Context_free.Rule.special_function "React.useEffect3" use_effect;
      Context_free.Rule.special_function "React.useEffect4" use_effect;
      Context_free.Rule.special_function "React.useEffect5" use_effect;
      Context_free.Rule.special_function "React.useEffect6" use_effect;
      Context_free.Rule.special_function "React.useEffect7" use_effect;
      (* useLayoutEffect *)
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
      match (attr.attr_payload, !mode) with
      | PStr [ { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_ident { txt = Lident "js" } }, []); _ } ], Native
      | PStr [ { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_ident { txt = Lident "native" } }, []); _ } ], Js ->
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
    end
end

let () =
  Driver.add_arg "-js" (Unit (fun () -> mode := Js)) ~doc:"preprocess for js build";
  let rules =
    [ Browser_only.expression_rule; Browser_only.structure_item_rule; Platform.rule ] @ Browser_only.use_effects
  in
  Driver.V2.register_transformation browser_ppx ~rules
    ~preprocess_impl:(fun _ -> Preprocess.traverse#structure)
    ~preprocess_intf:(fun _ -> Preprocess.traverse#signature)
