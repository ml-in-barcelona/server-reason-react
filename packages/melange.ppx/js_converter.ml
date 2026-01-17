open Ppxlib
module Builder = Ast_builder.Default

let is_mel_as_attr txt = txt = "mel.as"

let get_mel_as_int attrs =
  List.find_map
    (fun { attr_name = { txt; _ }; attr_payload; _ } ->
      if is_mel_as_attr txt then
        match attr_payload with
        | PStr [ { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_constant (Pconst_integer (s, _)); _ }, _); _ } ] ->
            Some (int_of_string s)
        | _ -> None
      else None)
    attrs

let get_mel_as_string attrs =
  List.find_map
    (fun { attr_name = { txt; _ }; attr_payload; _ } ->
      if is_mel_as_attr txt then
        match attr_payload with
        | PStr [ { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_constant (Pconst_string (s, _, _)); _ }, _); _ } ] ->
            Some s
        | _ -> None
      else None)
    attrs

type variant_info = { name : string; js_value : int }
type poly_variant_info = { name : string; js_string : string }

let check_duplicate_values ~loc mappings =
  let values = List.map (fun { js_value; _ } -> js_value) mappings in
  let rec check seen = function
    | [] -> ()
    | v :: rest ->
        if List.mem v seen then
          Location.raise_errorf ~loc
            "[@@deriving jsConverter] has duplicate value %d - each constructor must map to a unique integer" v
        else check (v :: seen) rest
  in
  check [] values

let check_duplicate_strings ~loc mappings =
  let strings = List.map (fun { js_string; _ } -> js_string) mappings in
  let rec check seen = function
    | [] -> ()
    | s :: rest ->
        if List.mem s seen then
          Location.raise_errorf ~loc
            "[@@deriving jsConverter] has duplicate value %S - each constructor must map to a unique string" s
        else check (s :: seen) rest
  in
  check [] strings

let compute_variant_mappings ~loc constrs =
  if constrs = [] then Location.raise_errorf ~loc "[@@deriving jsConverter] cannot be used on empty variant types";
  let explicit_values =
    List.filter_map (fun { pcd_name = _; pcd_attributes; _ } -> get_mel_as_int pcd_attributes) constrs
  in
  let next_available all_used current =
    let rec find n = if List.mem n all_used then find (n + 1) else n in
    find current
  in
  let _, _, mappings =
    List.fold_left
      (fun (current, all_used, acc) { pcd_name; pcd_attributes; pcd_args; pcd_loc; _ } ->
        match pcd_args with
        | Pcstr_tuple [] | Pcstr_record [] ->
            let js_value, next =
              match get_mel_as_int pcd_attributes with
              | Some v -> (v, max current (v + 1))
              | None ->
                  let v = next_available (all_used @ explicit_values) current in
                  (v, v + 1)
            in
            let new_all_used = js_value :: all_used in
            (next, new_all_used, { name = pcd_name.txt; js_value } :: acc)
        | _ ->
            Location.raise_errorf ~loc:pcd_loc
              "[@@deriving jsConverter] does not support variant constructors with payloads")
      (0, [], []) constrs
  in
  let result = List.rev mappings in
  check_duplicate_values ~loc result;
  result

let compute_poly_variant_mappings ~loc row_fields =
  if row_fields = [] then
    Location.raise_errorf ~loc "[@@deriving jsConverter] cannot be used on empty polymorphic variant types";
  let mappings =
    List.map
      (fun row_field ->
        match row_field.prf_desc with
        | Rtag ({ txt = name; _ }, true, []) ->
            let js_string = match get_mel_as_string row_field.prf_attributes with Some s -> s | None -> name in
            { name; js_string }
        | Rtag (_, _, _ :: _) ->
            Location.raise_errorf ~loc:row_field.prf_loc
              "[@@deriving jsConverter] does not support polymorphic variant constructors with payloads"
        | Rtag (_, false, []) ->
            Location.raise_errorf ~loc:row_field.prf_loc
              "[@@deriving jsConverter] does not support polymorphic variant constructors with payloads"
        | Rinherit _ ->
            Location.raise_errorf ~loc:row_field.prf_loc
              "[@@deriving jsConverter] does not support inherited polymorphic variants")
      row_fields
  in
  check_duplicate_strings ~loc mappings;
  mappings

