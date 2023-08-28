open Ppxlib
module Builder = Ast_builder.Default

type target = Native | Js

let mode = ref Native

let effect_rule =
  let extractor = Ast_pattern.(__') in
  let handler ~ctxt:_ ({ txt = payload; loc } : Ppxlib.Parsetree.payload loc) =
    match payload with
    | PStr [ { pstr_desc = Pstr_eval (expression, _); _ } ] -> (
        match expression.pexp_desc with
        | Pexp_apply
            ( {
                pexp_desc = Pexp_ident { txt = Ldot (Lident _, "useEffect"); _ };
                pexp_loc_stack;
              },
              _ ) ->
            [%expr React.useEffect0 (fun () -> None)]
        | _ ->
            [%expr [%ocaml.error "effect only accepts a useEffect expression"]])
    | _ -> [%expr [%ocaml.error "effect only accepts a useEffect expression"]]
  in
  Context_free.Rule.extension
    (Extension.V3.declare "effect" Extension.Context.expression extractor
       handler)

let browser_only_value_binding pattern expression =
  let loc = pattern.ppat_loc in
  let rec last_expr_to_raise_impossbile name expr =
    match expr.pexp_desc with
    | Pexp_fun (_arg_label, _arg_expression, pattern, expr) ->
        [%expr
          fun [%p pattern] ->
            ([%e last_expr_to_raise_impossbile name expr] [@warning "-27"])]
    | _ ->
        let message = Builder.estring ~loc name in
        [%expr raise (ReactDOM.Impossible_in_ssr [%e message])]
  in
  match pattern with
  | [%pat? ()] -> Builder.value_binding ~loc ~pat:pattern ~expr:[%expr ()]
  | _ -> (
      match expression.pexp_desc with
      | Pexp_fun (_arg_label, _arg_expression, fun_pattern, expr) ->
          let stringified = Ppxlib.Pprintast.string_of_expression expression in
          let expr = last_expr_to_raise_impossbile stringified expression in
          let vb = Builder.value_binding ~loc ~pat:pattern ~expr in
          let warning27 =
            Builder.attribute ~loc ~name:{ txt = "warning"; loc }
              ~payload:(PStr [ [%stri "-27"] ])
          in
          { vb with pvb_attributes = [ warning27 ] }
      | _ ->
          Builder.value_binding ~loc ~pat:pattern
            ~expr:
              [%expr
                [%ocaml.error
                  "browser only works on expressions or function definitions"]])

let browser_only_on_expressions_rule =
  let extractor = Ast_pattern.(single_expr_payload __) in
  let handler ~ctxt payload =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    match !mode with
    | Js -> payload
    | Native -> (
        match payload.pexp_desc with
        | Pexp_apply (expression, _) ->
            let stringified = Ppxlib.Pprintast.string_of_expression payload in
            let message = Builder.estring ~loc stringified in
            [%expr raise ReactDOM.Impossible_in_ssr [%e message]]
        | Pexp_fun (_arg_label, _arg_expression, fun_pattern, _expression) ->
            let stringified = Ppxlib.Pprintast.string_of_expression payload in
            let message = Builder.estring ~loc stringified in
            [%expr
              fun [%p fun_pattern] ->
                (raise ReactDOM.Impossible_in_ssr [%e message] [@warning "-27"])]
        | Pexp_let (rec_flag, value_bindings, expression) ->
            let pexp_let =
              Builder.pexp_let ~loc rec_flag
                (List.map
                   (fun binding ->
                     browser_only_value_binding binding.pvb_pat binding.pvb_expr)
                   value_bindings)
                expression
            in
            [%expr [%e pexp_let] [@warning "-27"]]
        | _ ->
            [%expr
              [%ocaml.error
                "browser only works on expressions or function definitions"]])
  in
  Context_free.Rule.extension
    (Extension.V3.declare "browser_only" Extension.Context.expression extractor
       handler)

let browser_only_on_structure_item =
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
    let rec last_expr_to_raise_impossbile name expr =
      match expr.pexp_desc with
      | Pexp_fun (_arg_label, _arg_expression, pattern, expr) ->
          [%expr
            fun [%p pattern] -> [%e last_expr_to_raise_impossbile name expr]]
      | _ ->
          let message = Builder.estring ~loc name in
          [%expr raise (ReactDOM.Impossible_in_ssr [%e message])]
    in
    match !mode with
    (* When it's Js, keep item as it is *)
    | Js -> do_nothing rec_flag
    | Native -> (
        match expression.pexp_desc with
        | Pexp_fun (_arg_label, _arg_expression, fun_pattern, expr) ->
            let message = Ppxlib.Pprintast.string_of_expression expression in
            [%stri
              let [%p pattern] =
               fun [%p fun_pattern] ->
                [%e last_expr_to_raise_impossbile message expr]
              [@@warning "-27"]]
        | _expr -> do_nothing rec_flag)
  in
  Context_free.Rule.extension
    (Extension.V3.declare "browser_only" Extension.Context.structure_item
       extractor handler)

let () =
  Driver.add_arg "-js"
    (Unit (fun () -> mode := Js))
    ~doc:"preprocess for js build";
  Driver.V2.register_transformation "browser_ppx"
    ~rules:
      [
        effect_rule;
        browser_only_on_expressions_rule;
        browser_only_on_structure_item;
      ]
