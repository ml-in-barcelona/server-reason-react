open Ppxlib
open Ast_builder.Default
module List = ListLabels

type target = Native | Js

(* Since ppxlib doesn't provide a way to get the submodules, we need to keep track of them manually *)
let mode = ref Native
let shared_folder_prefix = ref None
let repo_url = "https://github.com/ml-in-barcelona/server-reason-react"
let issues_url = Printf.sprintf "%s/issues" repo_url

let match_substring string substring =
  try
    Str.search_forward (Str.regexp_string substring) string 0 |> ignore;
    true
  with Not_found -> false

(* There's no Ppxlib.pexp_list since isn't a parsetree constructor *)
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
let react_dot_server_dot_function = "react.server.function"

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
let isReactServerFunctionBinding vb = hasAttrOnBinding vb react_dot_server_dot_function

let isClientComponentBinding value_bindings =
  let first_binding = List.hd value_bindings in
  isReactClientComponentBinding first_binding

let contains_client_component structure =
  List.exists
    ~f:(fun structure_item ->
      match structure_item.pstr_desc with
      | Pstr_value (_, value_bindings) -> List.exists ~f:isReactClientComponentBinding value_bindings
      | _ -> false)
    structure

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
        match ([%e attribute_value] : [ `String of string | `Function of 'a Runtime.server_function ]) with
        | `String s -> Some (React.JSX.String ([%e estring ~loc name], [%e estring ~loc jsxName], (s : string)))
        | `Function f ->
            Some
              (React.JSX.Action ([%e estring ~loc name], [%e estring ~loc jsxName], (f : 'a Runtime.server_function)))]
  | Attribute { type_ = DomProps.Action; name; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : [ `String of string | `Function of 'a Runtime.server_function ] option) with
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
             ([%e estring ~loc name], [%e estring ~loc jsxName], Stdlib.Int.to_string ([%e attribute_value] : int)))]
  | Attribute { type_ = DomProps.Int; name; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : int option) with
        | None -> None
        | Some v -> Some (React.JSX.String ([%e estring ~loc name], [%e estring ~loc jsxName], Stdlib.Int.to_string v))]
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
             ([%e estring ~loc name], [%e estring ~loc jsxName], Stdlib.Bool.to_string ([%e attribute_value] : bool)))]
  | Attribute { type_ = DomProps.BooleanishString; name; jsxName }, true ->
      [%expr
        match ([%e attribute_value] : bool option) with
        | None -> None
        | Some v -> Some (React.JSX.String ([%e estring ~loc name], [%e estring ~loc jsxName], Stdlib.Bool.to_string v))]
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
          [%expr Stdlib.List.filter_map Stdlib.Fun.id [%e list_of_attributes]])

let generate_create_element ~loc ~tag_name ~key ~props ~children =
  let dom_node_name = estring ~loc tag_name in
  match (key, children) with
  | Some key, Some children ->
      let childrens = pexp_list ~loc children in
      [%expr React.createElementWithKey ~key:[%e key] [%e dom_node_name] [%e props] [%e childrens]]
  | None, Some children ->
      let childrens = pexp_list ~loc children in
      [%expr React.createElement [%e dom_node_name] [%e props] [%e childrens]]
  | Some key, None -> [%expr React.createElementWithKey ~key:[%e key] [%e dom_node_name] [%e props] []]
  | None, None -> [%expr React.createElement [%e dom_node_name] [%e props] []]

let rewrite_lowercase ~loc tag_name args children =
  let key =
    args |> List.find_opt ~f:(fun (label, _) -> get_label label = "key") |> Option.map (fun (_, value) -> value)
  in
  let props = transform_lowercase_props ~loc ~tag_name args in
  match Static_analysis.analyze_element ~tag_name ~attrs:args ~children with
  | Static_analysis.Fully_static html ->
      let html_with_doctype = Static_analysis.maybe_add_doctype tag_name html in
      let html_expr = estring ~loc html_with_doctype in
      let original = generate_create_element ~loc ~tag_name ~key ~props ~children in
      [%expr React.Static { prerendered = [%e html_expr]; original = [%e original] }]
  | Static_analysis.Needs_string_concat _ | Static_analysis.Needs_buffer _ | Static_analysis.Cannot_optimize ->
      generate_create_element ~loc ~tag_name ~key ~props ~children

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
  let has_final_unit params =
    match List.rev params with
    | {
        pparam_desc = Pparam_val (Nolabel, _, { ppat_desc = Ppat_construct ({ txt = Lident "()" }, _) | Ppat_any; _ });
        _;
      }
      :: _ ->
        true
    | _ -> false
  in
  let unit_param = { pparam_loc = loc; pparam_desc = Pparam_val (Nolabel, None, [%pat? ()]) } in
  let rec find_innermost_function_and_add_unit expression =
    match expression.pexp_desc with
    | Pexp_function (params, constraint_, Pfunction_body inner_body) -> (
        match inner_body.pexp_desc with
        | Pexp_function _ ->
            let modified_inner = find_innermost_function_and_add_unit inner_body in
            { expression with pexp_desc = Pexp_function (params, constraint_, Pfunction_body modified_inner) }
        | _ when (not (has_final_unit params)) && params <> [] ->
            {
              expression with
              pexp_attributes = remove_warning_16_optional_argument_cannot_be_erased ~loc :: expression.pexp_attributes;
              pexp_desc = Pexp_function (params @ [ unit_param ], constraint_, Pfunction_body inner_body);
            }
        | _ -> expression)
    | Pexp_function _ -> expression
    | _ -> expression
  in
  let rec inner expression =
    match expression.pexp_desc with
    | Pexp_function _ -> find_innermost_function_and_add_unit expression
    (* let make = {let foo = bar in (~prop) => ...} *)
    | Pexp_let (recursive, vbs, internalExpression) ->
        pexp_let ~loc:expression.pexp_loc recursive vbs (inner internalExpression)
    (* let make = React.forwardRef((~prop) => ...) *)
    | Pexp_apply (_, [ (Nolabel, internalExpression) ]) -> inner internalExpression
    (* let make = React.memoCustomCompareProps((~prop) => ..., (prevPros, nextProps) => true) *)
    | Pexp_apply (_, [ (Nolabel, internalExpression); ((Nolabel, { pexp_desc = Pexp_function _; _ }) as _compareProps) ])
      ->
        inner internalExpression
    | Pexp_sequence (wrapperExpression, internalExpression) ->
        pexp_sequence ~loc:expression.pexp_loc wrapperExpression (inner internalExpression)
    | _ -> expression
  in
  inner expression

let transform_fun_body_expression expr fn =
  let rec find_innermost_body_and_transform expr =
    match expr.pexp_desc with
    | Pexp_function (params, constraint_, Pfunction_body inner_body) -> (
        match inner_body.pexp_desc with
        | Pexp_function _ ->
            let transformed_inner = find_innermost_body_and_transform inner_body in
            { expr with pexp_desc = Pexp_function (params, constraint_, Pfunction_body transformed_inner) }
        | _ ->
            let transformed_body = fn inner_body in
            { expr with pexp_desc = Pexp_function (params, constraint_, Pfunction_body transformed_body) })
    | _ -> fn expr
  in
  find_innermost_body_and_transform expr

let transform_fun_arguments expr fn =
  match expr.pexp_desc with
  | Pexp_function (params, constraint_, Pfunction_body expression) ->
      let new_params =
        List.map
          ~f:(fun param ->
            match param.pparam_desc with
            | Pparam_val (label, def, patt) -> { param with pparam_desc = Pparam_val (label, def, fn patt) }
            | Pparam_newtype _ -> param)
          params
      in
      { expr with pexp_desc = Pexp_function (new_params, constraint_, Pfunction_body expression) }
  | _ -> expr

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
  let default_value =
    (* default_value = None means there's no default *)
    None
  in
  let underscore = ppat_var ~loc:ghost_loc { txt = "_"; loc } in
  let core_type = [%type: string option] in
  let key_pattern = ppat_constraint ~loc underscore core_type in
  (* Append key argument since we want to allow users of this component to set key (and assign it to _ since it shouldn't be used) *)
  let function_body = pexp_fun ~loc:ghost_loc key_arg default_value key_pattern binding_expr in
  (* Since expand_make_binding is called on both native and js contexts, we need to keep the attributes *)
  { (value_binding ~loc:ghost_loc ~pat:name ~expr:function_body) with pvb_attributes = attributers }

let get_arguments pvb_expr =
  let rec go acc = function
    | Pexp_function (params, _, Pfunction_body expr) ->
        let args =
          List.filter_map
            ~f:(function
              | { pparam_desc = Pparam_val (label, default, patt); _ } -> Some (label, default, patt) | _ -> None)
            params
        in
        go (args @ acc) expr.pexp_desc
    | _ -> acc
  in
  go [] pvb_expr.pexp_desc

let make_of_json ~loc (core_type : core_type) prop =
  match core_type with
  (* QUESTION: How do we handle especial types on props,
     like `("someProp"), `List([React.element, string]).
     We already support it, but not with the ppx.
     Checkout the test_RSC_model.ml for more details. packages/reactDom/test/test_RSC_html.ml *)
  (* QUESTION: How can we handle optionals and others? Need a [@deriving rsc] for them? We currently encode None's as React.Model.Json `Null, should be enought *)
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
  | [%type: [%t? t] Runtime.server_function] -> [%expr ([%e prop] : [%t t] Runtime.server_function)]
  | [%type: [%t? t] Runtime.server_function option] -> [%expr ([%e prop] : [%t t] Runtime.server_function option)]
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
  let arguments = get_arguments binding.pvb_expr in
  let props_as_object_with_decoders = mel_obj ~loc (props_of_model ~loc arguments) in
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
            Ptyp_arrow (Optional "key", [%type: string], new_core_type)
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
            [%%ocaml.error "server-reason-react: there's seems to be an error in the signature of the component."]])
  | _ -> signature_item

let make_to_json ~loc (core_type : core_type) prop =
  match core_type with
  | [%type: React.element] -> [%expr React.Model.Element ([%e prop] : React.element)]
  | [%type: React.element option] ->
      [%expr
        match [%e prop] with Some prop -> React.Model.Element (prop : React.element) | None -> React.Model.Json `Null]
  | [%type: [%t? inner_type] Js.Promise.t] ->
      let json = [%expr [%to_json: [%t inner_type]]] in
      [%expr React.Model.Promise ([%e prop], fun value -> React.Model.Json ([%e json] value))]
  | [%type: [%t? inner_type] Js.Promise.t option] ->
      let json = [%expr [%to_json: [%t inner_type]]] in
      [%expr
        match [%e prop] with
        | Some prop -> React.Model.Promise (prop, fun value -> React.Model.Json ([%e json] value))
        | None -> React.Model.Json `Null]
  | { ptyp_desc = Ptyp_arrow (_, _, _) } ->
      let loc = core_type.ptyp_loc in
      [%expr
        [%ocaml.error
          "server-reason-react: you can't pass functions into client components. Functions aren't serialisable to JSON."]]
  | [%type: [%t? _] Runtime.server_function] -> [%expr React.Model.Function [%e prop]]
  | [%type: [%t? _] Runtime.server_function option] ->
      [%expr match [%e prop] with Some prop -> React.Model.Function prop | None -> React.Model.Json `Null]
  | [%type: [%t? inner_type] option] ->
      let json = [%expr [%to_json: [%t inner_type]]] in
      [%expr match [%e prop] with Some value -> React.Model.Json ([%e json] value) | None -> React.Model.Json `Null]
  | type_ ->
      let json = [%expr [%to_json: [%t type_]] [%e prop]] in
      [%expr React.Model.Json [%e json]]

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

module ServerFunction = struct
  let rec last_expr_to_fn ~loc expr fn =
    match expr.pexp_desc with
    | Pexp_constraint (expr, _) -> last_expr_to_fn ~loc expr fn
    | Pexp_function (params, constraint_, Pfunction_body expression) when params <> [] -> (
        match expression.pexp_desc with
        | Pexp_function _ ->
            let transformed_inner = last_expr_to_fn ~loc expression fn in
            { expr with pexp_desc = Pexp_function (params, constraint_, Pfunction_body transformed_inner) }
        | _ -> { expr with pexp_desc = Pexp_function (params, constraint_, Pfunction_body fn) })
    | _ -> fn

  let generate_id ~loc name =
    let file_path = loc.loc_start.pos_fname in
    let replacement =
      match shared_folder_prefix.contents with
      | Some x ->
          if match_substring file_path x then x
          else raise_errorf ~loc "Prefix doesn't match the file path. Provide a prefix that matches the file path."
      | None -> raise_errorf ~loc "Found a server.function without --shared-folder-prefix argument. Provide one."
    in
    (* We need to add a nasty hack here, since have different files for native and melange.Assume that the file structure is native/lib and js, and replace the name directly. This is supposed to be temporal, until dune implements https://github.com/ocaml/dune/issues/10630 *)
    let file_path = Str.replace_first (Str.regexp replacement) "" file_path in
    let hash = Printf.sprintf "%s_%s_%d" name file_path loc.loc_start.pos_lnum |> Hashtbl.hash |> string_of_int in
    hash

  let get_arg_details (arg : arg_label * expression option * pattern) =
    let arg_label, default, pattern = arg in
    let loc = pattern.ppat_loc in
    match pattern.ppat_desc with
    | Ppat_construct ({ txt = Lident "()"; loc }, None) -> Ok (Nolabel, None, [%type: unit])
    | Ppat_constraint (pattern, core_type) -> (
        let loc = pattern.ppat_loc in
        let core_type = match default with Some _ -> [%type: [%t core_type] option] | None -> core_type in
        match pattern.ppat_desc with
        | Ppat_var { txt = label; _ } -> Ok (arg_label, Some label, core_type)
        | _ -> Error (loc, "server-reason-react: server function arguments must have a name"))
    | _ -> Error (loc, "server-reason-react: server function arguments must have type annotations")

  let get_response_type expr =
    let rec aux expr acc =
      match expr.pexp_desc with
      | Pexp_function (_, Some (Pconstraint core_type), Pfunction_body body) -> aux body (Some core_type)
      | Pexp_function (_, _, Pfunction_body body) -> aux body acc
      | Pexp_constraint (expr, core_type) -> aux expr (Some core_type)
      | _ -> acc
    in
    aux expr None

  let response_to_json ~loc core_type response =
    match core_type with
    | Some [%type: [%t? core_type] Js.Promise.t] ->
        let json = [%expr [%to_json: [%t core_type]] [%e response]] in
        [%expr React.Model.Json [%e json]]
    | Some _ -> [%expr [%ocaml.error "server-reason-react: server functions must return a promise"]]
    | _ ->
        [%expr [%ocaml.error "server-reason-react: server functions must have a return type annotation (Js.Promise.t)"]]

  let map_arguments_to_expressions ~loc args =
    List.map
      ~f:(fun arg ->
        match arg with
        | Ok (arg_label, Some arg_name, _) -> (arg_label, [%expr [%e evar ~loc arg_name]])
        | Ok (arg_label, _, [%type: unit]) -> (arg_label, [%expr ()])
        | Ok _ ->
            ( Nolabel,
              [%expr
                [%ocaml.error
                  "server-reason-react: invalid argument, it must have a argument with name and type annotation"]] )
        | Error (loc, msg) -> (Nolabel, [%expr [%ocaml.error [%e estring ~loc msg]]]))
      args

  let encode_function_response ~loc ~response_expr ~core_type =
    [%expr
      try [%e response_expr] |> Lwt.map (fun response -> [%e response_to_json ~loc core_type [%expr response]])
      with e -> Lwt.fail e]

  let decode_arguments_vb ~loc args_to_decode =
    args_to_decode
    |> List.mapi ~f:(fun i (_, label, core_type) ->
        let string_of_core_type x =
          let f = Format.str_formatter in
          Astlib.Pprintast.core_type f x;
          Format.flush_str_formatter ()
        in
        let core_type_string = string_of_core_type core_type in
        let of_json = make_of_json ~loc core_type [%expr Stdlib.Array.unsafe_get args [%e eint ~loc i]] in
        value_binding ~loc
          ~pat:[%pat? [%p ppat_var ~loc { txt = label; loc }]]
          ~expr:
            [%expr
              try [%e of_json]
              with _ ->
                Stdlib.raise
                  (Invalid_argument
                     (Stdlib.Printf.sprintf
                        "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s"
                        [%e estring ~loc label] [%e estring ~loc core_type_string]
                        (Stdlib.Array.unsafe_get args [%e eint ~loc i] |> Yojson.Basic.to_string)))])

  let create_function_reference_registration ~loc ~id ~function_name ~args ~core_type =
    let apply_args = map_arguments_to_expressions ~loc args in
    let response_expr = pexp_apply ~loc [%expr [%e evar ~loc function_name].call] apply_args in

    let encoded_response_expr = encode_function_response ~loc ~response_expr ~core_type in
    let args_to_decode =
      List.filter_map
        ~f:(fun arg ->
          match arg with
          | Ok (_, _, [%type: Js.FormData.t]) -> None
          | Ok (arg_label, Some arg_name, core_type) -> Some (arg_label, arg_name, core_type)
          | Ok _ -> None
          | Error _ -> None)
        args
    in

    let args, formData =
      List.partition_map
        ~f:(fun arg ->
          match arg with Ok (_, _, [%type: Js.FormData.t]) -> Right arg | Ok _ -> Left arg | Error _ -> Left arg)
        args
    in

    let body_expr =
      match args_to_decode with
      | [] -> encoded_response_expr
      | args_to_decode ->
          let decoded_expr = decode_arguments_vb ~loc args_to_decode in
          pexp_let ~loc Nonrecursive decoded_expr encoded_response_expr
    in
    match (formData, args) with
    | [], _ -> [%stri FunctionReferences.register [%e estring ~loc id] (Body (fun args -> [%e body_expr]))]
    | [ _ ], [] ->
        [%stri FunctionReferences.register [%e estring ~loc id] (FormData (fun _ formData -> [%e body_expr]))]
    | _, [] ->
        [%stri [%ocaml.error "server-reason-react: server functions with form data must have at only one argument"]]
    | _ -> [%stri FunctionReferences.register [%e estring ~loc id] (FormData (fun args formData -> [%e body_expr]))]

  let create_server_function_record ~loc id expression =
    [%expr { Runtime.id = [%e estring ~loc id]; call = [%e expression] }]

  let rewrite_native_function ~vb ~rec_flag structure_item =
    let loc = structure_item.pstr_loc in
    let function_name = get_function_name vb in
    let args = get_arguments vb.pvb_expr |> List.map ~f:get_arg_details |> List.rev in
    let base_fn = vb.pvb_expr in
    let return_core_type = get_response_type base_fn in
    let id = generate_id ~loc:vb.pvb_loc function_name in
    let server_function_record_vb =
      value_binding ~loc:vb.pvb_loc ~pat:vb.pvb_pat ~expr:(create_server_function_record ~loc:vb.pvb_loc id base_fn)
    in
    let stri =
      [%stri
        include struct
          [%%i pstr_value ~loc rec_flag [ server_function_record_vb ]]
          [%%i create_function_reference_registration ~loc ~id ~function_name ~args ~core_type:return_core_type]
        end]
    in
    stri

  let response_of_json ~loc core_type response =
    match core_type with
    | Some [%type: [%t? core_type] Js.Promise.t] -> [%expr [%of_json: [%t core_type]] [%e response]]
    | Some _ -> [%expr [%ocaml.error "server-reason-react: server functions must return a promise"]]
    | _ ->
        [%expr [%ocaml.error "server-reason-react: server functions must have a return type annotation (Js.Promise.t)"]]

  let create_client_function ~loc ~return_core_type id args =
    let decode_response = response_of_json ~loc return_core_type in
    let apply_args = map_arguments_to_expressions ~loc args |> List.map ~f:(fun (_, expr) -> (Nolabel, expr)) in
    let fn =
      [%expr
        let action = ReactServerDOMEsbuild.createServerReference [%e estring ~loc id] in
        ([%e pexp_apply ~loc [%expr action] apply_args] [@u])
        |> Js.Promise.then_ (fun response -> Js.Promise.resolve [%e decode_response [%expr response]])]
    in
    fn

  let rewrite_client_function ~nested_module_names ~vb ~rec_flag structure_item =
    let loc = structure_item.pstr_loc in

    let function_name = get_function_name vb in
    let args = get_arguments vb.pvb_expr |> List.map ~f:get_arg_details |> List.rev in
    let base_fn = vb.pvb_expr in
    let return_core_type = get_response_type base_fn in
    let id = generate_id ~loc:vb.pvb_loc function_name in
    let server_function_record_vb =
      value_binding ~loc:vb.pvb_loc ~pat:vb.pvb_pat
        ~expr:
          (create_server_function_record ~loc:vb.pvb_loc id
             (last_expr_to_fn ~loc base_fn (create_client_function ~loc ~return_core_type id args)))
    in

    let loc = structure_item.pstr_loc in
    let module_name = String.concat "." nested_module_names in
    let _, formData =
      List.partition_map
        ~f:(fun arg ->
          match arg with Ok (_, _, [%type: Js.FormData.t]) -> Right arg | Ok _ -> Left arg | Error _ -> Left arg)
        args
    in
    let functionToCall = match formData with [] -> function_name | _ -> Printf.sprintf "%s.call" function_name in
    let comment = Printf.sprintf "// extract-server-function %s %s %s" id functionToCall module_name in
    let raw = estring ~loc comment in
    let extract_client_raw = [%stri [%%raw [%e raw]]] in
    [%stri
      include struct
        [%%i extract_client_raw]
        [%%i pstr_value ~loc:structure_item.pstr_loc rec_flag [ server_function_record_vb ]]
      end]
end

let rewrite_structure_item ~nested_module_names structure_item =
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
  | Pstr_value (rec_flag, value_bindings) when isReactServerFunctionBinding (List.hd value_bindings) ->
      let vb = List.hd value_bindings in
      let loc = structure_item.pstr_loc in
      if List.length value_bindings > 1 then
        [%stri
          [%%ocaml.error
          "server-reason-react: server functions don't support recursive bindings yet. If you need it, please open an \
           issue on https://github.com/reasonml-community/server-reason-react/issues"]]
      else ServerFunction.rewrite_native_function ~vb ~rec_flag structure_item
  | Pstr_value (rec_flag, value_bindings) ->
      let map_value_binding vb =
        if isReactClientComponentBinding vb then
          expand_make_binding vb (fun expr ->
              let loc = expr.pexp_loc in
              let fileName = expr.pexp_loc.loc_start.pos_fname in
              let replacement =
                match shared_folder_prefix.contents with
                | Some prefix ->
                    if match_substring fileName prefix then prefix
                    else
                      raise_errorf ~loc
                        "Prefix doesn't match the file path. Provide a prefix that matches the file path."
                | None ->
                    raise_errorf ~loc
                      "Found a react.client.component without --shared-folder-prefix argument. Provide one."
              in
              let file = fileName |> Str.replace_first (Str.regexp replacement) "" |> estring ~loc in
              let import_module =
                match nested_module_names with
                | [] -> file
                | _ ->
                    let submodule = estring ~loc (String.concat "." nested_module_names) in
                    [%expr Printf.sprintf "%s#%s" [%e file] [%e submodule]]
              in
              let arguments = get_arguments vb.pvb_expr in
              (* We transform the arguments from the value binding into React.client_props *)
              let props = props_to_model ~loc arguments in
              [%expr
                React.Client_component
                  {
                    import_module = [%e import_module];
                    import_name = "";
                    props = [%e props];
                    client = React.Upper_case_component (Stdlib.__FUNCTION__, fun () -> [%e expr]);
                  }])
        else if isReactComponentBinding vb then
          expand_make_binding vb (fun expr ->
              let loc = expr.pexp_loc in
              [%expr React.Upper_case_component (Stdlib.__FUNCTION__, fun () -> [%e expr])])
        else if isReactAsyncComponentBinding vb then
          expand_make_binding vb (fun expr ->
              let loc = expr.pexp_loc in
              [%expr React.Async_component (Stdlib.__FUNCTION__, fun () -> [%e expr])])
        else vb
      in
      let bindings = List.map ~f:map_value_binding value_bindings in
      pstr_value ~loc:structure_item.pstr_loc rec_flag bindings
  | _ -> structure_item

let rewrite_structure_item_for_js ~nested_module_names ctx structure_item =
  match structure_item.pstr_desc with
  (* external *)
  | Pstr_primitive ({ pval_name = { txt = _fnName }; pval_attributes; pval_type = _ } as _value_description) -> (
      match List.filter ~f:(fun attr -> hasAttr attr react_dot_client_dot_component) pval_attributes with
      | [] -> structure_item
      | _ ->
          let loc = structure_item.pstr_loc in
          [%stri [%%ocaml.error "server-reason-react: externals aren't supported on client components yet"]])
  | Pstr_value (rec_flag, value_bindings) when isReactServerFunctionBinding (List.hd value_bindings) ->
      let vb = List.hd value_bindings in
      ServerFunction.rewrite_client_function ~nested_module_names ~vb ~rec_flag structure_item
  (* let make = ... *)
  | Pstr_value (rec_flag, value_bindings) when isClientComponentBinding value_bindings ->
      let first_value_binding = List.hd value_bindings in
      let make_client = expand_make_binding_to_client first_value_binding in
      let make_client_binding = pstr_value ~loc:structure_item.pstr_loc rec_flag [ make_client ] in
      let original_value_binding =
        { first_value_binding with pvb_attributes = [ react_component_attribute ~loc:first_value_binding.pvb_loc ] }
      in
      let loc = structure_item.pstr_loc in
      let code_path = Expansion_context.Base.code_path ctx in
      let fileName = Code_path.file_path code_path in
      (* We need to add a nasty hack here, since have different files for native and melange.Assume that the file structure is /native/shared/ and js, and replace the name directly. This is supposed to be temporal, until dune implements https://github.com/ocaml/dune/issues/10630 *)
      let replacement =
        match shared_folder_prefix.contents with
        | Some prefix ->
            if match_substring fileName prefix then prefix
            else raise_errorf ~loc "Prefix doesn't match the file path. Provide a prefix that matches the file path."
        | None ->
            raise_errorf ~loc "Found a react.client.component without --shared-folder-prefix argument. Provide one."
      in
      let fileName = Str.replace_first (Str.regexp replacement) "" fileName in
      let comment =
        match nested_module_names with
        | [] -> estring ~loc (Printf.sprintf "// extract-client %s" fileName)
        | _ -> estring ~loc (Printf.sprintf "// extract-client %s %s" fileName (String.concat "." nested_module_names))
      in
      [%stri
        include struct
          [%%i [%stri [%%raw [%e comment]]]]
          [%%i pstr_value ~loc:structure_item.pstr_loc rec_flag [ original_value_binding ]]
          [%%i make_client_binding]
        end]
  | _ -> structure_item

let validate_tag_children tag children attributes : (unit, string) result =
  match Html.is_self_closing_tag tag with
  | true when Option.fold ~none:false ~some:(fun children -> List.length children > 0) children ->
      Error (Printf.sprintf {|"%s" is a self-closing tag and must not have "children".\n|} tag)
  | true
    when List.exists
           ~f:(fun (arg_label, _) ->
             match arg_label with
             | Labelled "dangerouslySetInnerHTML" | Optional "dangerouslySetInnerHTML" -> true
             | _ -> false)
           attributes ->
      Error (Printf.sprintf {|server-reason-react: "%s" is a self-closing tag and must not have "children".\n|} tag)
  | false -> Ok ()
  | true -> Ok ()

let traverse =
  object (_)
    inherit [Expansion_context.Base.t] Ast_traverse.map_with_context as super
    val mutable nested_module_names = []

    method! module_binding ctxt module_binding =
      (match module_binding.pmb_name.txt with
      | None -> ()
      | Some name -> nested_module_names <- nested_module_names @ [ name ]);
      let mapped = super#module_binding ctxt module_binding in
      let rec remove_last l = match l with [] -> [] | [ _ ] -> [] | hd :: tl -> hd :: remove_last tl in
      nested_module_names <- remove_last nested_module_names;
      mapped

    method! structure_item ctx structure_item =
      match mode.contents with
      | Native -> rewrite_structure_item ~nested_module_names (super#structure_item ctx structure_item)
      | Js -> rewrite_structure_item_for_js ~nested_module_names ctx (super#structure_item ctx structure_item)

    method! signature_item ctx signature_item =
      match mode.contents with
      | Native -> rewrite_signature_item (super#signature_item ctx signature_item)
      | Js -> super#signature_item ctx signature_item

    method! expression ctx expr =
      let expr = super#expression ctx expr in
      let attributes = expr.pexp_attributes in
      match mode.contents with
      | Js -> (
          (* In the case of expressions, it's the only transformation that needs to be done for JS. This expansion from "styles" prop into "className" and "style" props is a feature by styled-ppx. The existence of this here, is because dune/ppxlib doesn't allow more than one preprocess_impl and even that, the combination of styled-ppx and server-reason-react.ppx doesn't compose properly. *)
          try
            match expr.pexp_desc with
            | Pexp_apply (({ pexp_desc = Pexp_ident _; pexp_loc = loc; _ } as tag), args)
              when has_jsx_attr expr.pexp_attributes ->
                let new_args = Expand_styles_attribute.make ~loc args in
                { (pexp_apply ~loc (super#expression ctx tag) new_args) with pexp_attributes = attributes }
            | _ -> expr
          with Error err -> [%expr [%e err]])
      | Native -> (
          try
            match expr.pexp_desc with
            | Pexp_apply (({ pexp_desc = Pexp_ident _; pexp_loc = loc; _ } as tag), args)
              when has_jsx_attr expr.pexp_attributes -> (
                let children, rest_of_args = split_args args in
                match validate_tag_children (Pprintast.string_of_expression tag) children rest_of_args with
                | Error err -> [%expr [%ocaml.error [%e estring ~loc:expr.pexp_loc err]]]
                | Ok () -> (
                    match tag.pexp_desc with
                    (* div() [@JSX] *)
                    | Pexp_ident { txt = Lident name; loc = _name_loc } ->
                        (* This expansion from "styles" prop into "className" and "style" props is a feature by styled-ppx. The existence of this here, is because dune/ppxlib doesn't allow more than one preprocess_impl and even that, the combination of styled-ppx and server-reason-react.ppx doesn't compose properly. *)
                        let new_args = Expand_styles_attribute.make ~loc rest_of_args in
                        rewrite_lowercase ~loc:expr.pexp_loc name new_args children
                    (* Reason adds `createElement` as default when an uppercase is found,
                   we change it back to make *)
                    (* Foo.createElement() [@JSX] *)
                    | Pexp_ident { txt = Ldot (modulePath, ("createElement" | "make")); loc } ->
                        let id = { loc; txt = Ldot (modulePath, "make") } in
                        rewrite_component ~loc:expr.pexp_loc id rest_of_args children
                    (* local_function() [@JSX] *)
                    | Pexp_ident id -> rewrite_component ~loc:expr.pexp_loc id rest_of_args children
                    | _ -> assert false))
            (* div() [@JSX] *)
            | Pexp_apply (tag, _props) when has_jsx_attr expr.pexp_attributes ->
                raise_errorf ~loc:expr.pexp_loc "jsx: %s should be an identifier, not an expression"
                  (Pprintast.string_of_expression tag)
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

  Driver.add_arg "-shared-folder-prefix"
    (String
       (fun str ->
         let components = String.split_on_char '/' str |> List.filter ~f:(fun x -> x <> "") in
         let prefix = String.concat "/" components in
         let prefix = if prefix = "" then "" else prefix ^ "/" in
         shared_folder_prefix := Some prefix))
    ~doc:"prefix of shared folder, used to replace the it in the file path";

  Ppxlib.Driver.V2.register_transformation "server-reason-react.ppx" ~preprocess_impl:traverse#structure
    ~preprocess_intf:traverse#signature
