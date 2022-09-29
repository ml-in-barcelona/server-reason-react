open Ppxlib
module Builder = Ast_builder.Default

let expander e =
  let loc = e.pexp_loc in
  match e.pexp_desc with
  | Pexp_apply
      ( { pexp_desc = Pexp_ident { txt = Lident "##"; _ }; pexp_loc_stack = _ }
      , [ (Nolabel, objectArg); (Nolabel, methodArg) ] ) -> (
      match methodArg with
      | { pexp_desc = Pexp_ident { txt = Lident li; _ }; _ } ->
          Some (Builder.pexp_send ~loc objectArg { txt = li; loc })
      | _ -> None)
  | _ -> None

let () =
  Driver.register_transformation "double_hash_ppx"
    ~rules:[ Context_free.Rule.special_function "##" expander ]
