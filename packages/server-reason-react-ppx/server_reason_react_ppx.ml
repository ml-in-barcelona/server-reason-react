open Ppxlib
open Ast_builder.Default
module List = ListLabels

let repo_url = "https://github.com/ml-in-barcelona/server-reason-react"
let issues_url = repo_url |> Printf.sprintf "%s/issues"

(* There's no pexp_list on Ppxlib since isn't a constructor of the Parsetree *)
let pexp_list ~loc xs =
  List.fold_left (List.rev xs) ~init:[%expr []] ~f:(fun xs x ->
      let loc = x.pexp_loc in
      [%expr [%e x] :: [%e xs]])

exception Error of expression

let raise_errorf ~loc fmt =
  Printf.ksprintf
    (fun msg ->
      let expr = pexp_extension ~loc (Location.error_extensionf ~loc "%s" msg) in
      raise (Error expr))
    fmt

let make_string ~loc str = Ast_helper.Exp.constant ~loc (Ast_helper.Const.string str)
let react_dot_component = "react.component"
let react_dot_async_dot_component = "react.async.component"

(* Helper method to look up the [@react.component] attribute *)
let hasAttr { attr_name; _ } comparable = attr_name.txt = comparable

let hasReactComponentAttr { attr_name; _ } =
  attr_name.txt = react_dot_component || attr_name.txt = react_dot_async_dot_component

