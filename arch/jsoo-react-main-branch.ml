(* last_ *)

open Ppxlib
open Ast_helper

let dev_mode = Sys.getenv_opt "JSOO_REACT_DEV" <> None

module Str_label = struct
  type t =
    | Labelled of string
    | Optional of string

  let of_arg_label : arg_label -> t = function
    | Labelled s -> Labelled s
    | Optional s -> Optional s
    | Nolabel -> failwith "invariant failed: Str_label called with Nolabel"

  let to_arg_label : t -> arg_label = function
    | Labelled s -> Labelled s
    | Optional s -> Optional s

  let str = function Labelled s -> s | Optional s -> s
end

let rec find_opt p = function
  | [] -> None
  | x :: l -> if p x then Some x else find_opt p l

let nolabel = Nolabel
let labelled str = Labelled str

let getLabel str =
  match str with Optional str | Labelled str -> str | Nolabel -> ""

let isOptional str =
  match str with Optional _ -> true | Labelled _ -> false | Nolabel -> false

let optionIdent = Lident "option"

let isUnit expr =
  match expr.pexp_desc with
  | Pexp_construct ({ txt = Lident "()"; _ }, _) -> true
  | _ -> false

let constantString ~loc str = Ast_helper.Exp.constant ~loc (Const.string str)

let safeTypeFromValue label =
  let str = Str_label.str label in
  match String.sub str 0 1 with "_" -> "T" ^ str | _ -> str

let keyType loc =
  Typ.constr ~loc { loc; txt = optionIdent }
    [ Typ.constr ~loc { loc; txt = Lident "string" } [] ]

let refType loc = [%type: React.Dom.dom_ref]

type componentConfig = { propsName : string }

let extractChildren ?(removeLastPositionUnit = false) ~loc propsAndChildren =
  let rec allButLast_ lst acc =
    match lst with
    | [] -> []
    | [ (Nolabel, { pexp_desc = Pexp_construct ({ txt = Lident "()" }, None) })
      ] ->
        acc
    | (Nolabel, { pexp_loc }) :: _rest ->
        Location.raise_errorf ~loc:pexp_loc
          "JSX: found non-labelled argument before the last position"
    | arg :: rest -> allButLast_ rest (arg :: acc)
  in
  let allButLast lst = allButLast_ lst [] |> List.rev in
  match
    List.partition
      (fun (label, _) -> label = labelled "children")
      propsAndChildren
  with
  | [], props ->
      (* no children provided? Place a placeholder list *)
      ( Exp.construct ~loc { loc; txt = Lident "[]" } None
      , if removeLastPositionUnit then allButLast props else props )
  | [ (_, childrenExpr) ], props ->
      (childrenExpr, if removeLastPositionUnit then allButLast props else props)
  | _first :: (_, { pexp_loc }) :: _rest, _props ->
      Location.raise_errorf ~loc:pexp_loc
        "JSX: somehow there's more than one `children` label"

let unerasableIgnore loc =
  { attr_name = { txt = "warning"; loc }
  ; attr_payload = PStr [ Str.eval (Exp.constant (Const.string "-16")) ]
  ; attr_loc = loc
  }

(* [merlin_hide] tells merlin to not look at a node, or at any of its
   descendants. *)
let merlin_hide =
  { attr_name = { txt = "merlin.hide"; loc = Location.none }
  ; attr_payload = PStr []
  ; attr_loc = Location.none
  }

(* Helper method to look up the [@react.component] attribute *)
let hasAttr { attr_name; _ } = attr_name.txt = "react.component"

