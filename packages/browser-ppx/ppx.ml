open Ppxlib
module Builder = Ast_builder.Default

type target = Native | Js

let mode = ref Native

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

let remove_type_constraint pattern =
  match pattern with
  | { ppat_desc = Ppat_constraint (pattern, _); _ } -> pattern
  | _ -> pattern

let rec last_expr_to_raise_impossible ~loc original_name expr =
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
        | Pexp_ident { txt = _longident; loc } ->
            let item = [%expr Obj.magic ()] in
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
        Browser_only.expression_rule;
        Browser_only.structure_item_rule;
        Platform.rule;
      ]
