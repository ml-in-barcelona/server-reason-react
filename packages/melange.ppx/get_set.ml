(** [[@\@deriving getSet]] generates getter and setter functions for record fields.

    This is a native OCaml implementation compatible with melange's getSet deriver.

    {2 Basic usage}

    {[
      type person = { name : string; age : int } [@@deriving getSet]

      (* Generates: *)
      let nameGet x = x.name
      let ageGet x = x.age
    ]}

    {2 Mutable fields}

    Mutable fields also generate setter functions:

    {[
      type person = { name : string; mutable age : int } [@@deriving getSet]

      (* Generates: *)
      let nameGet x = x.name
      let ageGet x = x.age
      let ageSet x v = x.age <- v
    ]}

    {2 Light mode}

    With [{ light }], getters are named after the field (without "Get" suffix):

    {[
      type person = { name : string; mutable age : int } [@@deriving getSet { light }]

      (* Generates: *)
      let name x = x.name
      let age x = x.age
      let ageSet x v = x.age <- v
    ]} *)

open Ppxlib
module Builder = Ast_builder.Default

let derive_str ~light tdcls =
  List.concat_map
    (fun tdcl ->
      match tdcl.ptype_kind with
      | Ptype_record label_declarations ->
          List.concat_map
            (fun { pld_name; pld_mutable; pld_loc; _ } ->
              let getter_name = if light then pld_name.txt else pld_name.txt ^ "Get" in
              let getter_expr =
                Builder.pexp_fun ~loc:pld_loc Nolabel None
                  (Builder.ppat_var ~loc:pld_loc { loc = pld_loc; txt = "x" })
                  (Builder.pexp_field ~loc:pld_loc
                     (Builder.pexp_ident ~loc:pld_loc { loc = pld_loc; txt = Lident "x" })
                     { loc = pld_loc; txt = Lident pld_name.txt })
              in
              let getter_vb =
                Builder.value_binding ~loc:pld_loc ~pat:(Builder.pvar ~loc:pld_loc getter_name) ~expr:getter_expr
              in
              let getter = Builder.pstr_value ~loc:pld_loc Nonrecursive [ getter_vb ] in
              let setter =
                match pld_mutable with
                | Mutable ->
                    let setter_name = pld_name.txt ^ "Set" in
                    let setter_expr =
                      Builder.pexp_fun ~loc:pld_loc Nolabel None
                        (Builder.ppat_var ~loc:pld_loc { loc = pld_loc; txt = "x" })
                        (Builder.pexp_fun ~loc:pld_loc Nolabel None
                           (Builder.ppat_var ~loc:pld_loc { loc = pld_loc; txt = "v" })
                           (Builder.pexp_setfield ~loc:pld_loc
                              (Builder.pexp_ident ~loc:pld_loc { loc = pld_loc; txt = Lident "x" })
                              { loc = pld_loc; txt = Lident pld_name.txt }
                              (Builder.pexp_ident ~loc:pld_loc { loc = pld_loc; txt = Lident "v" })))
                    in
                    let setter_vb =
                      Builder.value_binding ~loc:pld_loc ~pat:(Builder.pvar ~loc:pld_loc setter_name) ~expr:setter_expr
                    in
                    [ Builder.pstr_value ~loc:pld_loc Nonrecursive [ setter_vb ] ]
                | Immutable -> []
              in
              [ getter ] @ setter)
            label_declarations
      | Ptype_abstract | Ptype_variant _ | Ptype_open ->
          let loc = tdcl.ptype_loc in
          Location.raise_errorf ~loc "[@@deriving getSet] can only be used on record types")
    tdcls

let derive_sig ~light tdcls =
  List.concat_map
    (fun tdcl ->
      match tdcl.ptype_kind with
      | Ptype_record label_declarations ->
          let core_type = Derive_util.core_type_of_type_declaration tdcl in
          List.concat_map
            (fun { pld_name; pld_type; pld_mutable; pld_attributes; pld_loc; _ } ->
              let is_optional = Derive_util.has_mel_optional pld_attributes in
              let getter_name = if light then pld_name.txt else pld_name.txt ^ "Get" in
              let getter_type = Builder.ptyp_arrow ~loc:pld_loc Nolabel core_type pld_type in
              let getter =
                Builder.psig_value ~loc:pld_loc
                  (Builder.value_description ~loc:pld_loc ~name:{ loc = pld_loc; txt = getter_name } ~type_:getter_type
                     ~prim:[])
              in
              let setter =
                match pld_mutable with
                | Mutable ->
                    let pld_type_inner =
                      if is_optional then Derive_util.get_pld_type pld_type ~attrs:pld_attributes else pld_type
                    in
                    let setter_name = pld_name.txt ^ "Set" in
                    let setter_type =
                      Builder.ptyp_arrow ~loc:pld_loc Nolabel core_type
                        (Builder.ptyp_arrow ~loc:pld_loc Nolabel pld_type_inner
                           (Builder.ptyp_constr ~loc:pld_loc { loc = pld_loc; txt = Lident "unit" } []))
                    in
                    [
                      Builder.psig_value ~loc:pld_loc
                        (Builder.value_description ~loc:pld_loc ~name:{ loc = pld_loc; txt = setter_name }
                           ~type_:setter_type ~prim:[]);
                    ]
                | Immutable -> []
              in
              [ getter ] @ setter)
            label_declarations
      | Ptype_abstract | Ptype_variant _ | Ptype_open ->
          let loc = tdcl.ptype_loc in
          Location.raise_errorf ~loc "[@@deriving getSet] can only be used on record types")
    tdcls

let str_type_decl =
  let args = Deriving.Args.(empty +> flag "light") in
  Deriving.Generator.V2.make args (fun ~ctxt:_ (_, type_decls) light -> derive_str ~light type_decls)

let sig_type_decl =
  let args = Deriving.Args.(empty +> flag "light") in
  Deriving.Generator.V2.make args (fun ~ctxt:_ (_, type_decls) light -> derive_sig ~light type_decls)

let deriver = Deriving.add "getSet" ~str_type_decl ~sig_type_decl
