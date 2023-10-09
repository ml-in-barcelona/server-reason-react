open Ppxlib
module Builder = Ast_builder.Default

class raise_exception_mapper =
  object (_self)
    inherit Ast_traverse.map as super

    method! structure_item item =
      match item.pstr_desc with
      | Pstr_primitive { pval_name; pval_attributes; pval_loc } ->
          let _TODO_locations = Location.none in
          let has_mel_module_attr =
            List.exists
              (fun { attr_name } -> attr_name.txt = "mel.module")
              pval_attributes
          in
          if has_mel_module_attr then
            let vb =
              Builder.value_binding ~loc:pval_loc
                ~pat:
                  (Builder.ppat_var ~loc:pval_name.loc
                     { loc = pval_name.loc; txt = pval_name.txt })
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
