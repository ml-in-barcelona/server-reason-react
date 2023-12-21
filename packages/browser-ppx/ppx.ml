open Ppxlib
module Builder = Ast_builder.Default

type target = Native | Js

let mode = ref Native

module Effect = struct
  (* TODO: [%effect] is a little incomplete, only works with useEffect0 (not other useEffectX, neither useLayoutEffects) *)
  let extractor = Ast_pattern.(__')

  let rule =
    let handler ~ctxt:_ ({ txt = payload; loc } : Ppxlib.Parsetree.payload loc)
        =
      match payload with
      | PStr [ { pstr_desc = Pstr_eval (expression, _); _ } ] -> (
          match !mode with
          | Js -> expression
          | Native -> (
              match expression.pexp_desc with
              | Pexp_apply
                  ( {
                      pexp_desc =
                        Pexp_ident { txt = Ldot (Lident _, "useEffect"); _ };
                      _;
                    },
                    _ ) ->
                  [%expr React.useEffect0 (fun () -> None)]
              | _ ->
                  [%expr
                    [%ocaml.error "effect only accepts a useEffect expression"]]
              ))
      | _ -> [%expr [%ocaml.error "effect only accepts a useEffect expression"]]
    in
    Context_free.Rule.extension
      (Extension.V3.declare "effect" Extension.Context.expression extractor
         handler)
end

module Platform = struct
  let pattern = Ast_pattern.(__')

  let collect_expressions ~loc first second =
    match (first.pc_lhs.ppat_desc, second.pc_lhs.ppat_desc) with
    | ( Ppat_construct
          ({ txt = Lident "Server" | Ldot (Lident "Runtime", "Server"); _ }, _),
        Ppat_construct
          ({ txt = Lident "Client" | Ldot (Lident "Runtime", "Client"); _ }, _)
      ) ->
        Ok (first.pc_rhs, second.pc_rhs)
    | ( Ppat_construct
          ({ txt = Lident "Client" | Ldot (Lident "Runtime", "Client"); _ }, _),
        Ppat_construct
          ({ txt = Lident "Server" | Ldot (Lident "Runtime", "Server"); _ }, _)
      ) ->
        Ok (second.pc_rhs, first.pc_rhs)
    | _ ->
        Error
          [%expr [%ocaml.error "platform requires 2 cases: Server | Client"]]

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
            | _ -> [%expr [%ocaml.error ast_error_msg]])
        | _ -> [%expr [%ocaml.error "platform requires a match expression"]])
    | _ -> [%expr [%ocaml.error "platform requires a match expression"]]

  let rule =
    Context_free.Rule.extension
      (Extension.V3.declare "platform" Extension.Context.expression pattern
         handler)
end

module Collected_idents = Set.Make (struct
  type t = longident

  let compare a b = String.compare (Longident.name a) (Longident.name b)
end)

module Collected_patterns = Set.Make (struct
  type t = string

  let compare a b = compare a b
end)

type rec_payload = { ids : Collected_idents.t; patterns : Collected_patterns.t }

let make_undescored_sequence ~loc idents last_expression =
  match idents with
  | [] -> last_expression
  | _ ->
      let ignored_value_bindings =
        List.map
          (fun ident ->
            Builder.value_binding ~loc
              ~pat:[%pat? _]
              ~expr:(Builder.pexp_ident ~loc { txt = ident; loc }))
          idents
      in
      Builder.pexp_let ~loc Nonrecursive ignored_value_bindings last_expression

