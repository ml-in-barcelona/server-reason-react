(** [[@\@deriving jsProperties]] generates a constructor function for record types.

    This is a native OCaml implementation compatible with melange's jsProperties deriver.

    {2 Basic usage}

    {[
      type person = { name : string; age : int } [@@deriving jsProperties]

      (* Generates: *)
      let person ~name ~age = { name; age }
    ]}

    {2 Optional fields}

    Fields marked with [[@mel.optional]] become optional labeled arguments. When any optional field exists, a trailing
    [unit] argument is added:

    {[
      type config = { host : string; port : int option [@mel.optional] } [@@deriving jsProperties]

      (* Generates: *)
      let config ~host ?port () = { host; port }
    ]}

    {2 Private types}

    Private types do not generate a constructor (the type cannot be constructed outside the module). *)

open Ppxlib
module Builder = Ast_builder.Default

let derive_str tdcls =
  List.concat_map
    (fun tdcl ->
      match tdcl.ptype_kind with
      | Ptype_record label_declarations -> (
          match tdcl.ptype_private with
          | Private -> []
          | Public ->
              let loc = tdcl.ptype_loc in
              let has_optional_field =
                List.exists
                  (fun (x : label_declaration) -> Derive_util.has_mel_optional x.pld_attributes)
                  label_declarations
              in
              let record_fields =
                List.map
                  (fun { pld_name; _ } ->
                    ({ loc; txt = Lident pld_name.txt }, Builder.pexp_ident ~loc { loc; txt = Lident pld_name.txt }))
                  label_declarations
              in
              let record_expr = Builder.pexp_record ~loc record_fields None in
              let body_with_unit =
                if has_optional_field then Builder.pexp_fun ~loc Nolabel None (Builder.punit ~loc) record_expr
                else record_expr
              in
              let func_expr =
                List.fold_right
                  (fun { pld_name; pld_attributes; pld_loc; _ } acc ->
                    let is_optional = Derive_util.has_mel_optional pld_attributes in
                    let label = if is_optional then Optional pld_name.txt else Labelled pld_name.txt in
                    Builder.pexp_fun ~loc:pld_loc label None
                      (Builder.ppat_var ~loc:pld_loc { loc = pld_loc; txt = pld_name.txt })
                      acc)
                  label_declarations body_with_unit
              in
              let pat = Builder.pvar ~loc tdcl.ptype_name.txt in
              let vb = Builder.value_binding ~loc ~pat ~expr:func_expr in
              [ Builder.pstr_value ~loc Nonrecursive [ vb ] ])
      | Ptype_abstract | Ptype_variant _ | Ptype_open ->
          let loc = tdcl.ptype_loc in
          Location.raise_errorf ~loc "[@@deriving jsProperties] can only be used on record types")
    tdcls

let derive_sig tdcls =
  List.concat_map
    (fun tdcl ->
      match tdcl.ptype_kind with
      | Ptype_record label_declarations -> (
          match tdcl.ptype_private with
          | Private -> []
          | Public ->
              let loc = tdcl.ptype_loc in
              let has_optional_field =
                List.exists
                  (fun (x : label_declaration) -> Derive_util.has_mel_optional x.pld_attributes)
                  label_declarations
              in
              let core_type = Derive_util.core_type_of_type_declaration tdcl in
              let make_type =
                List.fold_right
                  (fun { pld_name; pld_type; pld_attributes; pld_loc; _ } acc ->
                    let is_optional = Derive_util.has_mel_optional pld_attributes in
                    let label = if is_optional then Optional pld_name.txt else Labelled pld_name.txt in
                    let pld_type_inner =
                      if is_optional then Derive_util.get_pld_type pld_type ~attrs:pld_attributes else pld_type
                    in
                    Builder.ptyp_arrow ~loc:pld_loc label pld_type_inner acc)
                  label_declarations
                  (if has_optional_field then
                     Builder.ptyp_arrow ~loc Nolabel
                       (Builder.ptyp_constr ~loc { loc; txt = Lident "unit" } [])
                       core_type
                   else core_type)
              in
              [
                Builder.psig_value ~loc
                  (Builder.value_description ~loc ~name:{ loc; txt = tdcl.ptype_name.txt } ~type_:make_type ~prim:[]);
              ])
      | Ptype_abstract | Ptype_variant _ | Ptype_open ->
          let loc = tdcl.ptype_loc in
          Location.raise_errorf ~loc "[@@deriving jsProperties] can only be used on record types")
    tdcls

let str_type_decl =
  Deriving.Generator.V2.make Deriving.Args.empty (fun ~ctxt:_ (_, type_decls) -> derive_str type_decls)

let sig_type_decl =
  Deriving.Generator.V2.make Deriving.Args.empty (fun ~ctxt:_ (_, type_decls) -> derive_sig type_decls)

let deriver = Deriving.add "jsProperties" ~str_type_decl ~sig_type_decl
