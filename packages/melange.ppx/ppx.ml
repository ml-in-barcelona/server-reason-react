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

(* let has_mel_raw_attr pval_attributes =
   has_ptyp_attribute ptyp_attributes "mel.raw"
*)
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

let raise_failure () =
  (* TODO: Improve this error *)
  let loc = Location.none in
  [%expr raise (Failure "called Melange external \"mel.\" from native")]

let make_type ~loc arity =
  match arity with
  | 0 -> [%type: 'a]
  | 1 -> [%type: 'a -> 'b]
  | 2 -> [%type: 'a -> 'b -> 'c]
  | 3 -> [%type: 'a -> 'b -> 'c -> 'd]
  | 4 -> [%type: 'a -> 'b -> 'c -> 'd -> 'e]
  | 5 -> [%type: 'a -> 'b -> 'c -> 'd -> 'e -> 'f]
  | 6 -> [%type: 'a -> 'b -> 'c -> 'd -> 'e -> 'f -> 'g]
  | 7 -> [%type: 'a -> 'b -> 'c -> 'd -> 'e -> 'f -> 'g -> 'h]
  | _ -> failwith "Melange: Too many arguments"

let make_implementation ~loc arity =
  match arity with
  | 0 -> [%expr [%e raise_failure ()]]
  | 1 -> [%expr fun _ -> [%e raise_failure ()]]
  | 2 -> [%expr fun _ _ -> [%e raise_failure ()]]
  | 3 -> [%expr fun _ _ _ -> [%e raise_failure ()]]
  | 4 -> [%expr fun _ _ _ _ -> [%e raise_failure ()]]
  | 5 -> [%expr fun _ _ _ _ _ -> [%e raise_failure ()]]
  | 6 -> [%expr fun _ _ _ _ _ _ -> [%e raise_failure ()]]
  | 7 -> [%expr fun _ _ _ _ _ _ _ -> [%e raise_failure ()]]
  | _ -> failwith "Melange: Too many arguments"

let browser_only_alert_payload ~loc =
  {
    attr_name = { txt = "alert"; loc };
    attr_payload =
      PStr
        [
          [%stri
            browser_only
              "Since it's a [%mel.raw ...]. This expression is marked to only \
               run on the browser where JavaScript can run. You can only use \
               it inside a let%browser_only function."];
        ];
    attr_loc = loc;
  }

let make_value_description ~loc name arity =
  let name = { txt = name; loc } in
  let type_ = make_type ~loc arity in
  let value_description =
    Builder.value_description ~loc ~name ~type_ ~prim:[]
  in
  {
    value_description with
    pval_attributes = [ browser_only_alert_payload ~loc ];
  }

let get_function_arity pattern =
  let rec go arity = function
    | Pexp_fun (_, _, _, expr) -> go (arity + 1) expr.pexp_desc
    | _ -> arity
  in
  go 0 pattern

class raise_exception_mapper =
  object (_self)
    inherit Ast_traverse.map as super

    method! structure_item item =
      match item.pstr_desc with
      (* let a _ = [%mel.raw ...] *)
      | Pstr_value
          ( Nonrecursive,
            [
              {
                pvb_expr =
                  {
                    pexp_desc =
                      Pexp_fun
                        (arg_label, arg_expression, fun_pattern, expression);
                  } as pvb_expr;
                pvb_pat =
                  { ppat_desc = Ppat_var { txt = function_name; _ } } as
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
              ppat_attributes = [ browser_only_alert_payload ~loc ];
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
                  { ppat_desc = Ppat_var { txt = function_name; _ } } as pattern;
                pvb_attributes = _;
                pvb_loc = _;
              };
            ] )
        when expression_has_mel_raw expression.pexp_desc ->
          let loc = item.pstr_loc in
          let fn_pattern =
            {
              pattern with
              ppat_attributes = [ browser_only_alert_payload ~loc ];
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
                      Ppat_constraint (constrain_pattern, constrain_type);
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
              ppat_attributes = [ browser_only_alert_payload ~loc ];
            }
          in
          let function_arity = get_function_arity expression.pexp_desc in
          let implementation = make_implementation ~loc function_arity in
          [%stri let [%p fn_pattern] = [%e implementation]]
      (* %mel. *)
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
    ~rules:[ Pipe_first.rule; Regex.rule; Double_hash.rule ]
    "melange-native-ppx"