let get_pattern (collected : rec_payload) pattern =
  let add_pattern pattern =
    {
      collected with
      patterns = Collected_patterns.add pattern collected.patterns;
    }
  in
  let rec go pattern =
    let go_many patterns =
      let collected_patterns =
        List.fold_left
          (fun acc pattern ->
            let { patterns } = go pattern in
            Collected_patterns.union patterns acc)
          Collected_patterns.empty patterns
      in
      { collected with patterns = collected_patterns }
    in

    match pattern.ppat_desc with
    | Ppat_var { txt; loc = _ } -> add_pattern txt
    | Ppat_constraint (pat, _ty) -> go pat
    | Ppat_any -> collected
    | Ppat_alias (_pat, _) -> collected
    | Ppat_interval _ | Ppat_constant _ -> collected
    | Ppat_tuple pl -> go_many pl
    | Ppat_construct (_li, Some (_, pat)) -> go pat
    | Ppat_construct (_li, None) -> collected
    | Ppat_variant (_, Some pat) -> go pat
    | Ppat_variant (_, None) -> collected
    | Ppat_record (pl, _) -> pl |> List.map (fun (_lbl, p) -> p) |> go_many
    | Ppat_array pl -> go_many pl
    | Ppat_type _li -> collected
    | Ppat_lazy pat -> go pat
    | Ppat_unpack _id -> collected
    | Ppat_exception pat -> go pat
    | Ppat_extension _ -> collected
    | Ppat_open (_, _pat) -> collected
    (* Haven't seen this pattern, ignoring *)
    | Ppat_or (_p1, _p2) -> collected
  in
  go pattern

let is_a_pipe_first expression =
  match expression.pexp_desc with
  | Pexp_ident { txt = Lident "|."; _ } -> true
  | Pexp_ident { txt = Lident "|>"; _ } -> true
  | _ -> false

let is_pexp_apply expression =
  match expression.pexp_desc with Pexp_apply _ -> true | _ -> false

let get_first_arg args =
  let label, first_arg = List.hd args in
  match label with
  | Labelled _ -> None
  | Optional _ -> None
  | Nolabel -> Some first_arg

let get_idents_inside expression =
  let rec go expression payload =
    let add_one ident =
      { payload with ids = Collected_idents.add ident payload.ids }
    in
    let go_many expressions =
      let go_and_union acc expr =
        let payload = go expr payload in
        Collected_idents.union payload.ids acc
      in
      let ids = List.fold_left go_and_union payload.ids expressions in
      { payload with ids }
    in
    match expression.pexp_desc with
    | Pexp_ident { txt = ident; _ } -> add_one ident
    | Pexp_let (_rec_flag, value_bindings, expr) ->
        let new_payload = go expr payload in
        let patterns =
          List.fold_left
            (fun acc value_binding ->
              let { patterns } =
                get_pattern new_payload value_binding.pvb_pat
              in
              Collected_patterns.union patterns acc)
            Collected_patterns.empty value_bindings
        in
        { new_payload with patterns }
    | Pexp_function case ->
        let exprs = List.map (fun case -> case.pc_rhs) case in
        go_many exprs
    | Pexp_apply (ignored_apply_expr, args)
      when is_a_pipe_first ignored_apply_expr -> (
        let first_expr = get_first_arg args in
        match first_expr with
        | Some first_expr -> go first_expr payload
        | None -> payload)
    | Pexp_apply (apply_expr, args) when is_pexp_apply apply_expr ->
        let exprs = List.map (fun (_label, expr) -> expr) args in
        go_many (apply_expr :: exprs)
    | Pexp_apply (_ignored_apply_expr, args) ->
        let exprs = List.map (fun (_label, expr) -> expr) args in
        go_many exprs
    | Pexp_match (expr, cases) ->
        let exprs = expr :: List.map (fun case -> case.pc_rhs) cases in
        go_many exprs
    | Pexp_try (expr, cases) ->
        let exprs = expr :: List.map (fun case -> case.pc_rhs) cases in
        go_many exprs
    | Pexp_tuple exprs -> go_many exprs
    | Pexp_construct (_longident, Some expr) -> go expr payload
    | Pexp_construct ({ txt = _longident; _ }, None) -> payload
    | Pexp_variant (_label, Some expr) -> go expr payload
    | Pexp_variant (_label, None) -> payload
    | Pexp_record (fields, Some expr) ->
        let exprs = List.map snd fields in
        go_many (expr :: exprs)
    | Pexp_record (fields, None) ->
        let exprs = List.map snd fields in
        go_many exprs
    | Pexp_setfield (expr1, _longident, expr2) -> go_many [ expr1; expr2 ]
    | Pexp_array exprs -> go_many exprs
    | Pexp_ifthenelse (expr1, expr2, None) -> go_many [ expr1; expr2 ]
    | Pexp_ifthenelse (expr1, expr2, Some expr3) ->
        go_many [ expr1; expr2; expr3 ]
    | Pexp_sequence (expr, seq_expr) -> go_many [ expr; seq_expr ]
    | Pexp_while (expr1, expr2) -> go_many [ expr1; expr2 ]
    | Pexp_for (_pattern, expr1, expr2, _direction, expr3) ->
        go_many [ expr1; expr2; expr3 ]
    | Pexp_constraint (expr, _core_type) -> go expr payload
    | Pexp_coerce (expr, _core_type_opt, _core_type) -> go expr payload
    | Pexp_send (expr, _label) -> go expr payload
    | Pexp_setinstvar (_label, expr) -> go expr payload
    | Pexp_override fields ->
        let exprs = List.map (fun (_label, field) -> field) fields in
        go_many exprs
    | Pexp_letmodule (_label, _module_expr, expr) -> go expr payload
    | Pexp_letexception (_ext_constructor, expr) -> go expr payload
    | Pexp_assert expr -> go expr payload
    | Pexp_lazy expr -> go expr payload
    | Pexp_poly (expr, _core_type) -> go expr payload
    | Pexp_newtype (_label, expr) -> go expr payload
    | Pexp_open (_open_declaration, expr) -> go expr payload
    (* In case of lamdas, we don't want to collect idents, since the scope of them are inside the lamda, not in the scope of the function *)
    | Pexp_fun _ -> payload
    (* We don't collect fields accessors, since we already collect the Longident from the record *)
    | Pexp_field (expr, _ignored_longident) -> go expr payload
    | Pexp_unreachable | Pexp_constant _ | Pexp_new _ | Pexp_object _
    | Pexp_pack _ | Pexp_letop _ | Pexp_extension _ ->
        payload
  in
  go expression
    { ids = Collected_idents.empty; patterns = Collected_patterns.empty }

let collect_used_vars expression =
  let { ids; patterns } = get_idents_inside expression in
  let idents = Collected_idents.elements ids in
  let patterns = Collected_patterns.elements patterns in
  (* print_string "(* Patterns: ";
     List.iter
       (fun ident ->
         print_string ident;
         print_string "; ")
       patterns;
     print_string ". Idents: ";
     List.iter
       (fun ident ->
         print_string @@ Longident.name ident;
         print_string "; ")
       idents;
     print_endline " *)"; *)
  idents
  |> List.filter (fun ident -> not @@ List.mem (Longident.name ident) patterns)

let remove_type_constraint pattern =
  match pattern with
  | { ppat_desc = Ppat_constraint (pattern, _); _ } -> pattern
  | _ -> pattern

let rec last_expr_to_raise_impossible ~loc original_name expr =
  let vars = collect_used_vars expr in
  match expr.pexp_desc with
  | Pexp_constraint (expr, _) ->
      last_expr_to_raise_impossible ~loc original_name expr
  | Pexp_fun (arg_label, _arg_expression, fun_pattern, expression) ->
      let new_fun_pattern = remove_type_constraint fun_pattern in
      let fn =
        Builder.pexp_fun ~loc arg_label None new_fun_pattern
          (last_expr_to_raise_impossible ~loc original_name expression)
      in
      { fn with pexp_attributes = expr.pexp_attributes }
  | _ ->
      make_undescored_sequence ~loc vars
        [%expr
          Runtime.fail_impossible_action_in_ssr
            [%e Builder.estring ~loc original_name]]

module Browser_only = struct
  let get_function_name pattern =
    match pattern with Ppat_var { txt = name; _ } -> name | _ -> "<unkwnown>"

  let error_only_works_on ~loc =
    [%expr
      [%ocaml.error
        "browser_only works on function definitions or values. If there's \
         another case where it can be helpful, feel free to open an issue in \
         https://github.com/ml-in-barcelona/server-reason-react."]]

  let remove_alert_browser_only ~loc =
    Builder.attribute ~loc ~name:{ txt = "alert"; loc }
      ~payload:(PStr [ [%stri "-browser_only"] ])

  let browser_only_fun ~loc arg_label arg_expression pattern expression =
    let stringified = Ppxlib.Pprintast.string_of_expression expression in
    let message = Builder.estring ~loc stringified in
    let fn =
      Builder.pexp_fun ~loc arg_label arg_expression pattern
        [%expr Runtime.fail_impossible_action_in_ssr [%e message]]
    in
    { fn with pexp_attributes = expression.pexp_attributes }

  let browser_only_value_binding pattern expression =
    let loc = pattern.ppat_loc in
    match pattern with
    | [%pat? ()] -> Builder.value_binding ~loc ~pat:pattern ~expr:[%expr ()]
    | _ -> (
        match expression.pexp_desc with
        | Pexp_constraint
            ( {
                pexp_desc =
                  Pexp_fun (_arg_label, _arg_expression, _fun_pattern, _expr);
                _;
              },
              _type_constraint ) ->
            let function_name = get_function_name pattern.ppat_desc in
            let expr =
              last_expr_to_raise_impossible ~loc function_name expression
            in
            let vb = Builder.value_binding ~loc ~pat:pattern ~expr in
            { vb with pvb_attributes = [ remove_alert_browser_only ~loc ] }
        | Pexp_fun (_arg_label, _arg_expression, _fun_pattern, _expr) ->
            let function_name = get_function_name pattern.ppat_desc in
            let expr =
              last_expr_to_raise_impossible ~loc function_name expression
            in
            let vb = Builder.value_binding ~loc ~pat:pattern ~expr in
            { vb with pvb_attributes = [ remove_alert_browser_only ~loc ] }
        | Pexp_ident { txt = longident; loc } ->
            let stringified = Ppxlib.Longident.name longident in
            let message = Builder.estring ~loc stringified in
            let vb =
              Builder.value_binding ~loc ~pat:pattern
                ~expr:[%expr Runtime.fail_impossible_action_in_ssr [%e message]]
            in
            { vb with pvb_attributes = [ remove_alert_browser_only ~loc ] }
        | _ ->
            Builder.value_binding ~loc ~pat:pattern
              ~expr:(error_only_works_on ~loc))

  let extractor = Ast_pattern.(single_expr_payload __)

  let expression_handler ~ctxt payload =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    match !mode with
    | Js -> payload
    | Native -> (
        match payload.pexp_desc with
        | Pexp_apply (expression, _) ->
            let stringified =
              Ppxlib.Pprintast.string_of_expression expression
            in
            let message = Builder.estring ~loc stringified in
            [%expr Runtime.fail_impossible_action_in_ssr [%e message]]
        | Pexp_constraint
            ( {
                pexp_desc =
                  Pexp_fun (arg_label, arg_expression, pattern, expression);
              },
              type_constraint ) ->
            let fn =
              browser_only_fun ~loc arg_label arg_expression pattern expression
            in
            Builder.pexp_constraint ~loc
              { fn with pexp_attributes = expression.pexp_attributes }
              type_constraint
        | Pexp_fun (arg_label, arg_expression, pattern, expr) ->
            let function_name = get_function_name pattern.ppat_desc in
            let new_fun_pattern = remove_type_constraint pattern in
            Builder.pexp_fun ~loc arg_label arg_expression new_fun_pattern
              (last_expr_to_raise_impossible ~loc function_name expr)
        | Pexp_let (rec_flag, value_bindings, expression) ->
            let pexp_let =
              Builder.pexp_let ~loc rec_flag
                (List.map
                   (fun binding ->
                     browser_only_value_binding binding.pvb_pat binding.pvb_expr)
                   value_bindings)
                expression
            in
            [%expr [%e pexp_let]]
        | _ -> error_only_works_on ~loc)

  let expression_rule =
    Context_free.Rule.extension
      (Extension.V3.declare "browser_only" Extension.Context.expression
         extractor expression_handler)

  (* Generates a structure_item with a value binding with a pattern and an expression with all the alerts and warnings *)
  let make_vb_with_browser_only ~loc ?type_constraint pattern expression =
    match type_constraint with
    | Some type_constraint ->
        [%stri
          let[@warning "-27-32"] ([%p pattern] :
                                   ([%t type_constraint]
                                   [@alert
                                     browser_only
                                       "This expression is marked to only run \
                                        on the browser where JavaScript can \
                                        run. You can only use it inside a \
                                        let%browser_only function."])) =
            ([%e expression] [@alert "-browser_only"])]
    | None ->
        [%stri
          let[@warning "-27-32"] ([%p pattern]
              [@alert
                browser_only
                  "This expression is marked to only run on the browser where \
                   JavaScript can run. You can only use it inside a \
                   let%browser_only function."]) =
            ([%e expression] [@alert "-browser_only"])]

  let extractor =
    let open Ast_pattern in
    let extractor_in_let =
      pstr_value __ (value_binding ~pat:__ ~expr:__ ^:: nil)
    in
    pstr @@ extractor_in_let ^:: nil

  let structure_item_handler ~ctxt rec_flag pattern expression =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let do_nothing rec_flag =
      match rec_flag with
      | Recursive -> [%stri let rec [%p pattern] = [%e expression]]
      | Nonrecursive -> [%stri let [%p pattern] = [%e expression]]
    in

    match !mode with
    (* When it's -js, keep item as it is *)
    | Js -> do_nothing rec_flag
    | Native -> (
        match expression.pexp_desc with
        | Pexp_constraint
            ( {
                pexp_desc =
                  Pexp_fun (arg_label, arg_expression, fun_pattern, expr);
                _;
              },
              type_constraint ) ->
            let original_function_name = get_function_name pattern.ppat_desc in
            let new_fun_pattern = remove_type_constraint fun_pattern in
            let fn =
              Builder.pexp_fun ~loc arg_label arg_expression new_fun_pattern
                (last_expr_to_raise_impossible ~loc original_function_name expr)
            in
            let item = { fn with pexp_attributes = expr.pexp_attributes } in
            make_vb_with_browser_only ~loc ~type_constraint pattern item
        | Pexp_fun (arg_label, arg_expression, fun_pattern, expr) ->
            let original_function_name = get_function_name pattern.ppat_desc in
            let new_fun_pattern = remove_type_constraint fun_pattern in
            let fn =
              Builder.pexp_fun ~loc arg_label arg_expression new_fun_pattern
                (last_expr_to_raise_impossible ~loc original_function_name expr)
            in
            let item = { fn with pexp_attributes = expr.pexp_attributes } in
            make_vb_with_browser_only ~loc pattern item
        | Pexp_ident { txt = longident; loc } ->
            let stringified = Ppxlib.Longident.name longident in
            let message = Builder.estring ~loc stringified in
            let item =
              [%expr Runtime.fail_impossible_action_in_ssr [%e message]]
            in
            make_vb_with_browser_only ~loc pattern item
        | Pexp_newtype (name, expr) ->
            let original_function_name = name.txt in
            let item =
              last_expr_to_raise_impossible ~loc original_function_name expr
            in
            make_vb_with_browser_only ~loc pattern item
        | _expr -> do_nothing rec_flag)

  let structure_item_rule =
    Context_free.Rule.extension
      (Extension.V3.declare "browser_only" Extension.Context.structure_item
         extractor structure_item_handler)
end

let () =
  Driver.add_arg "-js"
    (Unit (fun () -> mode := Js))
    ~doc:"preprocess for js build";
  Driver.V2.register_transformation "browser_ppx"
    ~rules:
      [
        Effect.rule;
        Browser_only.expression_rule;
        Browser_only.structure_item_rule;
        Platform.rule;
      ]