(* Helper method to filter out any attribute that isn't [@react.component] *)
let otherAttrsPure { attr_name; _ } = attr_name.txt <> "react.component"

(* Iterate over the attributes and try to find the [@react.component] attribute *)
let has_attr_on_binding { pvb_attributes } =
  find_opt hasAttr pvb_attributes <> None

let used_attributes_tbl = Hashtbl.create 16

let register_loc attr =
  Ppxlib.Attribute.mark_as_handled_manually attr;
  Hashtbl.replace used_attributes_tbl attr.attr_name.loc ()

let filter_attr_name key attr =
  if attr.attr_name.txt = key then (
    register_loc attr;
    true)
  else false

(* Finds the name of the variable the binding is assigned to, otherwise raises Invalid_argument *)
let rec getFnName = function
  | { ppat_desc = Ppat_var { txt } } -> txt
  | { ppat_desc = Ppat_constraint (pat, _) } -> getFnName pat
  | { ppat_loc } ->
      Location.raise_errorf ~loc:ppat_loc
        "react.component calls cannot be destructured."

(* Lookup the value of `props` otherwise raise Invalid_argument error *)
let getPropsNameValue _acc (loc, exp) =
  match (loc, exp) with
  | { txt = Lident "props" }, { pexp_desc = Pexp_ident { txt = Lident str } } ->
      { propsName = str }
  | { txt; loc }, _ ->
      Location.raise_errorf ~loc
        "react.component only accepts props as an option, given: %s"
        (Longident.last_exn txt)

(* Lookup the `props` record or string as part of [@react.component] and store the name for use when rewriting *)
let get_props_attr payload =
  let default_props = { propsName = "Props" } in
  match payload with
  | Some
      (PStr
        ({ pstr_desc =
             Pstr_eval ({ pexp_desc = Pexp_record (recordFields, None) }, _)
         }
        :: _rest)) ->
      List.fold_left getPropsNameValue default_props recordFields
  | Some
      (PStr
        ({ pstr_desc =
             Pstr_eval ({ pexp_desc = Pexp_ident { txt = Lident "props" } }, _)
         }
        :: _rest)) ->
      { propsName = "props" }
  | Some (PStr ({ pstr_desc = Pstr_eval (_, _); pstr_loc } :: _rest)) ->
      Location.raise_errorf ~loc:pstr_loc
        "react.component accepts a record config with props as an options."
  | _ -> default_props

(* Plucks the label, loc, and type_ from an AST node *)
let pluckLabelDefaultLocType (label, default, _, _, loc, type_) =
  (label, default, loc, type_)

(*
  AST node builders
  These functions help us build AST nodes that are needed when transforming a [@react.component] into a
  constructor and a `makeProps` function
*)

(* Build an AST node representing all named args for the `makeProps` definition for a component's props *)
let rec makeArgsForMakePropsType list args =
  let open Str_label in
  match list with
  | (label, default, loc, interiorType) :: tl ->
      let coreType =
        match (label, interiorType, default) with
        (* ~foo=1 *)
        | label, None, Some _ ->
            Typ.mk ~loc (Ptyp_var (safeTypeFromValue label))
        (* ~foo: int=1 *)
        | _label, Some type_, Some _ -> type_
        (* ~foo: option(int)=? *)
        | ( (Optional _ as _label)
          , Some
              { ptyp_desc = Ptyp_constr ({ txt = Lident "option"; _ }, [ type_ ])
              ; _
              }
          , _ )
        (* ~foo: int=? - note this isnt valid. but we want to get a type error *)
        | (Optional _ as _label), Some type_, _ ->
            type_
        (* ~foo=? *)
        | (Optional _ as label), None, _ ->
            Typ.mk ~loc (Ptyp_var (safeTypeFromValue label))
        (* ~foo *)
        | label, None, _ -> Typ.mk ~loc (Ptyp_var (safeTypeFromValue label))
        | _label, Some type_, _ -> type_
      in
      makeArgsForMakePropsType tl
        (Typ.arrow ~loc (to_arg_label label) coreType args)
  | [] -> args

let make_props_name fnName = fnName ^ "_props"

(* Build an AST node for the props name when converted to a Js.t inside the function signature  *)
let makePropsName ~loc name = Pat.mk ~loc (Ppat_var { txt = name; loc })

let makeObjectField loc (label, _attrs, propType) =
  let type_ = [%type: [%t propType] Js_of_ocaml.Js.readonly_prop] in
  { pof_desc =
      Otag
        ({ loc; txt = Str_label.str label }, { type_ with ptyp_attributes = [] })
  ; pof_loc = loc
  ; pof_attributes = []
  }

(* Build an AST node representing a "closed" Js_of_ocaml.Js.t object representing a component's props *)
let makePropsType ~loc namedTypeList =
  Typ.mk ~loc
    (Ptyp_constr
       ( { txt = Ldot (Ldot (Lident "Js_of_ocaml", "Js"), "t"); loc }
       , [ Typ.mk ~loc
             (Ptyp_object (List.map (makeObjectField loc) namedTypeList, Closed))
         ] ))

let rec make_funs_for_make_props_body list args =
  match list with
  | (label, _default, loc, _interiorType) :: tl ->
      make_funs_for_make_props_body tl
        (Exp.fun_ ~loc
           (Str_label.to_arg_label label)
           None
           { ppat_desc = Ppat_var { txt = Str_label.str label; loc }
           ; ppat_loc = loc
           ; ppat_attributes = []
           ; ppat_loc_stack = []
           }
           args)
  | [] -> args

let makeAttributeValue ~loc ~isOptional (type_ : Html.attributeType) value =
  match (type_, isOptional) with
  | String, true ->
      [%expr Option.map Js_of_ocaml.Js.string ([%e value] : string option)]
  | String, false -> [%expr Js_of_ocaml.Js.string ([%e value] : string)]
  | Int, false -> [%expr ([%e value] : int)]
  | Int, true -> [%expr ([%e value] : int option)]
  | Float, false -> [%expr ([%e value] : float)]
  | Float, true -> [%expr ([%e value] : float option)]
  | Bool, false -> [%expr ([%e value] : bool)]
  | Bool, true -> [%expr ([%e value] : bool option)]
  | Style, false -> [%expr ([%e value] : React.Dom.Style.t)]
  | Style, true -> [%expr ([%e value] : React.Dom.Style.t option)]
  | Ref, false -> [%expr ([%e value] : React.Dom.dom_ref)]
  | Ref, true -> [%expr ([%e value] : React.Dom.dom_ref option)]
  | InnerHtml, false ->
      [%expr ([%e value] : React.Dom.DangerouslySetInnerHTML.t)]
  | InnerHtml, true ->
      [%expr ([%e value] : React.Dom.DangerouslySetInnerHTML.t option)]

let makeEventValue ~loc ~isOptional (type_ : Html.eventType) value =
  match (type_, isOptional) with
  | Clipboard, false -> [%expr ([%e value] : React.Event.Clipboard.t -> unit)]
  | Clipboard, true ->
      [%expr ([%e value] : (React.Event.Clipboard.t -> unit) option)]
  | Composition, false ->
      [%expr ([%e value] : React.Event.Composition.t -> unit)]
  | Composition, true ->
      [%expr ([%e value] : (React.Event.Composition.t -> unit) option)]
  | Keyboard, false -> [%expr ([%e value] : React.Event.Keyboard.t -> unit)]
  | Keyboard, true ->
      [%expr ([%e value] : (React.Event.Keyboard.t -> unit) option)]
  | Focus, false -> [%expr ([%e value] : React.Event.Focus.t -> unit)]
  | Focus, true -> [%expr ([%e value] : (React.Event.Focus.t -> unit) option)]
  | Form, false -> [%expr ([%e value] : React.Event.Form.t -> unit)]
  | Form, true -> [%expr ([%e value] : (React.Event.Form.t -> unit) option)]
  | Mouse, false -> [%expr ([%e value] : React.Event.Mouse.t -> unit)]
  | Mouse, true -> [%expr ([%e value] : (React.Event.Mouse.t -> unit) option)]
  | Selection, false -> [%expr ([%e value] : React.Event.Selection.t -> unit)]
  | Selection, true ->
      [%expr ([%e value] : (React.Event.Selection.t -> unit) option)]
  | Touch, false -> [%expr ([%e value] : React.Event.Touch.t -> unit)]
  | Touch, true -> [%expr ([%e value] : (React.Event.Touch.t -> unit) option)]
  | UI, false -> [%expr ([%e value] : React.Event.UI.t -> unit)]
  | UI, true -> [%expr ([%e value] : (React.Event.UI.t -> unit) option)]
  | Wheel, false -> [%expr ([%e value] : React.Event.Wheel.t -> unit)]
  | Wheel, true -> [%expr ([%e value] : (React.Event.Wheel.t -> unit) option)]
  | Media, false -> [%expr ([%e value] : React.Event.Media.t -> unit)]
  | Media, true -> [%expr ([%e value] : (React.Event.Media.t -> unit) option)]
  | Image, false -> [%expr ([%e value] : React.Event.Image.t -> unit)]
  | Image, true -> [%expr ([%e value] : (React.Event.Image.t -> unit) option)]
  | Animation, false -> [%expr ([%e value] : React.Event.Animation.t -> unit)]
  | Animation, true ->
      [%expr ([%e value] : (React.Event.Animation.t -> unit) option)]
  | Transition, false -> [%expr ([%e value] : React.Event.Transition.t -> unit)]
  | Transition, true ->
      [%expr ([%e value] : (React.Event.Transition.t -> unit) option)]
  | Pointer, false -> [%expr ([%e value] : React.Event.Syntetic.t -> unit)]
  | Pointer, true ->
      [%expr ([%e value] : (React.Event.Syntetic.t -> unit) option)]
  | Drag, false -> [%expr ([%e value] : React.Event.Syntetic.t -> unit)]
  | Drag, true -> [%expr ([%e value] : (React.Event.Syntetic.t -> unit) option)]

let makeValue ~loc ~isOptional prop value =
  match prop with
  | Html.Attribute attribute ->
      makeAttributeValue ~loc ~isOptional attribute.type_ value
  | Html.Event event -> makeEventValue ~loc ~isOptional event.type_ value

let make_js_props_obj ~loc named_arg_list_with_key_and_ref =
  let label_to_tuple label =
    let label_str = Str_label.str label in
    let id = Exp.ident ~loc { txt = Lident label_str; loc } in
    match label_str with
    | "key" ->
        [%expr
          [%e Exp.constant ~loc (Const.string label_str)]
          , inject
              (Js_of_ocaml.Js.Optdef.option
                 (Option.map Js_of_ocaml.Js.string [%e id]))]
    | "ref" ->
        [%expr
          [%e Exp.constant ~loc (Const.string label_str)]
          , inject (Js_of_ocaml.Js.Optdef.option [%e id])]
    | _ ->
        [%expr [%e Exp.constant ~loc (Const.string label_str)], inject [%e id]]
  in
  [%expr
    obj
      [%e
        Exp.array ~loc
          (List.map
             (fun (label, _, _, _) -> label_to_tuple label)
             named_arg_list_with_key_and_ref)]]

let rec get_wrap_fn_for_type ~loc typ =
  match typ with
  | Some [%type: React.element list] ->
      Some [%expr fun v -> Js_of_ocaml.Js.array (Array.of_list v)]
  | Some [%type: string] -> Some [%expr Js_of_ocaml.Js.string]
  | Some [%type: bool] -> Some [%expr Js_of_ocaml.Js.bool]
  | Some [%type: [%t? inner_typ] array] ->
      Some
        (match get_wrap_fn_for_type ~loc (Some inner_typ) with
        | Some inner_wrapf ->
            [%expr fun v -> Js_of_ocaml.Js.array (Array.map [%e inner_wrapf] v)]
        | None -> [%expr Js_of_ocaml.Js.array])
  | _ -> None

let make_external_js_props_obj ~loc named_arg_list =
  let label_to_tuple label typ =
    let label_ident =
      Exp.ident ~loc { txt = Lident (Str_label.str label); loc }
    in
    let maybe_wrap_fn = get_wrap_fn_for_type ~loc typ in
    match (label, maybe_wrap_fn) with
    | Labelled l, Some wrapf ->
        [%expr
          [%e Exp.constant ~loc (Const.string l)]
          , inject ([%e wrapf] [%e label_ident])]
    | Labelled l, None ->
        [%expr [%e Exp.constant ~loc (Const.string l)], inject [%e label_ident]]
    | Optional l, Some wrapf ->
        [%expr
          [%e Exp.constant ~loc (Const.string l)]
          , inject
              (Js_of_ocaml.Js.Optdef.option
                 (Option.map [%e wrapf] [%e label_ident]))]
    | Optional l, None ->
        [%expr
          [%e Exp.constant ~loc (Const.string l)]
          , inject (Js_of_ocaml.Js.Optdef.option [%e label_ident])]
  in
  [%expr
    obj
      [%e
        Exp.array ~loc
          (List.map
             (fun (label, _, _, typ) -> label_to_tuple label typ)
             named_arg_list)]]

(* Builds the function that takes labelled arguments and generates a JS object *)
let make_make_props js_props_obj fn_name loc named_arg_list props_type rest =
  let props_type = makePropsType ~loc props_type in
  let core_type =
    makeArgsForMakePropsType named_arg_list [%type: unit -> [%t props_type]]
  in
  Exp.mk ~loc
    (Pexp_let
       ( Nonrecursive
       , [ Vb.mk ~loc ~attrs:[ merlin_hide ]
             (Pat.mk ~loc
                (Ppat_constraint
                   ( makePropsName ~loc (make_props_name fn_name)
                   , { ptyp_desc = Ptyp_poly ([], core_type)
                     ; ptyp_loc = loc
                     ; ptyp_attributes = []
                     ; ptyp_loc_stack = []
                     } )))
             (Exp.mk ~loc
                (Pexp_constraint
                   ( make_funs_for_make_props_body named_arg_list
                       [%expr
                         fun () ->
                           let open Js_of_ocaml.Js.Unsafe in
                           [%e js_props_obj]]
                   , core_type )))
         ]
       , rest ))

let rec recursivelyTransformNamedArgsForMake mapper expr list =
  let expr = mapper#expression expr in
  let loc = expr.pexp_loc in
  match expr.pexp_desc with
  | Pexp_fun (Labelled "key", _, _, _) | Pexp_fun (Optional "key", _, _, _) ->
      Location.raise_errorf ~loc
        "native-react: key cannot be accessed inside of a component. Don't \
         worry - you can always key a component from its parent!"
  | Pexp_fun (Labelled "ref", _, _, _) | Pexp_fun (Optional "ref", _, _, _) ->
      Location.raise_errorf ~loc
        "native-react: ref cannot be passed as a normal prop. Please use \
         `forward_ref` API instead."
  | Pexp_fun
      (((Labelled label | Optional label) as arg), default, pattern, expression)
    ->
      let () =
        match (arg, pattern, default) with
        | Optional _, { ppat_desc = Ppat_constraint (_, { ptyp_desc }) }, None
          -> (
            match ptyp_desc with
            | Ptyp_constr ({ txt = Lident "option" }, [ _ ]) -> ()
            | _ ->
                let currentType =
                  match ptyp_desc with
                  | Ptyp_constr ({ txt }, []) ->
                      String.concat "." (Longident.flatten_exn txt)
                  | Ptyp_constr ({ txt }, _innerTypeArgs) ->
                      String.concat "." (Longident.flatten_exn txt) ^ "(...)"
                  | _ -> "..."
                in
                Location.raise_errorf ~loc:pattern.ppat_loc
                  "native-react: optional argument annotations must have \
                   explicit `option`. Did you mean `option(%s)=?`?"
                  currentType)
        | _ -> ()
      in
      let alias =
        match pattern with
        | { ppat_desc = Ppat_alias (_, { txt }) | Ppat_var { txt } } -> txt
        | { ppat_desc = Ppat_any } -> "_"
        | _ -> label
      in
      let type_ =
        match pattern with
        | { ppat_desc = Ppat_constraint (_, type_) } -> Some type_
        | _ -> None
      in
      recursivelyTransformNamedArgsForMake mapper expression
        (( Str_label.of_arg_label arg
         , default
         , pattern
         , alias
         , pattern.ppat_loc
         , type_ )
        :: list)
  | Pexp_fun
      ( Nolabel
      , _
      , { ppat_desc = Ppat_construct ({ txt = Lident "()" }, _) | Ppat_any }
      , _expression ) ->
      (list, None)
  | Pexp_fun
      ( Nolabel
      , _
      , { ppat_desc =
            ( Ppat_var { txt }
            | Ppat_constraint ({ ppat_desc = Ppat_var { txt } }, _) )
        }
      , _expression ) ->
      (list, Some txt)
  | Pexp_fun (Nolabel, _, pattern, _expression) ->
      Location.raise_errorf ~loc:pattern.ppat_loc
        "native-react: react.component refs only support plain arguments and \
         type annotations."
  | _ -> (list, None)

let arg_to_concrete_type types (arg, loc, type_) =
  match arg with
  | Str_label.Labelled _ -> (arg, [], type_) :: types
  | Optional _ ->
      (arg, [], Typ.constr ~loc { loc; txt = optionIdent } [ type_ ]) :: types

let argToType types (name, default, _noLabelName, _alias, loc, type_) =
  let open Str_label in
  match (type_, name, default) with
  | ( Some { ptyp_desc = Ptyp_constr ({ txt = Lident "option" }, [ type_ ]) }
    , (Optional _ as name)
    , _ ) ->
      ( name
      , []
      , { type_ with
          ptyp_desc =
            Ptyp_constr ({ loc = type_.ptyp_loc; txt = optionIdent }, [ type_ ])
        } )
      :: types
  | Some type_, name, Some _default ->
      ( name
      , []
      , { ptyp_desc = Ptyp_constr ({ loc; txt = optionIdent }, [ type_ ])
        ; ptyp_loc = loc
        ; ptyp_attributes = []
        ; ptyp_loc_stack = []
        } )
      :: types
  | Some type_, name, _ -> (name, [], type_) :: types
  | None, (Optional _ as name), _ ->
      ( name
      , []
      , { ptyp_desc =
            Ptyp_constr
              ( { loc; txt = optionIdent }
              , [ { ptyp_desc = Ptyp_var (safeTypeFromValue name)
                  ; ptyp_loc = loc
                  ; ptyp_attributes = []
                  ; ptyp_loc_stack = []
                  }
                ] )
        ; ptyp_loc = loc
        ; ptyp_attributes = []
        ; ptyp_loc_stack = []
        } )
      :: types
  | None, (Labelled _ as name), _ ->
      ( name
      , []
      , { ptyp_desc = Ptyp_var (safeTypeFromValue name)
        ; ptyp_loc = loc
        ; ptyp_attributes = []
        ; ptyp_loc_stack = []
        } )
      :: types

(* Builds the function that will be passed as first param to React.create_element *)
let make_js_comp
    ~loc
    ~fn_name
    ~forward_ref
    ~has_unit
    ~named_arg_list
    ~named_type_list
    ~payload
    ~wrap
    rest =
  let props = get_props_attr payload in
  let pluck_arg (label, _, _, _, loc, _) =
    let label_str = Str_label.str label in
    let props_name_id = Exp.ident ~loc { txt = Lident props.propsName; loc } in
    let label_const = Exp.constant ~loc (Const.string label_str) in
    let send =
      Exp.send ~loc
        (Exp.ident ~loc { txt = Lident "x"; loc })
        { txt = label_str; loc }
    in
    (* https://github.com/ocsigen/js_of_ocaml/blob/b1c807eaa40fa17b04c7d8e7e24306a03a46681d/ppx/ppx_js/lib_internal/ppx_js_internal.ml#L322-L332 *)
    let expr =
      [%expr
        (fun (type res a0) (a0 : a0 Js_of_ocaml.Js.t)
             (_ : a0 -> < get : res ; .. > Js_of_ocaml.Js.gen_prop) : res ->
          Js_of_ocaml.Js.Unsafe.get a0 [%e label_const])
          ([%e props_name_id] : < .. > Js_of_ocaml.Js.t)
          (fun x -> [%e send])]
    in
    (Str_label.to_arg_label label, expr)
  in
  let args =
    List.map pluck_arg named_arg_list
    @ (match forward_ref with
      | Some txt -> [ (Nolabel, Exp.ident ~loc { txt = Lident txt; loc }) ]
      | None -> [])
    @
    if has_unit then
      [ (Nolabel, Exp.construct { loc; txt = Lident "()" } None) ]
    else []
  in
  let inner_expr = Exp.apply (Exp.ident { loc; txt = Lident fn_name }) args in
  let inner_expr_with_ref =
    match forward_ref with
    | Some txt ->
        { inner_expr with
          pexp_desc =
            Pexp_fun
              ( nolabel
              , None
              , { ppat_desc = Ppat_var { txt; loc }
                ; ppat_loc = loc
                ; ppat_attributes = []
                ; ppat_loc_stack = []
                }
              , inner_expr )
        }
    | None -> inner_expr
  in
  Exp.mk ~loc ~attrs:[ merlin_hide ]
    (Pexp_let
       ( Nonrecursive
       , [ Vb.mk
             (Pat.var { loc; txt = fn_name })
             (wrap
                (Exp.fun_ nolabel None
                   { ppat_desc =
                       Ppat_constraint
                         ( makePropsName ~loc props.propsName
                         , makePropsType ~loc named_type_list )
                   ; ppat_loc = loc
                   ; ppat_attributes = []
                   ; ppat_loc_stack = []
                   }
                   inner_expr_with_ref))
         ]
       , rest ))

(* Builds the intermediate function with labelled arguments that will call make_props.
   [body] is the the component implementation as originally written in source,
   but without any wrappers like React.memo or forward_ref *)
let make_ml_comp ~loc ~fn_name ~body rest =
  Exp.mk ~loc
    (Pexp_let
       (Nonrecursive, [ Vb.mk (Pat.var { loc; txt = fn_name }) body ], rest))

(* This function takes any value binding and checks if it should be processed
   in case [react.component] attr is found, or if [inside_component] is passed. *)
let process_value_binding ~pstr_loc ~inside_component ~mapper binding =
  let gloc = { pstr_loc with loc_ghost = true } in
  if has_attr_on_binding binding || inside_component then
    let binding_loc = binding.pvb_loc in
    let binding_pat_loc = binding.pvb_pat.ppat_loc in
    let fn_name = getFnName binding.pvb_pat in
    let fn_ident = Exp.ident ~loc:gloc { loc = gloc; txt = Lident fn_name } in
    let modified_binding_old binding =
      let expression = binding.pvb_expr in
      (* TODO: there is a long-tail of unsupported features inside of blocks - Pexp_letmodule , Pexp_letexception , Pexp_ifthenelse *)
      let rec spelunk_for_fun_expr expression =
        match expression with
        (* let make = (~prop) => ... *)
        | { pexp_desc = Pexp_fun _ } -> expression
        (* let make = {let foo = bar in (~prop) => ...} *)
        | { pexp_desc = Pexp_let (_recursive, _vbs, return_expr) } ->
            (* here's where we spelunk! *)
            spelunk_for_fun_expr return_expr
        (* let make = React.forward_ref((~prop) => ...) or
           let make = React.memo(~compare, (~prop) => ...) *)
        | { pexp_desc =
              Pexp_apply
                ( _wrapper_expr
                , ( [ (Nolabel, inner_fun_expr) ]
                  | [ (Labelled "compare", _); (Nolabel, inner_fun_expr) ]
                  | [ (Nolabel, inner_fun_expr); (Labelled "compare", _) ] ) )
          } ->
            spelunk_for_fun_expr inner_fun_expr
        | { pexp_desc = Pexp_sequence (_wrapper_expr, inner_fun_expr) } ->
            spelunk_for_fun_expr inner_fun_expr
        | { pexp_desc = Pexp_newtype (_label, inner_fun_expr) } ->
            spelunk_for_fun_expr inner_fun_expr
        | { pexp_desc = Pexp_constraint (inner_fun_expr, _typ) } ->
            spelunk_for_fun_expr inner_fun_expr
        | exp ->
            Location.raise_errorf ~loc:exp.pexp_loc
              "react.component calls can only be on function definitions or \
               component wrappers (forward_ref, memo)."
      in
      spelunk_for_fun_expr expression
    in
    let named_arg_list, forward_ref =
      recursivelyTransformNamedArgsForMake mapper
        (modified_binding_old binding)
        []
    in
    let named_arg_list_with_key_and_ref =
      ( Str_label.Optional "key"
      , None
      , Pat.var { txt = "key"; loc = gloc }
      , "key"
      , gloc
      , Some (keyType gloc) )
      :: named_arg_list
    in
    let named_arg_list_with_key_and_ref =
      match forward_ref with
      | Some _ ->
          ( Str_label.Optional "ref"
          , None
          , Pat.var { txt = "ref"; loc = gloc }
          , "ref"
          , gloc
          , Some (refType gloc) )
          :: named_arg_list_with_key_and_ref
      | None -> named_arg_list_with_key_and_ref
    in
    let modified_binding binding =
      let has_application = ref false in
      let expression = binding.pvb_expr in
      let unerasable_ignore_exp exp =
        { exp with
          pexp_attributes = unerasableIgnore gloc :: exp.pexp_attributes
        }
      in
      (* TODO: there is a long-tail of unsupported features inside of blocks - Pexp_letmodule , Pexp_letexception , Pexp_ifthenelse *)
      let rec spelunk_for_fun_expr expression =
        match expression with
        (* let make = (~prop) => ... with no final unit *)
        | { pexp_desc =
              Pexp_fun
                ( ((Labelled _ | Optional _) as label)
                , default
                , pattern
                , ({ pexp_desc = Pexp_fun _ } as internalExpression) )
          } ->
            let wrap, has_unit, exp = spelunk_for_fun_expr internalExpression in
            ( wrap
            , has_unit
            , unerasable_ignore_exp
                { expression with
                  pexp_desc = Pexp_fun (label, default, pattern, exp)
                } )
        (* let make = (()) => ... *)
        (* let make = (_) => ... *)
        | { pexp_desc =
              Pexp_fun
                ( Nolabel
                , default
                , ({ ppat_desc =
                       Ppat_construct ({ txt = Lident "()" }, _) | Ppat_any
                   } as pattern)
                , internalExpression )
          } ->
            let loc = expression.pexp_loc in
            ( (fun a -> a)
            , true
            , { expression with
                pexp_desc =
                  Pexp_fun
                    ( Nolabel
                    , default
                    , pattern
                    , [%expr ([%e internalExpression] : React.element)] )
              } )
        (* let make = (~prop) => ... *)
        | { pexp_desc =
              Pexp_fun
                ( ((Labelled _ | Optional _) as label)
                , default
                , pattern
                , internalExpression )
          } ->
            let loc = expression.pexp_loc in
            ( (fun a -> a)
            , false
            , { (unerasable_ignore_exp expression) with
                pexp_desc =
                  Pexp_fun
                    ( label
                    , default
                    , pattern
                    , [%expr ([%e internalExpression] : React.element)] )
              } )
        (* let make = (prop) => ... *)
        | { pexp_desc =
              Pexp_fun (_nolabel, _default, pattern, _internalExpression)
          } ->
            if has_application.contents then
              ((fun a -> a), false, unerasable_ignore_exp expression)
            else
              Location.raise_errorf ~loc:pattern.ppat_loc
                "native-react: props need to be labelled arguments.\n\
                \  If you are working with refs be sure to wrap with \
                 React.forward_ref.\n\
                \  If your component doesn't have any props use () or _ \
                 instead of a name."
        (* let make = {let foo = bar in (~prop) => ...} *)
        | { pexp_desc = Pexp_let (recursive, vbs, internalExpression) } ->
            (* here's where we spelunk! *)
            let wrap, has_unit, exp = spelunk_for_fun_expr internalExpression in
            ( wrap
            , has_unit
            , { expression with pexp_desc = Pexp_let (recursive, vbs, exp) } )
        (* let make = React.forward_ref((~prop) => ...) *)
        | { pexp_desc =
              Pexp_apply (wrapper_expr, [ (Nolabel, internalExpression) ])
          } ->
            let () = has_application := true in
            let _, has_unit, exp = spelunk_for_fun_expr internalExpression in
            ( (fun exp -> Exp.apply wrapper_expr [ (nolabel, exp) ])
            , has_unit
            , exp )
        (* let make = React.memo(~compare, (~prop) => ...) *)
        | { pexp_desc =
              Pexp_apply
                ( wrapper_expr
                , ( [ (Nolabel, internalExpression)
                    ; ((Labelled "compare", _) as compareProps)
                    ]
                  | [ ((Labelled "compare", _) as compareProps)
                    ; (Nolabel, internalExpression)
                    ] ) )
          } ->
            let () = has_application := true in
            let _, has_unit, exp = spelunk_for_fun_expr internalExpression in
            ( (fun exp ->
                Exp.apply wrapper_expr [ (nolabel, exp); compareProps ])
            , has_unit
            , exp )
        | { pexp_desc = Pexp_sequence (wrapper_expr, internalExpression) } ->
            let wrap, has_unit, exp = spelunk_for_fun_expr internalExpression in
            ( wrap
            , has_unit
            , { expression with pexp_desc = Pexp_sequence (wrapper_expr, exp) }
            )
        | e -> ((fun a -> a), false, e)
      in
      let wrap, has_unit, expression = spelunk_for_fun_expr expression in
      (wrap, has_unit, expression)
    in
    let wrap, has_unit, ml_comp_body = modified_binding binding in
    let react_component_attr =
      try Some (List.find hasAttr binding.pvb_attributes)
      with Not_found -> None
    in
    let payload =
      match react_component_attr with
      | Some { attr_payload } -> Some attr_payload
      | None -> None
    in
    let named_type_list = List.fold_left argToType [] named_arg_list in
    let ml_comp = make_ml_comp ~loc:pstr_loc ~fn_name ~body:ml_comp_body in
    let js_comp =
      make_js_comp ~loc:gloc ~fn_name ~forward_ref ~has_unit ~named_arg_list
        ~named_type_list ~payload ~wrap
    in
    let make_props =
      let named_arg_list =
        List.map pluckLabelDefaultLocType named_arg_list_with_key_and_ref
      in
      let js_props_obj = make_js_props_obj ~loc:gloc named_arg_list in
      make_make_props js_props_obj fn_name gloc named_arg_list named_type_list
    in
    let set_display_name expr =
      if dev_mode then
        let loc = gloc in
        [%expr
          React.set_display_name [%e fn_ident] __FUNCTION__;
          [%e expr]]
      else expr
    in
    Vb.mk ~loc:binding_loc
      ~attrs:(List.filter otherAttrsPure binding.pvb_attributes)
      (Pat.var ~loc:binding_pat_loc { loc = binding_pat_loc; txt = fn_name })
      (let outer =
         make_funs_for_make_props_body
           (List.map pluckLabelDefaultLocType named_arg_list_with_key_and_ref)
           (let loc = gloc in
            [%expr
              fun () ->
                React.create_element [%e fn_ident]
                  [%e
                    Exp.apply ~loc
                      (Exp.ident ~loc
                         { loc; txt = Lident (make_props_name fn_name) })
                      (List.map
                         (fun ( arg
                              , _default
                              , _pattern
                              , _alias
                              , _pattern_loc
                              , _type ) ->
                           ( Str_label.to_arg_label arg
                           , Exp.ident ~loc:gloc
                               { loc = gloc; txt = Lident (Str_label.str arg) }
                           ))
                         named_arg_list_with_key_and_ref
                      @ [ ( Nolabel
                          , Exp.construct { loc; txt = Lident "()" } None )
                        ])]])
       in
       make_props @@ ml_comp @@ js_comp @@ set_display_name @@ outer)
  else binding

(* Builds the args list for elements like <Foo bar=2 />, or for React.Fragment: <> <div /> <p /> </> *)
let uppercase_element_args ~loc callArguments =
  let children, argsWithLabels =
    extractChildren ~loc ~removeLastPositionUnit:true callArguments
  in
  let argsForMake = argsWithLabels in
  let recursivelyTransformedArgsForMake =
    argsForMake |> List.map (fun (label, expression) -> (label, expression))
  in
  let filtered_children =
    match children with
    | [%expr []] -> []
    | children -> [ (labelled "children", children) ]
  in
  ( children
  , recursivelyTransformedArgsForMake @ filtered_children
    @ [ (nolabel, Exp.construct ~loc { loc; txt = Lident "()" } None) ] )

(* TODO: some line number might still be wrong *)
let jsxMapper () =
  let transformLowercaseCall loc attrs callArguments id callLoc =
    let children, nonChildrenProps = extractChildren ~loc callArguments in
    let componentNameExpr = Exp.ident { loc; txt = Lident id } in
    let args =
      (* Filtering out last unit *)
      let labeled_arg (name, value) =
        match isUnit value with
        | true -> None
        | false -> (
            match name with
            | Optional str -> Some (Str_label.Optional str, value)
            | Labelled str -> Some (Str_label.Labelled str, value)
            | Nolabel -> None)
      in
      let labeledProps = List.filter_map labeled_arg nonChildrenProps in
      let makePropField (str_label, value) =
        let loc = callLoc in
        match str_label with
        | Str_label.Optional str ->
            [%expr
              Prop.(maybe [%e Exp.ident { loc; txt = Lident str }]) [%e value]]
        | Labelled str ->
            [%expr
              [%e Exp.ident { loc; txt = Ldot (Lident "Prop", str) }] [%e value]]
      in
      let propsArray = Exp.array ~loc (List.map makePropField labeledProps) in
      [ (* [| href "..."; target "_blank" |] *)
        (nolabel, propsArray)
      ; (nolabel, children)
      ]
    in
    Exp.apply
      ~loc (* throw away the [@JSX] attribute and keep the others, if any *)
      ~attrs (* "div", "p" or the component name *) componentNameExpr args
  in
  let nestedModules = ref [] in
  let rec transformComponentDefinition
      ?(inside_component = false)
      mapper
      structure
      returnStructures =
    match structure with
    (* external *)
    | { pstr_loc
      ; pstr_desc =
          Pstr_primitive
            { pval_loc
            ; pval_name = { txt = fn_name }
            ; pval_attributes
            ; pval_type
            ; pval_prim
            }
      } -> (
        match (inside_component, List.partition hasAttr pval_attributes) with
        | false, ([], _) -> structure :: returnStructures
        | true, (_, rest_attrs) | _, (_ :: _, rest_attrs) -> (
            match pval_prim with
            | [] | _ :: _ :: _ ->
                Location.raise_errorf ~loc:pval_loc
                  "native-react: externals only allow single primitive \
                   declarations"
            | [ pval_prim ] ->
                let rec get_prop_types types { ptyp_loc; ptyp_desc } =
                  match ptyp_desc with
                  | Ptyp_arrow
                      ( ((Labelled _ | Optional _) as arg_label)
                      , type_
                      , ({ ptyp_desc = Ptyp_arrow _ } as rest) ) ->
                      get_prop_types
                        ((Str_label.of_arg_label arg_label, ptyp_loc, type_)
                        :: types)
                        rest
                  | Ptyp_arrow (Nolabel, { ptyp_loc }, _rest) ->
                      Location.raise_errorf ~loc:ptyp_loc
                        "native-react: externals only allow labelled or \
                         optional labelled arguments"
                  | Ptyp_arrow
                      ( ((Labelled _ | Optional _) as arg_label)
                      , type_
                      , returnValue ) ->
                      ( Str_label.of_arg_label arg_label
                      , returnValue.ptyp_loc
                      , type_ )
                      :: types
                  | Ptyp_any | Ptyp_var _ | Ptyp_tuple _
                  | Ptyp_constr (_, _)
                  | Ptyp_object (_, _)
                  | Ptyp_class (_, _)
                  | Ptyp_alias (_, _)
                  | Ptyp_variant (_, _, _)
                  | Ptyp_poly (_, _)
                  | Ptyp_package _ | Ptyp_extension _ ->
                      types
                in
                let prop_types = get_prop_types [] pval_type in
                let named_type_list =
                  List.fold_left arg_to_concrete_type [] prop_types
                in
                let pluck_label_and_loc (label, loc, type_) =
                  ( label
                  , None (* default *)
                  , Pat.var { txt = Str_label.str label; loc }
                  , Str_label.str label
                  , loc
                  , Some type_ )
                in
                let named_arg_list_with_key =
                  let loc = pstr_loc in
                  ( Str_label.Optional "key"
                  , None
                  , Pat.var { txt = "key"; loc }
                  , "key"
                  , loc
                  , Some [%type: string] )
                  :: List.map pluck_label_and_loc prop_types
                in
                let make_props =
                  let named_arg_list =
                    List.map pluckLabelDefaultLocType named_arg_list_with_key
                  in
                  let js_props_obj =
                    make_external_js_props_obj ~loc:pstr_loc named_arg_list
                  in
                  make_make_props js_props_obj fn_name pstr_loc named_arg_list
                    named_type_list
                in
                let gloc = { pstr_loc with loc_ghost = true } in
                let binding_pat_loc = gloc in
                let outer_make expression =
                  Vb.mk ~loc:pstr_loc ~attrs:rest_attrs
                    (Pat.var ~loc:binding_pat_loc
                       { loc = binding_pat_loc; txt = fn_name })
                    (let outer =
                       make_funs_for_make_props_body
                         (List.map pluckLabelDefaultLocType
                            named_arg_list_with_key)
                         (let loc = gloc in
                          [%expr
                            fun () ->
                              React.create_element [%e expression]
                                [%e
                                  Exp.apply ~loc
                                    (Exp.ident ~loc
                                       { loc
                                       ; txt = Lident (make_props_name fn_name)
                                       })
                                    (List.map
                                       (fun ( arg
                                            , _default
                                            , _pattern
                                            , _alias
                                            , _pattern_loc
                                            , _type ) ->
                                         ( Str_label.to_arg_label arg
                                         , Exp.ident ~loc:gloc
                                             { loc = gloc
                                             ; txt = Lident (Str_label.str arg)
                                             } ))
                                       named_arg_list_with_key
                                    @ [ ( Nolabel
                                        , Exp.construct
                                            { loc; txt = Lident "()" } None )
                                      ])]])
                     in
                     make_props outer)
                in
                let js_component_expr =
                  let loc = pstr_loc in
                  [%expr
                    Js_of_ocaml.Js.Unsafe.js_expr
                      [%e constantString ~loc pval_prim]]
                in
                { pstr_loc
                ; pstr_desc =
                    Pstr_value (Nonrecursive, [ outer_make js_component_expr ])
                }
                :: returnStructures))
    (* let%component foo = ... or external%component foo = ... *)
    | { pstr_desc = Pstr_extension (({ txt = "component" }, PStr structure), _)
      } ->
        List.fold_right
          (transformComponentDefinition ~inside_component:true mapper)
          structure returnStructures
    (* let component = ... *)
    | { pstr_loc; pstr_desc = Pstr_value (rec_flag, value_bindings) } ->
        let bindings =
          List.map
            (process_value_binding ~pstr_loc ~inside_component ~mapper)
            value_bindings
        in
        [ { pstr_loc; pstr_desc = Pstr_value (rec_flag, bindings) } ]
        @ returnStructures
    | structure -> structure :: returnStructures
  in
  let reactComponentTransform mapper structure_items =
    List.fold_right (transformComponentDefinition mapper) structure_items []
  in
  let transformJsxCall
      callExpression
      callArguments
      attrs
      apply_loc
      apply_loc_stack =
    match callExpression.pexp_desc with
    | Pexp_ident caller -> (
        match caller with
        | { txt = Lident "createElement" } ->
            raise
              (Invalid_argument
                 "JSX: `createElement` should be preceeded by a module name.")
        (* Foo.createElement(~prop1=foo, ~prop2=bar, ~children=[], ()) *)
        | { loc; txt = Ldot (modulePath, "createElement") } ->
            let _children_expr, args =
              uppercase_element_args ~loc callArguments
            in
            { pexp_desc =
                Pexp_apply
                  ( { callExpression with
                      pexp_desc =
                        Pexp_ident { loc; txt = Ldot (modulePath, "make") }
                    }
                  , args )
            ; pexp_attributes = attrs
            ; pexp_loc = apply_loc
            ; pexp_loc_stack = apply_loc_stack
            }
        (* div(~prop1=foo, ~prop2=bar, ~children=[bla], ()) *)
        (* turn that into
           React.Dom.createElement(~props=React.Dom.props(~props1=foo, ~props2=bar, ()), [|bla|]) *)
        | { loc; txt = Lident id } ->
            transformLowercaseCall loc attrs callArguments id apply_loc
        | { txt = Ldot (_, anythingNotCreateElementOrMake) } ->
            raise
              (Invalid_argument
                 ("JSX: the JSX attribute should be attached to a \
                   `YourModuleName.createElement` or `YourModuleName.make` \
                   call. We saw `" ^ anythingNotCreateElementOrMake
                ^ "` instead"))
        | { txt = Lapply _ } ->
            (* don't think there's ever a case where this is reached *)
            raise
              (Invalid_argument
                 "JSX: encountered a weird case while processing the code. \
                  Please report this!"))
    | _ ->
        raise
          (Invalid_argument
             "JSX: `createElement` should be preceeded by a simple, direct \
              module name.")
  in
  object (self)
    inherit Ast_traverse.map as super

    method! structure structure =
      match structure with
      | structure_items ->
          super#structure (reactComponentTransform self structure_items)

    method! expression expression =
      let expression = super#expression expression in
      match expression with
      | { pexp_desc = Pexp_apply (callExpression, callArguments)
        ; pexp_attributes
        ; pexp_loc = apply_loc
        ; pexp_loc_stack
        } -> (
          (* Does the function application have the @JSX attribute? *)
          let jsxAttribute, nonJSXAttributes =
            List.partition
              (fun attribute -> attribute.attr_name.txt = "JSX")
              pexp_attributes
          in
          match (jsxAttribute, nonJSXAttributes) with
          (* no JSX attribute *)
          | [], _ -> expression
          | _, nonJSXAttributes ->
              transformJsxCall callExpression callArguments nonJSXAttributes
                apply_loc pexp_loc_stack)
      (* is it a list with jsx attribute? Reason <>foo</> desugars to [@JSX][foo]*)
      | { pexp_desc =
            ( Pexp_construct
                ({ txt = Lident "::"; loc }, Some { pexp_desc = Pexp_tuple _ })
            | Pexp_construct ({ txt = Lident "[]"; loc }, None) )
        ; pexp_attributes
        ; pexp_loc
        ; pexp_loc_stack
        } as listItems -> (
          let jsxAttribute, nonJSXAttributes =
            List.partition
              (fun attribute -> attribute.attr_name.txt = "JSX")
              pexp_attributes
          in
          match (jsxAttribute, nonJSXAttributes) with
          (* no JSX attribute *)
          | [], _ -> expression
          | _, nonJSXAttributes ->
              let callExpression = [%expr React.Fragment.createElement] in
              transformJsxCall callExpression
                [ (Labelled "children", { listItems with pexp_attributes = [] })
                ]
                nonJSXAttributes pexp_loc pexp_loc_stack)
      (* Delegate to the default mapper, a deep identity traversal *)
      | _e -> expression

    method! module_binding module_binding =
      let _ =
        match module_binding.pmb_name.txt with
        | None -> ()
        | Some txt -> nestedModules := txt :: !nestedModules
      in
      let mapped = super#module_binding module_binding in
      let _ = nestedModules := List.tl !nestedModules in
      mapped
  end

let rewrite_implementation (code : Parsetree.structure) : Parsetree.structure =
  let mapper = jsxMapper () in
  mapper#structure code

let rewrite_signature (code : Parsetree.signature) : Parsetree.signature =
  let mapper = jsxMapper () in
  mapper#signature code

let () =
  Driver.register_transformation "native-react-ppx" ~impl:rewrite_implementation
    ~intf:rewrite_signature