(* Helper method to filter out any attribute that isn't [@react.component] *)
let otherAttrsPure { attr_name; _ } =
  attr_name.txt <> react_dot_component && attr_name.txt <> react_dot_async_dot_component

let hasNotAttrOnBinding { pvb_attributes } comparable =
  List.find_opt ~f:(fun attr -> hasAttr attr comparable) pvb_attributes = None

let hasAttrOnBinding { pvb_attributes } comparable =
  List.find_opt ~f:(fun attr -> hasAttr attr comparable) pvb_attributes <> None

let rec unwrap_children children = function
  | { pexp_desc = Pexp_construct ({ txt = Lident "[]"; _ }, None); _ } -> List.rev children
  | { pexp_desc = Pexp_construct ({ txt = Lident "::"; _ }, Some { pexp_desc = Pexp_tuple [ child; next ]; _ }); _ } ->
      unwrap_children (child :: children) next
  | e -> raise_errorf ~loc:e.pexp_loc "jsx: children prop should be a list"

let is_jsx = function { attr_name = { txt = "JSX"; _ }; _ } -> true | _ -> false
let has_jsx_attr attrs = List.exists ~f:is_jsx attrs

let rewrite_component ~loc tag args children =
  let component = pexp_ident ~loc tag in
  let props =
    match children with
    | None -> args
    | Some [ children ] -> (Labelled "children", children) :: args
    | Some children -> (Labelled "children", [%expr React.list [%e pexp_list ~loc children]]) :: args
  in
  pexp_apply ~loc component props

let validate_prop ~loc id name =
  match DomProps.findByJsxName ~tag:id name with
  | Ok p -> p
  | Error `ElementNotFound ->
      raise_errorf ~loc "jsx: HTML tag '%s' doesn't exist.\nIf this isn't correct, please open an issue at %s" id
        issues_url
  | Error `AttributeNotFound -> (
      match DomProps.findClosestName name with
      | None ->
          raise_errorf ~loc
            "jsx: prop '%s' isn't valid on a '%s' element.\nIf this isn't correct, please open an issue at %s." name id
            issues_url
      | Some suggestion ->
          raise_errorf ~loc
            "jsx: prop '%s' isn't valid on a '%s' element.\n\
             Hint: Maybe you mean '%s'?\n\n\
             If this isn't correct, please open an issue at %s."
            name id suggestion issues_url)

let make_prop ~is_optional ~prop attribute_value =
  let loc = attribute_value.pexp_loc in
  let open DomProps in
  match (prop, is_optional) with
  | Attribute { type_ = DomProps.String; name; jsxName }, false ->
      [%expr
        Some (React.JSX.String ([%e estring ~loc name], [%e estring ~loc jsxName], ([%e attribute_value] : string)))]
  | Attribute { type_ = DomProps.String; name; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : string option) with
        | None -> None
        | Some v -> Some (React.JSX.String ([%e estring ~loc name], [%e estring ~loc jsxName], v))]
  | Attribute { type_ = DomProps.Int; name; jsxName }, false ->
      [%expr
        Some
          (React.JSX.String
             ([%e estring ~loc name], [%e estring ~loc jsxName], string_of_int ([%e attribute_value] : int)))]
  | Attribute { type_ = DomProps.Int; name; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : int option) with
        | None -> None
        | Some v -> Some (React.JSX.String ([%e estring ~loc name], [%e estring ~loc jsxName], string_of_int v))]
  | Attribute { type_ = DomProps.Bool; name; jsxName }, false ->
      [%expr Some (React.JSX.Bool ([%e estring ~loc name], [%e estring ~loc jsxName], ([%e attribute_value] : bool)))]
  | Attribute { type_ = DomProps.Bool; name; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : bool option) with
        | None -> None
        | Some v -> Some (React.JSX.Bool ([%e estring ~loc name], [%e estring ~loc jsxName], v))]
  (* BooleanishString needs to transform bool into string *)
  | Attribute { type_ = DomProps.BooleanishString; name; jsxName }, false ->
      [%expr
        Some
          (React.JSX.String
             ([%e estring ~loc name], [%e estring ~loc jsxName], string_of_bool ([%e attribute_value] : bool)))]
  | Attribute { type_ = DomProps.BooleanishString; name; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : bool option) with
        | None -> None
        | Some v -> Some (React.JSX.String ([%e estring ~loc name], [%e estring ~loc jsxName], string_of_bool v))]
  | Attribute { type_ = DomProps.Style; _ }, false ->
      [%expr Some (React.JSX.Style (ReactDOM.Style.to_string ([%e attribute_value] : ReactDOM.Style.t)))]
  | Attribute { type_ = DomProps.Style; _ }, true ->
      [%expr
        match ([%e attribute_value] : ReactDOM.Style.t option) with
        | None -> None
        | Some v -> Some (React.JSX.Style (ReactDOM.Style.to_string v))]
  | Attribute { type_ = DomProps.Ref; _ }, false -> [%expr Some (React.JSX.Ref ([%e attribute_value] : React.domRef))]
  | Attribute { type_ = DomProps.Ref; _ }, true ->
      [%expr match ([%e attribute_value] : React.domRef option) with None -> None | Some v -> Some (React.JSX.Ref v)]
  | Attribute { type_ = DomProps.InnerHtml; _ }, false ->
      [%expr Some (React.JSX.dangerouslyInnerHtml [%e attribute_value])]
  | Attribute { type_ = DomProps.InnerHtml; _ }, true ->
      [%expr match [%e attribute_value] with None -> None | Some v -> Some (React.JSX.dangerouslyInnerHtml v)]
  | Event { type_ = Mouse; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Mouse (fun _ -> () : React.Event.Mouse.t -> unit)))]
  | Event { type_ = Mouse; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Mouse.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Mouse (fun _ -> ())))]
  | Event { type_ = Selection; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Selection (fun _ -> () : React.Event.Mouse.t -> unit)))]
  | Event { type_ = Selection; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Selection.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Selection (fun _ -> ())))]
  | Event { type_ = Touch; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Touch (fun _ -> () : React.Event.Touch.t -> unit)))]
  | Event { type_ = Touch; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Touch.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Touch (fun _ -> ())))]
  | Event { type_ = UI; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.UI (fun _ -> () : React.Event.UI.t -> unit)))]
  | Event { type_ = UI; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.UI.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.UI (fun _ -> ())))]
  | Event { type_ = Wheel; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Wheel (fun _ -> () : React.Event.Wheel.t -> unit)))]
  | Event { type_ = Wheel; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Wheel.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Wheel (fun _ -> ())))]
  | Event { type_ = Clipboard; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ( [%e make_string ~loc jsxName],
               React.JSX.Clipboard (fun _ -> () : React.Event.Clipboard.t -> unit) ))]
  | Event { type_ = Clipboard; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Clipboard.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Clipboard (fun _ -> ())))]
  | Event { type_ = Composition; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ( [%e make_string ~loc jsxName],
               React.JSX.Composition (fun _ -> () : React.Event.Composition.t -> unit) ))]
  | Event { type_ = Composition; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Composition.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Composition (fun _ -> ())))]
  | Event { type_ = Keyboard; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Keyboard (fun _ -> () : React.Event.Keyboard.t -> unit)))]
  | Event { type_ = Keyboard; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Keyboard.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Keyboard (fun _ -> ())))]
  | Event { type_ = Focus; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Focus (fun _ -> () : React.Event.Focus.t -> unit)))]
  | Event { type_ = Focus; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Focus.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Focus (fun _ -> ())))]
  | Event { type_ = Form; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Form (fun _ -> () : React.Event.Form.t -> unit)))]
  | Event { type_ = Form; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Form.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Form (fun _ -> ())))]
  | Event { type_ = Media; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Media (fun _ -> () : React.Event.Media.t -> unit)))]
  | Event { type_ = Media; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Media.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Media (fun _ -> ())))]
  | Event { type_ = Inline; jsxName }, false ->
      [%expr Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Inline ([%e attribute_value] : string)))]
  | Event { type_ = Inline; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : string option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Inline (fun _ -> ())))]
  | Event { type_ = Image; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ( [%e make_string ~loc jsxName],
               React.JSX.Image ([%e attribute_value] : (React.Event.Image.t -> unit) option) ))]
  | Event { type_ = Image; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Image.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Image (fun _ -> ())))]
  | Event { type_ = Animation; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ( [%e make_string ~loc jsxName],
               React.JSX.Animation (fun _ -> () : React.Event.Animation.t -> unit) ))]
  | Event { type_ = Animation; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Animation.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Animation (fun _ -> ())))]
  | Event { type_ = Transition; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ( [%e make_string ~loc jsxName],
               React.JSX.Transition (fun _ -> () : React.Event.Transition.t -> unit) ))]
  | Event { type_ = Transition; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Transition.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Transition (fun _ -> ())))]
  | Event { type_ = Pointer; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Pointer (fun _ -> () : React.Event.Pointer.t -> unit)))]
  | Event { type_ = Pointer; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Pointer.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Pointer (fun _ -> ())))]
  | Event { type_ = Drag; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Drag (fun _ -> () : React.Event.Drag.t -> unit)))]
  | Event { type_ = Drag; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Drag.t -> unit) option) with
        | None -> None
        | Some _ -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Drag (fun _ -> ())))]

