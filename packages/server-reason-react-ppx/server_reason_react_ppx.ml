open Ppxlib
open Ast_builder.Default
module List = ListLabels

type target = Native | Js

let mode = ref Native
let repo_url = "https://github.com/ml-in-barcelona/server-reason-react"
let issues_url = Printf.sprintf "%s/issues" repo_url

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

let longident ~loc txt = { txt = Lident txt; loc }
let ident ~loc txt = pexp_ident ~loc (longident ~loc txt)
let make_string ~loc str = Ast_helper.Exp.constant ~loc (Ast_helper.Const.string str)
let react_dot_component = "react.component"
let react_dot_async_dot_component = "react.async.component"
let react_dot_client_dot_component = "react.client.component"

(* Helper method to look up the [@react.component] attribute *)
let hasAttr { attr_name; _ } comparable = attr_name.txt = comparable

let hasAnyReactComponentAttribute { attr_name; _ } =
  attr_name.txt = react_dot_component
  || attr_name.txt = react_dot_async_dot_component
  || attr_name.txt = react_dot_client_dot_component

(* Helper method to filter out any attribute that isn't [@react.component] *)
let nonReactAttributes { attr_name; _ } =
  attr_name.txt <> react_dot_component
  && attr_name.txt <> react_dot_async_dot_component
  && attr_name.txt <> react_dot_client_dot_component

let hasAttrOnBinding { pvb_attributes } comparable =
  List.find_opt ~f:(fun attr -> hasAttr attr comparable) pvb_attributes <> None

let isReactComponentBinding vb = hasAttrOnBinding vb react_dot_component
let isReactAsyncComponentBinding vb = hasAttrOnBinding vb react_dot_async_dot_component
let isReactClientComponentBinding vb = hasAttrOnBinding vb react_dot_client_dot_component

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
  | Attribute { type_ = DomProps.Action; name; jsxName }, false ->
      [%expr
        Some (React.JSX.Action ([%e estring ~loc name], [%e estring ~loc jsxName], ([%e attribute_value] : string)))]
  | Attribute { type_ = DomProps.Action; name; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : string option) with
        | None -> None
        | Some v -> Some (React.JSX.Action ([%e estring ~loc name], [%e estring ~loc jsxName], v))]
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
      [%expr Some (React.JSX.Style ([%e attribute_value] : ReactDOM.Style.t))]
  | Attribute { type_ = DomProps.Style; _ }, true ->
      [%expr
        match ([%e attribute_value] : ReactDOM.Style.t option) with None -> None | Some v -> Some (React.JSX.Style v)]
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
             ([%e make_string ~loc jsxName], React.JSX.Mouse ([%e attribute_value] : React.Event.Mouse.t -> unit)))]
  | Event { type_ = Mouse; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Mouse.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Mouse v))]
  | Event { type_ = Selection; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Selection ([%e attribute_value] : React.Event.Mouse.t -> unit)))]
  | Event { type_ = Selection; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Selection.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Selection v))]
  | Event { type_ = Touch; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Touch ([%e attribute_value] : React.Event.Touch.t -> unit)))]
  | Event { type_ = Touch; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Touch.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Touch v))]
  | Event { type_ = UI; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.UI ([%e attribute_value] : React.Event.UI.t -> unit)))]
  | Event { type_ = UI; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.UI.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.UI v))]
  | Event { type_ = Wheel; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Wheel ([%e attribute_value] : React.Event.Wheel.t -> unit)))]
  | Event { type_ = Wheel; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Wheel.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Wheel v))]
  | Event { type_ = Clipboard; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ( [%e make_string ~loc jsxName],
               React.JSX.Clipboard ([%e attribute_value] : React.Event.Clipboard.t -> unit) ))]
  | Event { type_ = Clipboard; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Clipboard.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Clipboard v))]
  | Event { type_ = Composition; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ( [%e make_string ~loc jsxName],
               React.JSX.Composition ([%e attribute_value] : React.Event.Composition.t -> unit) ))]
  | Event { type_ = Composition; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Composition.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Composition v))]
  | Event { type_ = Keyboard; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Keyboard ([%e attribute_value] : React.Event.Keyboard.t -> unit)))]
  | Event { type_ = Keyboard; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Keyboard.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Keyboard v))]
  | Event { type_ = Focus; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Focus ([%e attribute_value] : React.Event.Focus.t -> unit)))]
  | Event { type_ = Focus; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Focus.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Focus v))]
  | Event { type_ = Form; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Form ([%e attribute_value] : React.Event.Form.t -> unit)))]
  | Event { type_ = Form; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Form.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Form v))]
  | Event { type_ = Media; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Media ([%e attribute_value] : React.Event.Media.t -> unit)))]
  | Event { type_ = Media; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Media.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Media v))]
  | Event { type_ = Inline; jsxName }, false ->
      [%expr Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Inline ([%e attribute_value] : string)))]
  | Event { type_ = Inline; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : string option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Inline v))]
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
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Image v))]
  | Event { type_ = Animation; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ( [%e make_string ~loc jsxName],
               React.JSX.Animation ([%e attribute_value] : React.Event.Animation.t -> unit) ))]
  | Event { type_ = Animation; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Animation.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Animation v))]
  | Event { type_ = Transition; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ( [%e make_string ~loc jsxName],
               React.JSX.Transition ([%e attribute_value] : React.Event.Transition.t -> unit) ))]
  | Event { type_ = Transition; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Transition.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Transition v))]
  | Event { type_ = Pointer; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Pointer ([%e attribute_value] : React.Event.Pointer.t -> unit)))]
  | Event { type_ = Pointer; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Pointer.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Pointer v))]
  | Event { type_ = Drag; jsxName }, false ->
      [%expr
        Some
          (React.JSX.Event
             ([%e make_string ~loc jsxName], React.JSX.Drag ([%e attribute_value] : React.Event.Drag.t -> unit)))]
  | Event { type_ = Drag; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : (React.Event.Drag.t -> unit) option) with
        | None -> None
        | Some v -> Some (React.JSX.Event ([%e make_string ~loc jsxName], React.JSX.Drag v))]

