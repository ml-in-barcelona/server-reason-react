open Ppxlib
module Builder = Ast_builder.Default

let effect_rule =
  let extractor = Ast_pattern.(__') in
  let handler ~ctxt:_ ({ txt = payload; loc } : Ppxlib.Parsetree.payload loc) =
    match payload with
    | PStr [ { pstr_desc = Pstr_eval (expression, _); _ } ] -> (
        match expression.pexp_desc with
        | Pexp_apply
            ( {
                (* Ldot (Lident "Prop", str) *)
                pexp_desc = Pexp_ident { txt = Ldot (Lident _, "useEffect"); _ };
                pexp_loc_stack;
              },
              _ ) ->
            [%expr React.useEffect (fun () -> None) [||]]
        | _ ->
            [%expr [%ocaml.error "effect only accepts a useEffect expression"]])
    | _ -> [%expr [%ocaml.error "effect only accepts a useEffect expression"]]
  in
  Context_free.Rule.extension
    (Extension.V3.declare "effect" Extension.Context.expression extractor
       handler)

let () = Driver.V2.register_transformation "browser_ppx" ~rules:[ effect_rule ]