let is_optional = function Optional _ -> true | _ -> false

let transform_labelled ~loc ~tag_name (prop_label, (runtime_value : expression)) props =
  match prop_label with
  | Nolabel -> props
  | Optional name | Labelled name ->
      let is_optional = is_optional prop_label in
      let prop = validate_prop ~loc tag_name name in
      let new_prop = make_prop ~is_optional ~prop runtime_value in
      [%expr [%e new_prop] :: [%e props]]

let transform_lowercase_props ~loc ~tag_name args =
  match args with
  | [] -> [%expr []]
  | attrs -> (
      let list_of_attributes = attrs |> List.fold_right ~f:(transform_labelled ~loc ~tag_name) ~init:[%expr []] in
      match list_of_attributes with
      | [%expr []] -> [%expr []]
      | _ ->
          (* We need to filter attributes since optionals are represented as None *)
          [%expr Stdlib.List.filter_map Fun.id [%e list_of_attributes]])

let rewrite_lowercase ~loc:exprLoc tag_name args children =
  let loc = exprLoc in
  let dom_node_name = estring ~loc:exprLoc tag_name in
  let props = transform_lowercase_props ~loc:exprLoc ~tag_name args in
  match children with
  | Some children ->
      let childrens = pexp_list ~loc children in
      [%expr React.createElement [%e dom_node_name] [%e props] [%e childrens]]
  | None -> [%expr React.createElement [%e dom_node_name] [%e props] []]

