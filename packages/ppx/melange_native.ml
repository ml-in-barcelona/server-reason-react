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
          let has_mel_module_attr =
            List.exists is_melange_attr pval_attributes
          in
          if has_mel_module_attr then
            let args_pat =
              Builder.ppat_constraint ~loc:pval_type.ptyp_loc
                (Builder.ppat_var ~loc:pval_name.loc
                   { loc = pval_name.loc; txt = pval_name.txt })
                pval_type
            in
            let vb =
              Builder.value_binding ~loc:pval_loc ~pat:args_pat
                ~expr:
                  (Builder.pexp_fun ~loc:Location.none Nolabel None
                     (Builder.ppat_any ~loc:Location.none)
                     (let loc = Location.none in
                      [%expr
                        raise
                          (Failure
                             "called Melange external \"mel.\" from native")]))
            in
            Ast_helper.Str.value Nonrecursive [ vb ]
          else super#structure_item item
      | _ -> super#structure_item item
  end

let structure_mapper s = (new raise_exception_mapper)#structure s

let () =
  Driver.register_transformation ~preprocess_impl:structure_mapper
    "melange-native-ppx"
