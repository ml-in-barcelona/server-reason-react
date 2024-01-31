open Ppxlib
module Builder = Ast_builder.Default

let is_melange_attr { attr_name = { txt = attr } } =
  let len = 4 in
  String.length attr > 4 && String.equal (String.sub attr 0 len) "mel."

let is_send_pipe pval_attributes =
  List.exists
    (fun { attr_name = { txt = attr } } -> String.equal attr "mel.send.pipe")
    pval_attributes

let get_function_name pattern =
  let rec go pattern =
    match pattern with
    | Ppat_var { txt = name; _ } -> Some name
    | Ppat_constraint (pattern, _) -> go pattern.ppat_desc
    | _ -> None
  in
  go pattern

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

let has_ptyp_attribute ptyp_attributes attribute =
  List.exists
    (fun { attr_name = { txt = attr } } -> attr = attribute)
    ptyp_attributes

let is_mel_as core_type =
  match core_type with
  | { ptyp_desc = Ptyp_any; ptyp_attributes; _ } ->
      has_ptyp_attribute ptyp_attributes "mel.as"
  | _ -> false

let extract_args_labels_types acc pval_type =
  let rec go acc = function
    (* In case of being mel.as, ignore those *)
    | { ptyp_desc = Ptyp_arrow (_label, t1, _t2); _ } when is_mel_as t1 -> acc
    | { ptyp_desc = Ptyp_arrow (_label, _t1, t2); _ } when is_mel_as t2 -> acc
    | { ptyp_desc = Ptyp_arrow (_label, t1, t2); _ }
      when is_mel_as t1 && is_mel_as t2 ->
        acc
    | { ptyp_desc = Ptyp_arrow (label, t1, t2); _ } ->
        let pattern =
          Builder.ppat_var ~loc:t1.ptyp_loc { loc = t1.ptyp_loc; txt = "_" }
        in
        go ((label, pattern, t1) :: acc) t2
    | _ -> acc
  in
  go acc pval_type

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
        (* `constr -> arrow (constr -> constr)` gets transformed into
           `constr -> constr -> t -> constr` *)
        | Ptyp_constr _, Ptyp_arrow (_inner_label, _p1, _p2) ->
            Builder.ptyp_arrow ~loc:t1.ptyp_loc label t1
              (insert_core_type_in_arrow t2)
        (* `constr -> constr` gets transformed into `constr -> t -> constr` *)
        (* `arrow (constr -> constr) -> constr` gets transformed into,
            `arrow (constr -> constr) -> t -> constr` *)
        | _, _ ->
            Builder.ptyp_arrow ~loc:t2.ptyp_loc label t1
              (Builder.ptyp_arrow ~loc:t2.ptyp_loc Nolabel send_pipe_core_type
                 t2))
    (* In case of being a single ptyp_* turn into ptyp_* -> t *)
    | { ptyp_desc = Ptyp_constr ({ txt = _; loc }, _); _ }
    | { ptyp_desc = Ptyp_var _; ptyp_loc = loc; _ } ->
        Builder.ptyp_arrow ~loc Nolabel core_type send_pipe_core_type
    (* Here we ignore the Ptyp_any *)
    | _ -> core_type
  in
  insert_core_type_in_arrow pval_type

let inject_send_pipe_as_last_argument pipe_type args_labels =
  match pipe_type with
  | None -> args_labels
  | Some pipe_core_type -> pipe_core_type :: args_labels

let is_mel_raw expr =
  match expr with
  | Pexp_extension ({ txt = "mel.raw"; _ }, _) -> true
  | _ -> false

let expression_has_mel_raw expr =
  let rec go expr =
    match expr with
    | Pexp_extension ({ txt = "mel.raw"; _ }, _) as pexp_desc ->
        is_mel_raw pexp_desc
    | Pexp_constraint (expr, _) -> is_mel_raw expr.pexp_desc
    | Pexp_fun (_, _, _, expr) -> go expr.pexp_desc
    | _ -> false
  in
  go expr

let raise_failure ~loc name =
  [%expr
    let () =
      Printf.printf
        {|
There is a Melange's external (for example: [@mel.get]) call from native code.

Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.

|}
    in
    raise
      (Runtime.fail_impossible_action_in_ssr
         [%e Builder.pexp_constant ~loc (Pconst_string (name, loc, None))])]