let is_optional = function Optional _ -> true | _ -> false
let get_label = function Nolabel -> "" | Optional name | Labelled name -> name

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
  let key_prop =
    args |> List.find_opt ~f:(fun (label, _) -> get_label label = "key") |> Option.map (fun (_, value) -> value)
  in
  let key = match key_prop with None -> [%expr None] | Some key -> [%expr Some [%e key]] in
  let props = transform_lowercase_props ~loc:exprLoc ~tag_name args in
  match children with
  | Some children ->
      let childrens = pexp_list ~loc children in
      [%expr React.createElementWithKey ~key:[%e key] [%e dom_node_name] [%e props] [%e childrens]]
  | None -> [%expr React.createElementWithKey ~key:[%e key] [%e dom_node_name] [%e props] []]

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
    attr_payload = PStr [ Str.eval (Exp.constant (Const.string "-16")) ];
    attr_loc = loc;
  }

let remove_warning_27_unused_var_strict ~loc =
  let open Ast_helper in
  {
    attr_name = { txt = "warning"; loc };
    attr_payload = PStr [ Str.eval (Exp.constant (Const.string "-27")) ];
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

let transform_fun_arguments expr fn =
  let rec inner expr =
    match expr.pexp_desc with
    | Pexp_fun (label, def, patt, expression) -> pexp_fun ~loc:expr.pexp_loc label def (fn patt) (inner expression)
    | _ -> expr
  in
  inner expr

let transform_labelled_arguments_type (core_type : core_type) fn =
  let rec inner core_type =
    match core_type.ptyp_desc with
    | Ptyp_arrow (label, core_type_1, core_type_2) ->
        ptyp_arrow ~loc:core_type.ptyp_loc label (fn core_type_1) (inner core_type_2)
    | _ -> core_type
  in
  inner core_type

let expand_make_binding binding react_element_variant_wrapping =
  let attributers = binding.pvb_attributes |> List.filter ~f:nonReactAttributes in
  let loc = binding.pvb_loc in
  let ghost_loc = { binding.pvb_loc with loc_ghost = true } in
  let binding_with_unit = add_unit_at_the_last_argument binding.pvb_expr in
  let binding_expr = transform_fun_body_expression binding_with_unit react_element_variant_wrapping in
  (* Builds an AST node for the modified `make` function *)
  let name = ppat_var ~loc:ghost_loc { txt = get_function_name binding; loc = ghost_loc } in
  let key_arg = Optional "key" in
  (* default_value = None means there's no default *)
  let default_value = None in
  let key_renamed_to_underscore = ppat_var ~loc:ghost_loc { txt = "_"; loc } in
  let core_type = [%type: string option] in
  let key_pattern = ppat_constraint ~loc key_renamed_to_underscore core_type in
  (* Append key argument since we want to allow users of this component to set key
     (and assign it to _ since it shouldn't be used) *)
  let function_body = pexp_fun ~loc:ghost_loc key_arg default_value key_pattern binding_expr in
  (* Since expand_make_binding is called on both native and js contexts, we need to keep the attributes *)
  { (value_binding ~loc:ghost_loc ~pat:name ~expr:function_body) with pvb_attributes = attributers }

let get_labelled_arguments pvb_expr =
  let rec go acc = function
    | Pexp_fun (label, default, patt, expr) -> go ((label, default, patt) :: acc) expr.pexp_desc
    | _ -> acc
  in
  go [] pvb_expr.pexp_desc

let make_of_json ~loc (core_type : core_type) prop =
  match core_type with
  (* QUESTION: How do we handle especial types on props,
     like `("someProp"), `List([React.element, string]).
     We already support it, but not with the ppx.
     Checkout the test_RSC_model.ml for more details. packages/reactDom/test/test_RSC_html.ml *)
  (* QUESTION: How can we handle optionals and others? Need a [@deriving rsc] for them? We currently encode None's as React.Json `Null, should be enought *)
  | [%type: React.element] -> [%expr ([%e prop] : React.element)]
  | [%type: React.element option] -> [%expr ([%e prop] : React.element option)]
  (* TODO: Add promise caching? When is it needed? *)
  (* | [%type: [%t? t] Js.Promise.t] ->
     [%expr
       let promise = [%e prop] in
       let promise' = (Obj.magic promise : [%t t] Js.Promise.t Js.Dict.t) in
       match Js.Dict.get promise' "__promise" with
       | Some promise -> promise
       | None ->
           let promise =
             Promise.(
               let* json = (Obj.magic (Js.Promise.resolve promise) : Realm.Json.t Promise.t) in
               let data = [%of_json: [%t t]] json in
               return data)
           in
           Js.Dict.set promise' "__promise" promise;
           promise] *)
  | [%type: [%t? t] Js.Promise.t] -> [%expr ([%e prop] : [%t t] Js.Promise.t)]
  | [%type: [%t? inner_type] option] as type_ -> (
      match inner_type.ptyp_desc with
      | Ptyp_arrow (_, _, _) -> [%expr ([%e prop] : [%t type_])]
      | _ -> [%expr [%of_json: [%t type_]] [%e prop]])
  | type_ -> (
      match type_.ptyp_desc with
      | Ptyp_arrow (_, _, _) -> [%expr ([%e prop] : [%t type_])]
      | _ -> [%expr [%of_json: [%t type_]] [%e prop]])

let props_of_model ~loc (props : (arg_label * expression option * pattern) list) : (longident loc * expression) list =
  List.filter_map
    ~f:(fun (arg_label, default, pattern) ->
      match pattern.ppat_desc with
      | Ppat_construct ({ txt = Lident "()"; _ }, None) -> None
      | Ppat_constraint (_, core_type) -> (
          match arg_label with
          | Nolabel ->
              (* This error is raised by reason-react-ppx as well *)
              let loc = pattern.ppat_loc in
              Some (longident ~loc "error", [%expr [%ocaml.error "props need to be labelled arguments"]])
          | Labelled label | Optional label ->
              let core_type = match default with Some _ -> [%type: [%t core_type] option] | None -> core_type in
              let prop = [%expr props##[%e ident ~loc label]] in
              let value = make_of_json ~loc core_type prop in
              Some (longident ~loc label, value))
      | _ ->
          let loc = pattern.ppat_loc in
          let expr =
            match arg_label with
            | Nolabel -> [%expr [%ocaml.error "server-reason-react: client components need type annotations"]]
            | Labelled label | Optional label ->
                let msg =
                  Printf.sprintf
                    "server-reason-react: client components need type annotations. Missing annotation for '%s'" label
                in
                let msg_expr = estring ~loc msg in
                [%expr [%ocaml.error [%e msg_expr]]]
          in
          Some (longident ~loc "error", expr))
    props

let react_component_attribute ~loc =
  { attr_name = { txt = "react.component"; loc }; attr_payload = PStr []; attr_loc = loc }

let mel_obj ~loc fields =
  match fields with
  (* QUESTION: Maybe unit would work here best, for correctness? *)
  | [] -> [%expr Js.Obj.empty ()]
  | _ ->
      let record = pexp_record ~loc fields None in
      let stri = pstr_eval ~loc record [] in
      [%expr [%mel.obj [%%i stri]]]

let expand_make_binding_to_client binding =
  let loc = binding.pvb_loc in
  let ghost_loc = { binding.pvb_loc with loc_ghost = true } in
  let labelled_arguments = get_labelled_arguments binding.pvb_expr in
  let props_as_object_with_decoders = mel_obj ~loc (props_of_model ~loc labelled_arguments) in
  let make_argument = [ (Nolabel, props_as_object_with_decoders) ] in
  let make_call = pexp_apply ~loc:ghost_loc [%expr make] make_argument in
  let name = ppat_var ~loc:ghost_loc { txt = "make_client"; loc = ghost_loc } in
  let client_single_argument = ppat_var ~loc:ghost_loc { txt = "props"; loc } in
  let function_body = pexp_fun ~loc:ghost_loc Nolabel None client_single_argument make_call in
  value_binding ~loc:ghost_loc ~pat:name ~expr:function_body

let rec add_unit_at_the_last_argument_in_core_type core_type =
  match core_type.ptyp_desc with
  | Ptyp_arrow (arg_label, core_type_1, core_type_2) ->
      {
        core_type with
        ptyp_desc = Ptyp_arrow (arg_label, core_type_1, add_unit_at_the_last_argument_in_core_type core_type_2);
      }
  | Ptyp_constr _ ->
      let loc = core_type.ptyp_loc in
      { core_type with ptyp_desc = Ptyp_arrow (Nolabel, [%type: unit], core_type) }
  | _ -> core_type

let rewrite_signature_item signature_item =
  (* Removes the [@react.component] from the AST *)
  match signature_item with
  | {
      psig_loc = _;
      psig_desc = Psig_value ({ pval_name = { txt = _fnName }; pval_attributes; pval_type } as psig_desc);
    } as psig -> (
      let new_ptyp_desc =
        match pval_type.ptyp_desc with
        | Ptyp_arrow (arg_label, core_type_1, core_type_2) ->
            let loc = pval_type.ptyp_loc in
            let original_core_type = { pval_type with ptyp_desc = Ptyp_arrow (arg_label, core_type_1, core_type_2) } in
            let new_core_type = add_unit_at_the_last_argument_in_core_type original_core_type in
            Ptyp_arrow (Optional "key", [%type: string option], new_core_type)
        | ptyp_desc -> ptyp_desc
      in
      let new_core_type = { pval_type with ptyp_desc = new_ptyp_desc } in
      match List.filter ~f:hasAnyReactComponentAttribute pval_attributes with
      | [] -> signature_item
      | [ _ ] ->
          {
            psig with
            psig_desc =
              Psig_value
                {
                  psig_desc with
                  pval_type = new_core_type;
                  pval_attributes = List.filter ~f:nonReactAttributes pval_attributes;
                };
          }
      | _ ->
          let loc = signature_item.psig_loc in
          [%sigi:
            [%%ocaml.error "server-reason-react-ppx: there's seems to be an error in the signature of the component."]])
  | _ -> signature_item

let make_to_json ~loc (core_type : core_type) prop =
  match core_type with
  | [%type: React.element] -> [%expr React.Element ([%e prop] : React.element)]
  | [%type: React.element option] ->
      [%expr match [%e prop] with Some prop -> React.Element (prop : React.element) | None -> React.Json `Null]
  | [%type: [%t? inner_type] Js.Promise.t] ->
      let json = [%expr [%to_json: [%t inner_type]]] in
      [%expr React.Promise ([%e prop], [%e json])]
  | [%type: [%t? inner_type] Js.Promise.t option] ->
      let json = [%expr [%to_json: [%t inner_type]]] in
      [%expr
        match [%e prop] with Some prop -> [%expr React.Promise ([%e prop], [%e json])] | None -> React.Json `Null]
  | { ptyp_desc = Ptyp_arrow (_, _, _) } ->
      let loc = core_type.ptyp_loc in
      [%expr
        [%ocaml.error
          "server-reason-react: you can't pass functions into client components. Functions aren't serialisable to JSON."]]
  | type_ ->
      let json = [%expr [%to_json: [%t type_]] [%e prop]] in
      [%expr React.Json [%e json]]

let props_to_model ~loc (props : (arg_label * expression option * pattern) list) =
  List.fold_left ~init:[%expr []]
    ~f:(fun acc (arg_label, _default, pattern) ->
      match pattern.ppat_desc with
      | Ppat_construct ({ txt = Lident "()"; _ }, None) -> acc
      | Ppat_constraint (_, core_type) -> (
          match arg_label with
          | Nolabel ->
              (* This error is raised by reason-react-ppx as well *)
              let loc = pattern.ppat_loc in
              [%expr [%ocaml.error "props need to be labelled arguments"] :: [%e acc]]
          | Labelled label | Optional label ->
              let prop = ident ~loc label in
              let value = make_to_json ~loc core_type prop in
              let name = estring ~loc label in
              [%expr ([%e name], [%e value]) :: [%e acc]])
      (* TODO: Add all ppat_desc possibilities *)
      | _ ->
          let loc = pattern.ppat_loc in
          let expr =
            match arg_label with
            | Nolabel -> [%expr [%ocaml.error "server-reason-react: client components need type annotations"]]
            | Labelled label | Optional label ->
                let msg =
                  Printf.sprintf
                    "server-reason-react: client components need type annotations. Missing annotation for '%s'" label
                in
                let msg_expr = estring ~loc msg in
                [%expr [%ocaml.error [%e msg_expr]]]
          in
          [%expr [%e expr] :: [%e acc]])
    props

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
  (* let make = ... *)
  | Pstr_value (rec_flag, value_bindings) ->
      let map_value_binding vb =
        if isReactClientComponentBinding vb then
          expand_make_binding vb (fun expr ->
              let loc = expr.pexp_loc in
              let import_module = pexp_ident ~loc { txt = Lident "__FILE__"; loc } in
              let labelled_arguments = get_labelled_arguments vb.pvb_expr in
              (* We transform the arguments from the value binding into React.client_props *)
              let props = props_to_model ~loc labelled_arguments in
              [%expr
                React.Client_component
                  { import_module = [%e import_module]; import_name = ""; props = [%e props]; client = [%e expr] }])
        else if isReactComponentBinding vb then
          expand_make_binding vb (fun expr ->
              let loc = expr.pexp_loc in
              [%expr React.Upper_case_component (__FUNCTION__, fun () -> [%e expr])])
        else if isReactAsyncComponentBinding vb then
          expand_make_binding vb (fun expr ->
              let loc = expr.pexp_loc in
              [%expr React.Async_component (fun () -> [%e expr])])
        else vb
      in
      let bindings = List.map ~f:map_value_binding value_bindings in
      pstr_value ~loc:structure_item.pstr_loc rec_flag bindings
  | _ -> structure_item

let isClientComponentBinding value_bindings =
  let first_binding = List.hd value_bindings in
  isReactClientComponentBinding first_binding

let rewrite_structure_item_for_js ctx structure_item =
  match structure_item.pstr_desc with
  (* external *)
  | Pstr_primitive ({ pval_name = { txt = _fnName }; pval_attributes; pval_type = _ } as _value_description) -> (
      match List.filter ~f:(fun attr -> hasAttr attr react_dot_client_dot_component) pval_attributes with
      | [] -> structure_item
      | _ ->
          let loc = structure_item.pstr_loc in
          [%stri [%%ocaml.error "server-reason-react: externals aren't supported on client components yet"]])
  (* let make = ... *)
  | Pstr_value (rec_flag, value_bindings) when isClientComponentBinding value_bindings ->
      let first_value_binding = List.hd value_bindings in
      let make_client = expand_make_binding_to_client first_value_binding in
      let make_client_binding = pstr_value ~loc:structure_item.pstr_loc rec_flag [ make_client ] in
      let original_value_binding =
        { first_value_binding with pvb_attributes = [ react_component_attribute ~loc:first_value_binding.pvb_loc ] }
      in
      let loc = structure_item.pstr_loc in
      let fileName = Expansion_context.Base.input_name ctx in
      let fileName =
        if String.ends_with ~suffix:".re.ml" fileName then Filename.chop_extension fileName else fileName
      in
      (* We need to add a nasty hack here, since have different files for native and melange.Assume that the file structure is native/lib and js, and replace the name directly. This is supposed to be temporal, until dune implements https://github.com/ocaml/dune/issues/10630 *)
      let fileName = Str.replace_first (Str.regexp {|/js/|}) "/native/lib/" fileName in
      let comment = Printf.sprintf "// extract-client %s" fileName in
      let raw = estring ~loc comment in
      let extract_client_raw = [%stri [%%raw [%e raw]]] in
      [%stri
        include struct
          [%%i extract_client_raw]
          [%%i pstr_value ~loc:structure_item.pstr_loc rec_flag [ original_value_binding ]]
          [%%i make_client_binding]
        end]
  | _ -> structure_item

let contains_client_component structure =
  List.exists
    ~f:(fun structure_item ->
      match structure_item.pstr_desc with
      | Pstr_value (_, value_bindings) -> List.exists ~f:isReactClientComponentBinding value_bindings
      | _ -> false)
    structure

let raise_usage_of_client_components module_expr =
  match module_expr.pmod_desc with
  | Pmod_structure structure when contains_client_component structure ->
      let loc = module_expr.pmod_loc in
      Ast_builder.Default.pmod_structure ~loc
        [
          pstr_eval ~loc
            [%expr
              [%error
                "can't use [@react.client.component] inside a module, only on the toplevel. Please move the make \
                 function outside of the module."]]
            [];
        ]
  | _ -> module_expr

let rewrite_jsx =
  object (_)
    inherit [Expansion_context.Base.t] Ppxlib.Ast_traverse.map_with_context as super

    method! structure_item ctx structure_item =
      match mode.contents with
      | Native -> rewrite_structure_item (super#structure_item ctx structure_item)
      | Js -> rewrite_structure_item_for_js ctx (super#structure_item ctx structure_item)

    method! signature_item ctx signature_item =
      match mode.contents with
      | Native -> rewrite_signature_item (super#signature_item ctx signature_item)
      | Js -> super#signature_item ctx signature_item

    method! module_expr ctx module_expr =
      match mode.contents with
      | Js -> super#module_expr ctx (raise_usage_of_client_components module_expr)
      | Native -> super#module_expr ctx module_expr

    method! expression ctx expr =
      let expr = super#expression ctx expr in
      match mode.contents with
      | Js -> expr
      | Native -> (
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
          with Error err -> [%expr [%e err]])
  end

let () =
  Driver.add_arg "-melange" (Unit (fun () -> mode := Js)) ~doc:"preprocess for js build";
  Ppxlib.Driver.V2.register_transformation "server-reason-react.ppx" ~preprocess_impl:rewrite_jsx#structure
    ~preprocess_intf:rewrite_jsx#signature
