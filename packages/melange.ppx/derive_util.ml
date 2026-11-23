open Ppxlib
module Builder = Ast_builder.Default

let has_mel_optional attrs =
  List.exists (fun { attr_name = { txt; _ }; _ } -> txt = "mel.optional" || txt = "bs.optional") attrs

let get_pld_type pld_type ~attrs =
  let is_optional = has_mel_optional attrs in
  match is_optional with
  | true -> (
      match pld_type.ptyp_desc with
      | Ptyp_constr ({ txt = Lident "option"; _ }, [ inner_type ]) -> inner_type
      | _ -> Location.raise_errorf ~loc:pld_type.ptyp_loc "`[@mel.optional]' must appear on an option type (`_ option')"
      )
  | false -> pld_type

let core_type_of_type_declaration (tdcl : type_declaration) =
  match tdcl with
  | { ptype_name = { txt; loc }; ptype_params; _ } ->
      Builder.ptyp_constr ~loc { txt = Lident txt; loc } (List.map fst ptype_params)
