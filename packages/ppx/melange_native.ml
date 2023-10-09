open Ppxlib
module Builder = Ast_builder.Default

let is_melange_attr { attr_name = { txt = attr } } =
  let len = 4 in
  String.length attr > 4 && String.equal (String.sub attr 0 len) "mel."

class raise_exception_mapper =
  object (_self)
    inherit Ast_traverse.map as super

    method! structure_item item =
      match item.pstr_desc with
      | Pstr_primitive { pval_name; pval_attributes; pval_loc; pval_type } ->
          let _TODO_locations = Location.none in
          let has_mel_module_attr =
            List.exists is_melange_attr pval_attributes
          in
          if has_mel_module_attr then
            let rec generate_arg_patterns_and_types = function
              | { ptyp_desc = Ptyp_arrow (_arg_label, arg, rest); _ } ->
                  let arg_pat =
                    Builder.ppat_var ~loc:_TODO_locations
                      { loc = arg.ptyp_loc; txt = "_arg_name_" }
                  in
                  let rest_args, arg_name, rest_types =
                    generate_arg_patterns_and_types rest
                  in
                  ( arg_pat :: rest_args,
                    (* todo: consolidate with let arg_pat above *)
                    { loc = arg.ptyp_loc; txt = "_arg_name_" } :: arg_name,
                    arg :: rest_types )
              | _ -> ([], [], [])
            in
            let _arg_patterns, arg_names, _arg_types =
              generate_arg_patterns_and_types pval_type
            in
            let _typs =
              Builder.ptyp_poly ~loc:_TODO_locations arg_names
                (Builder.ptyp_arrow ~loc:_TODO_locations Nolabel
                   (Builder.ptyp_constr ~loc:_TODO_locations
                      { loc = Location.none; txt = Lident "unit" }
                      [])
                   (Builder.ptyp_constr ~loc:_TODO_locations
                      { loc = Location.none; txt = Lident "unit" }
                      []))
            in
            let args_pat =
              Builder.ppat_constraint ~loc:_TODO_locations
                (Builder.ppat_var ~loc:_TODO_locations
                   { loc = pval_name.loc; txt = pval_name.txt })
                pval_type
            in
            let vb =
              Builder.value_binding ~loc:pval_loc ~pat:args_pat
                ~expr:
                  (Builder.pexp_fun ~loc:_TODO_locations Nolabel None
                     (Builder.ppat_any ~loc:_TODO_locations)
                     (let loc = _TODO_locations in
                      [%expr
                        raise
                          (Failure "called Melange external @mel from native")]))
            in
            Ast_helper.Str.value Nonrecursive [ vb ]
          else super#structure_item item
      | _ -> super#structure_item item
  end

let structure_mapper s = (new raise_exception_mapper)#structure s

let () =
  Driver.register_transformation ~preprocess_impl:structure_mapper
    "melange-native-ppx"
