open Ppxlib
module Builder = Ast_builder.Default

type target = Native | Js

let mode = ref Native

module Effect = struct
  let rule =
    let extractor = Ast_pattern.(__') in
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

module Browser_only = struct
  (* 26 unused-var (bound to a let or as) *)
  let remove_unused_var ~loc =
    Builder.attribute ~loc ~name:{ txt = "warning"; loc }
      ~payload:(PStr [ [%stri "-26"] ])

  (* 27 unused-var-strict (not bound to a let or as, for example a function argument)*)
  let remove_unused_var_strict ~loc =
    Builder.attribute ~loc ~name:{ txt = "warning"; loc }
      ~payload:(PStr [ [%stri "-27"] ])

  let remove_unused_varariables ~loc =
    Builder.attribute ~loc ~name:{ txt = "warning"; loc }
      ~payload:(PStr [ [%stri "-26-27"] ])

  let get_function_name pattern =
    match pattern with Ppat_var { txt = name; _ } -> name | _ -> "unkwnown"

  let error_only_works_on ~loc =
    [%expr
      [%ocaml.error
        "browser_only works on function definitions or values. If there's \
         another case where it can be helpful, feel free to open an issue in \
         https://github.com/ml-in-barcelona/server-reason-react."]]

  let _enable_alert_browser_only ~loc =
    {
      attr_name = { txt = "alert"; loc };
      attr_payload =
        PStr
          [
            [%stri
              browser_only
                "This expression is marked to only run on the browser where \
                 JavaScript can run. You can only use it inside a \
                 let%browser_only function."];
          ];
      attr_loc = loc;
    }

  let remove_alert_browser_only ~loc =
    Builder.attribute ~loc ~name:{ txt = "alert"; loc }
      ~payload:(PStr [ [%stri "-browser_only"] ])

  let browser_only_value_binding pattern expression =
    let loc = pattern.ppat_loc in
    let rec last_expr_to_raise_impossible original_function_name expr =
      match expr.pexp_desc with
      | Pexp_constraint (expr, _) ->
          last_expr_to_raise_impossible original_function_name expr
      | Pexp_fun (arg_label, arg_expression, fun_pattern, expr) ->
          let fn =
            Builder.pexp_fun ~loc arg_label arg_expression fun_pattern
              (last_expr_to_raise_impossible original_function_name expr)
          in
          { fn with pexp_attributes = expr.pexp_attributes }
      | _ ->
          let message = Builder.estring ~loc original_function_name in
          [%expr Runtime.fail_impossible_action_in_ssr [%e message]]
    in
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
            let expr = last_expr_to_raise_impossible function_name expression in
            let pat =
              {
                pattern with
                ppat_attributes = [ (* enable_alert_browser_only ~loc *) ];
              }
            in
            let vb = Builder.value_binding ~loc ~pat ~expr in

            {
              vb with
              pvb_attributes =
                [
                  remove_unused_varariables ~loc; remove_alert_browser_only ~loc;
                ];
            }
        | Pexp_fun (_arg_label, _arg_expression, _fun_pattern, _expr) ->
            let function_name = get_function_name pattern.ppat_desc in
            let expr = last_expr_to_raise_impossible function_name expression in
            let pat =
              {
                pattern with
                ppat_attributes = [ (* enable_alert_browser_only ~loc *) ];
              }
            in
            let vb = Builder.value_binding ~loc ~pat ~expr in
            {
              vb with
              pvb_attributes =
                [
                  remove_unused_varariables ~loc; remove_alert_browser_only ~loc;
                ];
            }
        | Pexp_ident { txt = longident; loc } ->
            let stringified = Ppxlib.Longident.name longident in
            let message = Builder.estring ~loc stringified in
            let pat =
              {
                pattern with
                ppat_attributes = [ (* enable_alert_browser_only ~loc *) ];
              }
            in
            let vb =
              Builder.value_binding ~loc ~pat
                ~expr:[%expr Runtime.fail_impossible_action_in_ssr [%e message]]
            in
            { vb with pvb_attributes = [ remove_alert_browser_only ~loc ] }
        | _ ->
            Builder.value_binding ~loc ~pat:pattern
              ~expr:(error_only_works_on ~loc))

  let expression_rule =
    let extractor = Ast_pattern.(single_expr_payload __) in
    let handler ~ctxt payload =
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
              let stringified =
                Ppxlib.Pprintast.string_of_expression expression
              in
              let message = Builder.estring ~loc stringified in
              let pat =
                {
                  pattern with
                  ppat_attributes = [ (* enable_alert_browser_only ~loc *) ];
                }
              in
              let fn =
                Builder.pexp_fun ~loc arg_label arg_expression pat
                  [%expr Runtime.fail_impossible_action_in_ssr [%e message]]
              in
              Builder.pexp_constraint ~loc
                { fn with pexp_attributes = expression.pexp_attributes }
                type_constraint
          | Pexp_fun (arg_label, arg_expression, pattern, expression) ->
              let stringified =
                Ppxlib.Pprintast.string_of_expression expression
              in
              let message = Builder.estring ~loc stringified in
              let pat =
                {
                  pattern with
                  ppat_attributes = [ (* enable_alert_browser_only ~loc *) ];
                }
              in
              let fn =
                Builder.pexp_fun ~loc arg_label arg_expression pat
                  [%expr Runtime.fail_impossible_action_in_ssr [%e message]]
              in
              { fn with pexp_attributes = expression.pexp_attributes }
          | Pexp_let (rec_flag, value_bindings, expression) ->
              let pexp_let =
                Builder.pexp_let ~loc rec_flag
                  (List.map
                     (fun binding ->
                       browser_only_value_binding binding.pvb_pat
                         binding.pvb_expr)
                     value_bindings)
                  expression
              in
              [%expr [%e pexp_let]]
          | _ -> error_only_works_on ~loc)
    in
    Context_free.Rule.extension
      (Extension.V3.declare "browser_only" Extension.Context.expression
         extractor handler)

  let structure_item_rule =
    let extractor =
      let open Ast_pattern in
      let extractor_in_let =
        pstr_value __ (value_binding ~pat:__ ~expr:__ ^:: nil)
      in
      pstr @@ extractor_in_let ^:: nil
    in
    let handler ~ctxt rec_flag pattern expression =
      let loc = Expansion_context.Extension.extension_point_loc ctxt in
      let do_nothing rec_flag =
        match rec_flag with
        | Recursive -> [%stri let rec [%p pattern] = [%e expression]]
        | Nonrecursive -> [%stri let [%p pattern] = [%e expression]]
      in
      let rec last_expr_to_raise_impossible original_name expr =
        match expr.pexp_desc with
        | Pexp_fun (arg_label, arg_expression, fun_pattern, expression) ->
            let pat =
              {
                fun_pattern with
                ppat_attributes = [ (* enable_alert_browser_only ~loc *) ];
              }
            in
            let fn =
              Builder.pexp_fun ~loc arg_label arg_expression pat
                (last_expr_to_raise_impossible original_name expression)
            in
            { fn with pexp_attributes = expr.pexp_attributes }
        | _ ->
            [%expr
              Runtime.fail_impossible_action_in_ssr
                [%e Builder.estring ~loc original_name]]
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
              let original_function_name =
                get_function_name pattern.ppat_desc
              in
              let pat =
                {
                  fun_pattern with
                  ppat_attributes = [ (* enable_alert_browser_only ~loc *) ];
                }
              in
              let fn =
                Builder.pexp_fun ~loc arg_label arg_expression pat
                  (last_expr_to_raise_impossible original_function_name expr)
              in
              let item = { fn with pexp_attributes = expr.pexp_attributes } in
              [%stri
                let[@warning "-27-32"] ([%p pattern] :
                                         ([%t type_constraint]
                                         [@alert
                                           browser_only
                                             "This expression is marked to \
                                              only run on the browser where \
                                              JavaScript can run. You can only \
                                              use it inside a let%browser_only \
                                              function."])) =
                  ([%e item] [@alert "-browser_only"])]
          | Pexp_fun (arg_label, arg_expression, fun_pattern, expr) ->
              let original_function_name =
                get_function_name pattern.ppat_desc
              in
              let pat =
                {
                  fun_pattern with
                  ppat_attributes = [ (* enable_alert_browser_only ~loc *) ];
                }
              in
              let fn =
                Builder.pexp_fun ~loc arg_label arg_expression pat
                  (last_expr_to_raise_impossible original_function_name expr)
              in
              let item = { fn with pexp_attributes = expr.pexp_attributes } in
              [%stri
                let[@warning "-27-32"] ([%p pattern]
                    [@alert
                      browser_only
                        "This expression is marked to only run on the browser \
                         where JavaScript can run. You can only use it inside \
                         a let%browser_only function."]) =
                  ([%e item] [@alert "-browser_only"])]
          | Pexp_ident { txt = longident; loc } ->
              let stringified = Ppxlib.Longident.name longident in
              let message = Builder.estring ~loc stringified in
              [%stri
                let ([%p pattern]
                    [@alert
                      browser_only
                        "This expression is marked to only run on the browser \
                         where JavaScript can run. You can only use it inside \
                         a let%browser_only function."]) =
                  Runtime.fail_impossible_action_in_ssr [%e message]
                [@@alert "-browser_only"]]
          | _expr -> do_nothing rec_flag)
    in
    Context_free.Rule.extension
      (Extension.V3.declare "browser_only" Extension.Context.structure_item
         extractor handler)
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
      ]