let make_implementation ~loc arity =
  let rec make_fun ~loc arity =
    match arity with
    | 0 -> [%expr Obj.magic ()]
    | _ ->
        Builder.pexp_fun ~loc Nolabel None
          (Builder.ppat_var ~loc { loc; txt = "_" })
          (make_fun ~loc (arity - 1))
  in
  make_fun ~loc arity

let browser_only_alert_mel_raw_message =
  "Since it's a [%mel.raw ...]. This expression is marked to only run on the \
   browser where JavaScript can run. You can only use it inside a \
   let%browser_only function."

let browser_only_alert ~loc str =
  {
    attr_name = { txt = "alert"; loc };
    attr_payload =
      PStr
        [
          [%stri
            browser_only
              [%e Builder.pexp_constant ~loc (Pconst_string (str, loc, None))]];
        ];
    attr_loc = loc;
  }

let get_function_arity pattern =
  let rec go arity = function
    | Pexp_fun (_, _, _, expr) -> go (arity + 1) expr.pexp_desc
    | _ -> arity
  in
  go 0 pattern

let transform_external_arrow ~loc pval_name pval_attributes pval_type =
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
  let pat =
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
      (raise_failure ~loc:pval_type.ptyp_loc pval_name.txt)
      arg_labels
  in
  let vb = Builder.value_binding ~loc ~pat ~expr:function_expression in
  Ast_helper.Str.value Nonrecursive [ vb ]