let generate_to_js_variant ~loc type_name mappings =
  let cases =
    List.map
      (fun { name; js_value } ->
        let pattern = Builder.ppat_construct ~loc { loc; txt = Lident name } None in
        let expr = Builder.pexp_constant ~loc (Pconst_integer (string_of_int js_value, None)) in
        Builder.case ~lhs:pattern ~guard:None ~rhs:expr)
      mappings
  in
  let func_name = type_name ^ "ToJs" in
  let param_name = "x" in
  let func_expr =
    Builder.pexp_fun ~loc Nolabel None
      (Builder.ppat_var ~loc { loc; txt = param_name })
      (Builder.pexp_match ~loc (Builder.pexp_ident ~loc { loc; txt = Lident param_name }) cases)
  in
  Builder.value_binding ~loc ~pat:(Builder.pvar ~loc func_name) ~expr:func_expr

let generate_from_js_variant ~loc type_name mappings ~new_type =
  let cases =
    List.map
      (fun { name; js_value } ->
        let pattern = Builder.ppat_constant ~loc (Pconst_integer (string_of_int js_value, None)) in
        let constr = Builder.pexp_construct ~loc { loc; txt = Lident name } None in
        let rhs = if new_type then constr else Builder.pexp_construct ~loc { loc; txt = Lident "Some" } (Some constr) in
        Builder.case ~lhs:pattern ~guard:None ~rhs)
      mappings
  in
  let default_case =
    if new_type then None
    else
      Some
        (Builder.case ~lhs:(Builder.ppat_any ~loc) ~guard:None
           ~rhs:(Builder.pexp_construct ~loc { loc; txt = Lident "None" } None))
  in
  let all_cases = cases @ Option.to_list default_case in
  let func_name = type_name ^ "FromJs" in
  let param_name = "x" in
  let func_expr =
    Builder.pexp_fun ~loc Nolabel None
      (Builder.ppat_var ~loc { loc; txt = param_name })
      (Builder.pexp_match ~loc (Builder.pexp_ident ~loc { loc; txt = Lident param_name }) all_cases)
  in
  Builder.value_binding ~loc ~pat:(Builder.pvar ~loc func_name) ~expr:func_expr

let generate_to_js_poly ~loc type_name mappings =
  let cases =
    List.map
      (fun { name; js_string } ->
        let pattern = Builder.ppat_variant ~loc name None in
        let expr = Builder.pexp_constant ~loc (Pconst_string (js_string, loc, None)) in
        Builder.case ~lhs:pattern ~guard:None ~rhs:expr)
      mappings
  in
  let func_name = type_name ^ "ToJs" in
  let param_name = "x" in
  let func_expr =
    Builder.pexp_fun ~loc Nolabel None
      (Builder.ppat_var ~loc { loc; txt = param_name })
      (Builder.pexp_match ~loc (Builder.pexp_ident ~loc { loc; txt = Lident param_name }) cases)
  in
  Builder.value_binding ~loc ~pat:(Builder.pvar ~loc func_name) ~expr:func_expr

let generate_from_js_poly ~loc type_name mappings ~new_type =
  let cases =
    List.map
      (fun { name; js_string } ->
        let pattern = Builder.ppat_constant ~loc (Pconst_string (js_string, loc, None)) in
        let variant = Builder.pexp_variant ~loc name None in
        let rhs =
          if new_type then variant else Builder.pexp_construct ~loc { loc; txt = Lident "Some" } (Some variant)
        in
        Builder.case ~lhs:pattern ~guard:None ~rhs)
      mappings
  in
  let default_case =
    if new_type then None
    else
      Some
        (Builder.case ~lhs:(Builder.ppat_any ~loc) ~guard:None
           ~rhs:(Builder.pexp_construct ~loc { loc; txt = Lident "None" } None))
  in
  let all_cases = cases @ Option.to_list default_case in
  let func_name = type_name ^ "FromJs" in
  let param_name = "x" in
  let func_expr =
    Builder.pexp_fun ~loc Nolabel None
      (Builder.ppat_var ~loc { loc; txt = param_name })
      (Builder.pexp_match ~loc (Builder.pexp_ident ~loc { loc; txt = Lident param_name }) all_cases)
  in
  Builder.value_binding ~loc ~pat:(Builder.pvar ~loc func_name) ~expr:func_expr

