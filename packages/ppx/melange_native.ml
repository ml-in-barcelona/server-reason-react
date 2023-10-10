open Ppxlib
module Builder = Ast_builder.Default

let is_melange_attr { attr_name = { txt = attr } } =
  let len = 4 in
  String.length attr > 4 && String.equal (String.sub attr 0 len) "mel."

let is_send_pipe pval_attributes =
  List.exists
    (fun { attr_name = { txt = attr } } -> String.equal attr "mel.send.pipe")
    pval_attributes

let get_label = function
  | Ptyp_constr ({ txt = Lident label; _ }, _) -> Some label
  | _ -> None

(* Extract the `t` from [@mel.send.pipe: t] *)
let get_send_pipe pval_attributes =
  if is_send_pipe pval_attributes then
    let first_attribute = List.hd pval_attributes in
    match first_attribute.attr_payload with
    | PTyp core_type -> Some core_type
    | _ -> None
  else None

let has_mel_module_attr pval_attributes =
  List.exists is_melange_attr pval_attributes

let extract_args_labels_types acc pval_type =
  let rec go acc = function
    | { ptyp_desc = Ptyp_arrow (label, t1, t2); _ } ->
        let arg_name = "_" in
        let arg_pat =
          Builder.ppat_var ~loc:t1.ptyp_loc
            { loc = t1.ptyp_loc; txt = arg_name }
        in
        go ((label, arg_pat, t1) :: acc) t2
    | _ -> acc
  in
  go acc pval_type

let raise_failure () =
  let loc = Location.none in
  [%expr raise (Failure "called Melange external \"mel.\" from native")]

class raise_exception_mapper =
  object (_self)
    inherit Ast_traverse.map as super

    method! structure_item item =
      match item.pstr_desc with
      | Pstr_primitive { pval_name; pval_attributes; pval_loc; pval_type }
        when has_mel_module_attr pval_attributes ->
          let arg_piped_type, _send_pipe_core_type =
            match get_send_pipe pval_attributes with
            | Some core_type -> (
                match core_type.ptyp_desc with
                | Ptyp_constr ({ txt = Lident _; _ }, _) ->
                    let arg_name = "_" in
                    let arg_pat =
                      Builder.ppat_var ~loc:core_type.ptyp_loc
                        { loc = core_type.ptyp_loc; txt = arg_name }
                    in
                    ([ (Nolabel, arg_pat, core_type) ], Some core_type)
                | _ -> ([], None))
            | None -> ([], None)
          in
          let args_labels_types = extract_args_labels_types [] pval_type in
          let core_type =
            Builder.ppat_var ~loc:pval_name.loc
              { loc = pval_name.loc; txt = pval_name.txt }
          in
          let pval_type_piped : core_type =
            match _send_pipe_core_type with
            | Some core_type ->
                Builder.ptyp_arrow ~loc:core_type.ptyp_loc Nolabel core_type
                  pval_type
            | None -> pval_type
          in
          let args_pat =
            Builder.ppat_constraint ~loc:pval_type.ptyp_loc core_type
              (Builder.ptyp_poly ~loc:pval_type.ptyp_loc [] pval_type_piped)
          in
          let fun_expr =
            List.fold_left
              (fun acc (label, arg_pat, arg_type) ->
                Builder.pexp_fun ~loc:arg_type.ptyp_loc label None arg_pat acc)
              (raise_failure ())
              (arg_piped_type @ args_labels_types)
          in
          let vb =
            Builder.value_binding ~loc:pval_loc ~pat:args_pat ~expr:fun_expr
          in
          Ast_helper.Str.value Nonrecursive [ vb ]
      | _ -> super#structure_item item
  end

let structure_mapper s = (new raise_exception_mapper)#structure s

let () =
  Driver.register_transformation ~preprocess_impl:structure_mapper
    "melange-native-ppx"