let transform_external pval_name pval_attributes pval_loc pval_type =
  let loc = pval_loc in
  match pval_type.ptyp_desc with
  | Ptyp_arrow _ ->
      transform_external_arrow ~loc pval_name pval_attributes pval_type
  | Ptyp_var _ | Ptyp_any | Ptyp_constr _ ->
      (* When mel.send.pipe is used, it's treated as a funcion *)
      if Option.is_some (get_send_pipe pval_attributes) then
        transform_external_arrow ~loc pval_name pval_attributes pval_type
      else
        let function_core_type =
          Builder.ppat_var ~loc { loc; txt = pval_name.txt }
        in
        let pattern =
          Builder.ppat_constraint ~loc function_core_type
            (Builder.ptyp_poly ~loc [] pval_type)
        in
        let pattern =
          {
            pattern with
            ppat_attributes =
              [
                browser_only_alert ~loc
                  "This expression is marked to only run on the browser where \
                   JavaScript can run. You can only use it inside a \
                   let%browser_only function.";
              ];
          }
        in
        [%stri let [%p pattern] = Obj.magic ()]
  | Ptyp_tuple _ ->
      [%stri
        [%ocaml.error
          "server-reason-react.melange_ppx: Tuples are not supported in native \
           externals the same way as melange.ppx support them."]]
  | Ptyp_object _ ->
      [%stri
        [%ocaml.error
          "server-reason-react.melange_ppx: Objects are not supported in \
           native externals the same way as melange.ppx support them."]]
  | Ptyp_class _ ->
      [%stri
        [%ocaml.error
          "server-reason-react.melange_ppx: Classes are not supported in \
           native externals the same way as melange.ppx support them."]]
  | Ptyp_variant _ ->
      [%stri
        [%ocaml.error
          "server-reason-react.melange_ppx: Variants are not supported in \
           native externals the same way as melange.ppx support them."]]
  | Ptyp_extension _ ->
      [%stri
        [%ocaml.error
          "server-reason-react.melange_ppx: Extensions are not supported in \
           native externals the same way as melange.ppx support them."]]
  | Ptyp_alias _ ->
      [%stri
        [%ocaml.error
          "server-reason-react.melange_ppx: Variants are not supported in \
           native externals the same way as melange.ppx support them."]]
  | Ptyp_poly _ ->
      [%stri
        [%ocaml.error
          "server-reason-react.melange_ppx: Polyvariants are not supported in \
           native externals the same way as melange.ppx support them."]]
  | Ptyp_package _ ->
      [%stri
        [%ocaml.error
          "server-reason-react.melange_ppx: Packages are not supported in \
           native externals the same way as melange.ppx support them."]]

let tranform_record_to_object ~loc (record : (longident_loc * expression) list)
    =
  let fields =
    List.map
      (fun ((longident : longident_loc), expression) ->
        let label =
          match longident.txt with
          | Lident label -> label
          | Ldot _ | Lapply _ ->
              Location.raise_errorf ~loc
                "`%%mel.obj' literals only support labels"
        in
        Builder.pcf_method ~loc
          ( Builder.Located.mk label ~loc,
            Public,
            Cfk_concrete (Fresh, expression) ))
      record
  in
  Builder.pexp_object ~loc
    (Builder.class_structure ~self:(Builder.ppat_any ~loc) ~fields)

class raise_exception_mapper =
  object (_self)
    inherit Ast_traverse.map as super

    method! expression expr =
      match expr.pexp_desc with
      | Pexp_extension
          ( { txt = "mel.obj"; _ },
            PStr
              [
                {
                  pstr_desc =
                    Pstr_eval
                      ({ pexp_desc = Pexp_record (record, None); pexp_loc }, _);
                  _;
                };
              ] ) ->
          tranform_record_to_object ~loc:pexp_loc record
      | Pexp_extension ({ txt = "mel.obj"; loc }, _) ->
          [%expr [%ocaml.error "%%mel.obj requires a record literal"]]
      | _ -> super#expression expr

    method! structure_item item =
      match item.pstr_desc with
      (* [%%mel.raw ...] *)
      | Pstr_extension (({ txt = "mel.raw"; loc }, _), _) -> [%stri ()]
      (* let a _ = [%mel.raw ...] *)
      | Pstr_value
          ( Nonrecursive,
            [
              {
                pvb_expr =
                  {
                    pexp_desc =
                      Pexp_fun
                        (_arg_label, _arg_expression, _fun_pattern, expression);
                  } as pvb_expr;
                pvb_pat =
                  { ppat_desc = Ppat_var { txt = _function_name; _ } } as
                  pvb_pattern;
                pvb_attributes = _;
                pvb_loc = _;
              };
            ] )
        when expression_has_mel_raw expression.pexp_desc ->
          let loc = item.pstr_loc in
          let function_arity = get_function_arity pvb_expr.pexp_desc in
          let implementation = make_implementation ~loc function_arity in
          let fn_pattern =
            {
              pvb_pattern with
              ppat_attributes =
                [ browser_only_alert ~loc browser_only_alert_mel_raw_message ];
            }
          in
          [%stri let [%p fn_pattern] = [%e implementation]]
      (* let a = [%mel.raw ...] *)
      | Pstr_value
          ( Nonrecursive,
            [
              {
                pvb_expr = expression;
                pvb_pat =
                  { ppat_desc = Ppat_var { txt = _function_name; _ } } as
                  pattern;
                pvb_attributes = _;
                pvb_loc = _;
              };
            ] )
        when expression_has_mel_raw expression.pexp_desc ->
          let loc = item.pstr_loc in
          let fn_pattern =
            {
              pattern with
              ppat_attributes =
                [ browser_only_alert ~loc browser_only_alert_mel_raw_message ];
            }
          in
          let function_arity = get_function_arity expression.pexp_desc in
          let implementation = make_implementation ~loc function_arity in
          [%stri let [%p fn_pattern] = [%e implementation]]
      (* let a: t = [%mel.raw ...] *)
      | Pstr_value
          ( Nonrecursive,
            [
              {
                pvb_expr = expression;
                pvb_pat =
                  {
                    ppat_desc =
                      Ppat_constraint (constrain_pattern, _constrain_type);
                  };
                pvb_attributes = _;
                pvb_loc = _;
              };
            ] )
        when expression_has_mel_raw expression.pexp_desc ->
          let loc = item.pstr_loc in
          let fn_pattern =
            {
              constrain_pattern with
              ppat_attributes =
                [ browser_only_alert ~loc browser_only_alert_mel_raw_message ];
            }
          in
          let function_arity = get_function_arity expression.pexp_desc in
          let implementation = make_implementation ~loc function_arity in
          [%stri let [%p fn_pattern] = [%e implementation]]
      (* %mel. *)
      (* external foo: t = "{{JavaScript}}" *)
      | Pstr_primitive { pval_name; pval_attributes; pval_loc; pval_type } ->
          transform_external pval_name pval_attributes pval_loc pval_type
      | _ -> super#structure_item item
  end

let structure_mapper s = (new raise_exception_mapper)#structure s

module Debug = struct
  let rule =
    let extractor = Ast_pattern.(__') in
    let handler ~ctxt:_ { loc } = [%expr ()] in
    Context_free.Rule.extension
      (Extension.V3.declare "debug" Extension.Context.expression extractor
         handler)
end

let () =
  Driver.register_transformation ~impl:structure_mapper
    ~rules:[ Pipe_first.rule; Regex.rule; Double_hash.rule; Debug.rule ]
    "melange-native-ppx"