let split_args args =
  let children = ref (Location.none, []) in
  let rest =
    List.filter_map args ~f:(function
      | Labelled "children", children_expression ->
          let children' = unwrap_children [] children_expression in
          children := (children_expression.pexp_loc, children');
          None
      | arg_label, e -> Some (arg_label, e))
  in
  let children_prop = match !children with _loc, [] -> None | _loc, children -> Some children in
  (children_prop, rest)

let reverse_pexp_list ~loc expr =
  let rec go acc = function
    | [%expr []] -> acc
    | [%expr [%e? hd] :: [%e? tl]] -> go [%expr [%e hd] :: [%e acc]] tl
    | expr -> expr
  in
  go [%expr []] expr

let list_have_tail expr =
  match expr with
  | Pexp_construct ({ txt = Lident "::"; _ }, Some { pexp_desc = Pexp_tuple _; _ })
  | Pexp_construct ({ txt = Lident "[]"; _ }, None) ->
      false
  | _ -> true

let transform_items_of_list ~loc children =
  let rec run_mapper children accum =
    match children with
    | [%expr []] -> reverse_pexp_list ~loc accum
    | [%expr [%e? v] :: [%e? acc]] when list_have_tail acc.pexp_desc -> [%expr [%e v]]
    | [%expr [%e? v] :: [%e? acc]] -> run_mapper acc [%expr [%e v] :: [%e accum]]
    | notAList -> notAList
  in
  run_mapper children [%expr []]

let remove_warning_16_optional_argument_cannot_be_erased ~loc =
  let open Ast_helper in
  {
    attr_name = { txt = "warning"; loc };
    attr_payload = PStr [ Str.eval (Ast_helper.Exp.constant (Const.string "-16")) ];
    attr_loc = loc;
  }

let remove_warning_27_unused_var_strict ~loc =
  let open Ast_helper in
  {
    attr_name = { txt = "warning"; loc };
    attr_payload = PStr [ Str.eval (Ast_helper.Exp.constant (Const.string "-27")) ];
    attr_loc = loc;
  }

(* Finds the name of the variable the binding is assigned to, otherwise raises *)
let get_function_name binding =
  match binding with
  | { pvb_pat = { ppat_desc = Ppat_var { txt } } } -> txt
  | _ -> raise_errorf ~loc:binding.pvb_loc "react.component calls cannot be destructured."

(* TODO: there are a few unsupported features inside of blocks - Pexp_letmodule , Pexp_letexception , Pexp_ifthenelse *)
let add_unit_at_the_last_argument expression =
  let loc = expression.pexp_loc in
  let rec inner expression =
    match expression.pexp_desc with
    (* let make = (~prop) => ... with no final unit *)
    | Pexp_fun
        (((Labelled _ | Optional _) as label), default, pattern, ({ pexp_desc = Pexp_fun _ } as internalExpression)) ->
        pexp_fun ~loc:expression.pexp_loc label default pattern (inner internalExpression)
    (* let make = (()) => ... *)
    (* let make = (_) => ... *)
    | Pexp_fun (Nolabel, _, { ppat_desc = Ppat_construct ({ txt = Lident "()" }, _) | Ppat_any }, _) -> expression
    (* let make = (~prop) => ... *)
    | Pexp_fun (label, default, pattern, internalExpression) ->
        {
          expression with
          pexp_attributes = remove_warning_16_optional_argument_cannot_be_erased ~loc :: expression.pexp_attributes;
          pexp_desc =
            Pexp_fun
              (label, default, pattern, pexp_fun ~loc:expression.pexp_loc Nolabel None [%pat? ()] internalExpression);
        }
    (* let make = {let foo = bar in (~prop) => ...} *)
    | Pexp_let (recursive, vbs, internalExpression) ->
        pexp_let ~loc:expression.pexp_loc recursive vbs (inner internalExpression)
    (* let make = React.forwardRef((~prop) => ...) *)
    | Pexp_apply (_, [ (Nolabel, internalExpression) ]) -> inner internalExpression
    (* let make = React.memoCustomCompareProps((~prop) => ..., (prevPros, nextProps) => true) *)
    | Pexp_apply (_, [ (Nolabel, internalExpression); ((Nolabel, { pexp_desc = Pexp_fun _ }) as _compareProps) ]) ->
        inner internalExpression
    | Pexp_sequence (wrapperExpression, internalExpression) ->
        pexp_sequence ~loc:expression.pexp_loc wrapperExpression (inner internalExpression)
    | _ -> expression
  in
  inner expression

let transform_fun_body_expression expr fn =
  let rec inner expr =
    match expr.pexp_desc with
    | Pexp_fun (label, def, patt, expression) -> pexp_fun ~loc:expr.pexp_loc label def patt (inner expression)
    | _ -> fn expr
  in

  inner expr

let make_value_binding binding react_element_variant_wrapping =
  let loc = binding.pvb_loc in
  let ghost_loc = { binding.pvb_loc with loc_ghost = true } in
  let binding_with_unit = add_unit_at_the_last_argument binding.pvb_expr in
  let binding_expr = transform_fun_body_expression binding_with_unit react_element_variant_wrapping in
  (* Builds an AST node for the modified `make` function *)
  let name = Ast_helper.Pat.mk ~loc:ghost_loc (Ppat_var { txt = get_function_name binding; loc = ghost_loc }) in
  let key_arg = Optional "key" in
  (* default_value = None means there's no default *)
  let default_value = None in
  let key_renamed_to_underscore = ppat_var ~loc:ghost_loc { txt = "_"; loc } in
  let core_type = [%type: string option] in
  let key_pattern = ppat_constraint ~loc key_renamed_to_underscore core_type in
  (* Append key argument since we want to allow users of this component to set key
     (and assign it to _ since it shouldn't be used) *)
  let function_body = pexp_fun ~loc:ghost_loc key_arg default_value key_pattern binding_expr in
  Ast_helper.Vb.mk ~loc name function_body

let rewrite_signature_item signature_item =
  (* Remove the [@react.component] from the AST *)
  match signature_item with
  | {
      psig_loc = _;
      psig_desc = Psig_value ({ pval_name = { txt = _fnName }; pval_attributes; pval_type } as psig_desc);
    } as psig -> (
      match List.filter ~f:hasReactComponentAttr pval_attributes with
      | [] -> signature_item
      | [ _ ] ->
          {
            psig with
            psig_desc =
              Psig_value { psig_desc with pval_type; pval_attributes = List.filter ~f:otherAttrsPure pval_attributes };
          }
      | _ ->
          let loc = signature_item.psig_loc in
          [%sigi:
            [%%ocaml.error
            "externals aren't supported on server-reason-react. externals are used to bind to React components from \
             JavaScript. In the server, that doesn't make sense. If you need to render this on the server, implement a \
             stub component or an empty element (React.null)"]])
  | _signature_item -> signature_item

let rewrite_structure_item structure_item =
  match structure_item.pstr_desc with
  (* external *)
  | Pstr_primitive ({ pval_name = { txt = _fnName }; pval_attributes; pval_type = _ } as _value_description) -> (
      match
        List.filter
          ~f:(fun attr -> hasAttr attr react_dot_component || hasAttr attr react_dot_async_dot_component)
          pval_attributes
      with
      | [] -> structure_item
      | _ ->
          let loc = structure_item.pstr_loc in
          [%stri
            [%%ocaml.error
            "externals aren't supported on server-reason-react. externals are used to bind to React components defined \
             in JavaScript, in the server, that doesn't make sense. If you need to render this on the server, \
             implement a placeholder or an empty element"]])
  (* let component = ... *)
  | Pstr_value (rec_flag, value_bindings) ->
      let map_value_binding vb =
        if hasAttrOnBinding vb react_dot_component then
          make_value_binding vb (fun expr ->
              let loc = expr.pexp_loc in
              [%expr React.Upper_case_component (fun () -> [%e expr])])
        else if hasAttrOnBinding vb react_dot_async_dot_component then
          make_value_binding vb (fun expr ->
              let loc = expr.pexp_loc in
              [%expr React.Async_component (fun () -> [%e expr])])
        else vb
      in
      let bindings = List.map ~f:map_value_binding value_bindings in
      pstr_value ~loc:structure_item.pstr_loc rec_flag bindings
  | _ -> structure_item

let rewrite_jsx =
  object (_ : Ast_traverse.map)
    inherit Ast_traverse.map as super
    method! structure_item structure_item = rewrite_structure_item (super#structure_item structure_item)
    method! signature_item signature_item = rewrite_signature_item (super#signature_item signature_item)

    method! expression expr =
      let expr = super#expression expr in
      try
        match expr.pexp_desc with
        | Pexp_apply (({ pexp_desc = Pexp_ident _; _ } as tag), args) when has_jsx_attr expr.pexp_attributes -> (
            let children, rest_of_args = split_args args in
            match tag.pexp_desc with
            (* div() [@JSX] *)
            | Pexp_ident { txt = Lident name; loc = _name_loc } ->
                rewrite_lowercase ~loc:expr.pexp_loc name rest_of_args children
            (* Reason adds `createElement` as default when an uppercase is found,
               we change it back to make *)
            (* Foo.createElement() [@JSX] *)
            | Pexp_ident { txt = Ldot (modulePath, ("createElement" | "make")); loc } ->
                let id = { loc; txt = Ldot (modulePath, "make") } in
                rewrite_component ~loc:expr.pexp_loc id rest_of_args children
            (* local_function() [@JSX] *)
            | Pexp_ident id -> rewrite_component ~loc:expr.pexp_loc id rest_of_args children
            | _ -> assert false)
        (* div() [@JSX] *)
        | Pexp_apply (tag, _props) when has_jsx_attr expr.pexp_attributes ->
            raise_errorf ~loc:expr.pexp_loc "jsx: %s should be an identifier, not an expression"
              (Ppxlib_ast.Pprintast.string_of_expression tag)
        (* <> </> is represented as a list in the Parsetree with [@JSX] *)
        | Pexp_construct ({ txt = Lident "::"; loc }, Some { pexp_desc = Pexp_tuple _; _ })
        | Pexp_construct ({ txt = Lident "[]"; loc }, None) -> (
            let jsx_attr, rest_attributes = List.partition ~f:is_jsx expr.pexp_attributes in
            match (jsx_attr, rest_attributes) with
            | [], _ -> expr
            | _, rest_attributes ->
                let children = transform_items_of_list ~loc expr in
                let new_expr = [%expr React.fragment (React.list [%e children])] in
                { new_expr with pexp_attributes = rest_attributes })
        | _ -> expr
      with Error err -> [%expr [%e err]]
  end

let () =
  Ppxlib.Driver.register_transformation "server-reason-react.ppx" ~impl:rewrite_jsx#structure
    ~intf:rewrite_jsx#signature