let generate_abstract_type ~loc type_name ~is_poly =
  let abs_type_name = "abs_" ^ type_name in
  let manifest =
    if is_poly then Some (Builder.ptyp_constr ~loc { loc; txt = Lident "string" } [])
    else Some (Builder.ptyp_constr ~loc { loc; txt = Lident "int" } [])
  in
  Builder.type_declaration ~loc ~name:{ loc; txt = abs_type_name } ~params:[] ~cstrs:[] ~kind:Ptype_abstract
    ~private_:Public ~manifest

let str_gen ~loc ~path:_ (rec_flag, type_decls) new_type =
  let _ = rec_flag in
  List.concat_map
    (fun { ptype_name; ptype_kind; ptype_manifest; ptype_loc; _ } ->
      let type_name = ptype_name.txt in
      match (ptype_kind, ptype_manifest) with
      | Ptype_variant constrs, _ ->
          let mappings = compute_variant_mappings ~loc:ptype_loc constrs in
          let to_js = generate_to_js_variant ~loc:ptype_loc type_name mappings in
          let from_js = generate_from_js_variant ~loc:ptype_loc type_name mappings ~new_type in
          let abs_type =
            if new_type then
              [ Builder.pstr_type ~loc Nonrecursive [ generate_abstract_type ~loc type_name ~is_poly:false ] ]
            else []
          in
          abs_type
          @ [ Builder.pstr_value ~loc Nonrecursive [ to_js ]; Builder.pstr_value ~loc Nonrecursive [ from_js ] ]
      | Ptype_abstract, Some { ptyp_desc = Ptyp_variant (row_fields, Closed, None); ptyp_loc; _ } ->
          let mappings = compute_poly_variant_mappings ~loc:ptyp_loc row_fields in
          let to_js = generate_to_js_poly ~loc:ptype_loc type_name mappings in
          let from_js = generate_from_js_poly ~loc:ptype_loc type_name mappings ~new_type in
          let abs_type =
            if new_type then
              [ Builder.pstr_type ~loc Nonrecursive [ generate_abstract_type ~loc type_name ~is_poly:true ] ]
            else []
          in
          abs_type
          @ [ Builder.pstr_value ~loc Nonrecursive [ to_js ]; Builder.pstr_value ~loc Nonrecursive [ from_js ] ]
      | Ptype_abstract, Some { ptyp_desc = Ptyp_variant (_, Open, _); ptyp_loc; _ } ->
          Location.raise_errorf ~loc:ptyp_loc "[@@deriving jsConverter] does not support open polymorphic variants"
      | Ptype_abstract, Some { ptyp_desc = Ptyp_variant (_, _, Some _); ptyp_loc; _ } ->
          Location.raise_errorf ~loc:ptyp_loc
            "[@@deriving jsConverter] does not support polymorphic variants with row variables"
      | _ ->
          Location.raise_errorf ~loc:ptype_loc
            "[@@deriving jsConverter] only supports variant types and polymorphic variant types")
    type_decls

