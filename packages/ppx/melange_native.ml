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

type t = Ppxlib.core_type

(* Insert send_pipe_core_type as a last argument of the function, but not the return type *)
let construct_pval_with_send_pipe send_pipe_core_type pval_type =
  let rec insert_core_type_in_arrow core_type =
    match core_type with
    (* Handle only ptyp and constr.
       Missing `| Ptyp_any | Ptyp_var | Ptyp_arrow | Ptyp_tuple | Ptyp_constr
                | Ptyp_object | Ptyp_class | Ptyp_alias | Ptyp_variant
                | Ptyp_poly | Ptyp_package | Ptyp_extension`
       The aren't used in most bindings.
    *)
    | { ptyp_desc = Ptyp_arrow (label, t1, t2); _ } -> (
        match (t1.ptyp_desc, t2.ptyp_desc) with
        (* `constr -> constr` gets transformed into `constr -> t -> constr` *)
        | Ptyp_constr _, Ptyp_constr _ ->
            Builder.ptyp_arrow ~loc:t2.ptyp_loc label t1
              (Builder.ptyp_arrow ~loc:t2.ptyp_loc Nolabel send_pipe_core_type
                 t2)
        (* `arrow (constr -> constr) -> constr` gets transformed into,
           `arrow (constr -> constr) -> t -> constr`
        *)
        | Ptyp_arrow _, Ptyp_constr _ ->
            Builder.ptyp_arrow ~loc:t2.ptyp_loc label t1
              (Builder.ptyp_arrow ~loc:t2.ptyp_loc Nolabel send_pipe_core_type
                 t2)
        (* `constr -> arrow (constr -> constr)` gets transformed into
           `constr -> constr -> t -> constr` *)
        | Ptyp_constr _, Ptyp_arrow (_inner_label, _p1, _p2) ->
            Builder.ptyp_arrow ~loc:t1.ptyp_loc label t1
              (insert_core_type_in_arrow t2)
        | _ ->
            insert_core_type_in_arrow t2
            (* match t2 with
               | { ptyp_desc = Ptyp_constr ({ txt = _; _ }, _); _ } ->
                   Builder.ptyp_arrow ~loc:t2.ptyp_loc label t1
                     (Builder.ptyp_arrow ~loc:t2.ptyp_loc label send_pipe_core_type t2)
               | _ -> insert_core_type_in_arrow t2 *))
    (* In case of being a single ptyp, turn into ptyp -> t *)
    | { ptyp_desc = Ptyp_constr ({ txt = _; loc }, _); _ } ->
        Builder.ptyp_arrow ~loc Nolabel core_type send_pipe_core_type
    | _ -> core_type
  in
  insert_core_type_in_arrow pval_type

let inject_send_pipe_as_last_argument pipe_type args_labels =
  match pipe_type with
  | None -> args_labels
  | Some pipe_core_type -> pipe_core_type :: args_labels

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
          let pipe_type =
            match get_send_pipe pval_attributes with
            | Some core_type ->
                let pattern =
                  Builder.ppat_var ~loc:core_type.ptyp_loc
                    { loc = core_type.ptyp_loc; txt = "_" }
                in
                Some (Nolabel, pattern, core_type)
            | None -> None
          in
          let args_labels_types = extract_args_labels_types [] pval_type in
          let function_core_type =
            Builder.ppat_var ~loc:pval_name.loc
              { loc = pval_name.loc; txt = pval_name.txt }
          in
          let pval_type_piped =
            match pipe_type with
            | None -> pval_type
            | Some (_, _, pipe_type) ->
                construct_pval_with_send_pipe pipe_type pval_type
          in
          let function_pattern =
            Builder.ppat_constraint ~loc:pval_type.ptyp_loc function_core_type
              (Builder.ptyp_poly ~loc:pval_type.ptyp_loc [] pval_type_piped)
          in
          let arg_labels =
            inject_send_pipe_as_last_argument pipe_type args_labels_types
          in
          let function_expression =
            List.fold_left
              (fun acc (label, arg_pat, arg_type) ->
                Builder.pexp_fun ~loc:arg_type.ptyp_loc label None arg_pat acc)
              (raise_failure ()) arg_labels
          in
          let vb =
            Builder.value_binding ~loc:pval_loc ~pat:function_pattern
              ~expr:function_expression
          in
          Ast_helper.Str.value Nonrecursive [ vb ]
      | _ -> super#structure_item item
  end

let structure_mapper s = (new raise_exception_mapper)#structure s

let () =
  Driver.register_transformation ~preprocess_impl:structure_mapper
    "melange-native-ppx"