let sig_gen ~loc ~path:_ (_rec_flag, type_decls) new_type =
  List.concat_map
    (fun { ptype_name; ptype_kind; ptype_manifest; ptype_loc; _ } ->
      let type_name = ptype_name.txt in
      let type_lid = { loc; txt = Lident type_name } in
      match (ptype_kind, ptype_manifest) with
      | Ptype_variant _, _ ->
          let to_js_name = type_name ^ "ToJs" in
          let from_js_name = type_name ^ "FromJs" in
          let abs_type_name = "abs_" ^ type_name in
          let abs_type_lid = { loc; txt = Lident abs_type_name } in
          let type_t = Builder.ptyp_constr ~loc type_lid [] in
          let int_t = Builder.ptyp_constr ~loc { loc; txt = Lident "int" } [] in
          let abs_t = Builder.ptyp_constr ~loc abs_type_lid [] in
          let return_t, from_input_t = if new_type then (abs_t, abs_t) else (int_t, int_t) in
          let to_js_type = Builder.ptyp_arrow ~loc Nolabel type_t return_t in
          let from_js_return =
            if new_type then type_t else Builder.ptyp_constr ~loc { loc; txt = Lident "option" } [ type_t ]
          in
          let from_js_type = Builder.ptyp_arrow ~loc Nolabel from_input_t from_js_return in
          let abs_type_decl =
            if new_type then
              [
                Builder.psig_type ~loc Nonrecursive
                  [
                    Builder.type_declaration ~loc ~name:{ loc; txt = abs_type_name } ~params:[] ~cstrs:[]
                      ~kind:Ptype_abstract ~private_:Public ~manifest:None;
                  ];
              ]
            else []
          in
          abs_type_decl
          @ [
              Builder.psig_value ~loc
                (Builder.value_description ~loc ~name:{ loc; txt = to_js_name } ~type_:to_js_type ~prim:[]);
              Builder.psig_value ~loc
                (Builder.value_description ~loc ~name:{ loc; txt = from_js_name } ~type_:from_js_type ~prim:[]);
            ]
      | Ptype_abstract, Some { ptyp_desc = Ptyp_variant (_, Closed, None); _ } ->
          let to_js_name = type_name ^ "ToJs" in
          let from_js_name = type_name ^ "FromJs" in
          let abs_type_name = "abs_" ^ type_name in
          let abs_type_lid = { loc; txt = Lident abs_type_name } in
          let type_t = Builder.ptyp_constr ~loc type_lid [] in
          let string_t = Builder.ptyp_constr ~loc { loc; txt = Lident "string" } [] in
          let abs_t = Builder.ptyp_constr ~loc abs_type_lid [] in
          let return_t, from_input_t = if new_type then (abs_t, abs_t) else (string_t, string_t) in
          let to_js_type = Builder.ptyp_arrow ~loc Nolabel type_t return_t in
          let from_js_return =
            if new_type then type_t else Builder.ptyp_constr ~loc { loc; txt = Lident "option" } [ type_t ]
          in
          let from_js_type = Builder.ptyp_arrow ~loc Nolabel from_input_t from_js_return in
          let abs_type_decl =
            if new_type then
              [
                Builder.psig_type ~loc Nonrecursive
                  [
                    Builder.type_declaration ~loc ~name:{ loc; txt = abs_type_name } ~params:[] ~cstrs:[]
                      ~kind:Ptype_abstract ~private_:Public ~manifest:None;
                  ];
              ]
            else []
          in
          abs_type_decl
          @ [
              Builder.psig_value ~loc
                (Builder.value_description ~loc ~name:{ loc; txt = to_js_name } ~type_:to_js_type ~prim:[]);
              Builder.psig_value ~loc
                (Builder.value_description ~loc ~name:{ loc; txt = from_js_name } ~type_:from_js_type ~prim:[]);
            ]
      | _ ->
          Location.raise_errorf ~loc:ptype_loc
            "[@@deriving jsConverter] only supports variant types and polymorphic variant types")
    type_decls

let str_type_decl =
  let args = Deriving.Args.(empty +> flag "newType") in
  Deriving.Generator.V2.make args (fun ~ctxt (rec_flag, type_decls) new_type ->
      let loc = Expansion_context.Deriver.derived_item_loc ctxt in
      str_gen ~loc ~path:[] (rec_flag, type_decls) new_type)

let sig_type_decl =
  let args = Deriving.Args.(empty +> flag "newType") in
  Deriving.Generator.V2.make args (fun ~ctxt (rec_flag, type_decls) new_type ->
      let loc = Expansion_context.Deriver.derived_item_loc ctxt in
      sig_gen ~loc ~path:[] (rec_flag, type_decls) new_type)

let deriver = Deriving.add "jsConverter" ~str_type_decl ~sig_type_decl
