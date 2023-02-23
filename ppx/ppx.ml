(*
  This is the file that handles turning Reason JSX' agnostic function call into
  server-reason-react calls, defined in lib/react.ml or lib/reactDom.ml.

  Check the tests for more concrete examples, but the general idea is:

  transform
  `[@JSX] div(~props1=a, ~props2=b, ~children=[foo, bar], ())`
  `React.createElement("div", [| React.Attribute.XXX((props1, 1), React.Attribute.XXX((props2, b)), [foo, bar])`.

  transform the upper-cased case
  `[@JSX] Foo.createElement(~key=a, ~ref=b, ~foo=bar, ~children=[], ())`
  `React.createElement(Foo.make(~key=a, ~ref=b, ~foo=bar, ()))`

  transform the upper-cased case
  `[@JSX] Foo.createElement(~foo=bar, ~children=[foo, bar], ())`
  `React.createElement(Foo.make(~foo=bar, ()), [foo, bar])`

  transform
  `[@JSX] [foo]`
  `React.createFragment([foo])`
 *)

module OCaml_location = Location
open Ppxlib
open Ast_helper

let rec find_opt p = function
  | [] -> None
  | x :: l -> if p x then Some x else find_opt p l

let isCap str =
  let first = String.sub str 0 1 in
  let capped = String.uppercase_ascii first in
  first = capped

let nolabel = Nolabel
let labelled str = Labelled str
let optional str = Optional str
let isOptional str = match str with Optional _ -> true | _ -> false
let isLabelled str = match str with Labelled _ -> true | _ -> false

let getLabel str =
  match str with Optional str | Labelled str -> str | Nolabel -> ""

let optionIdent = Lident "option"

let argIsKeyRef = function
  | Labelled ("key" | "ref"), _ | Optional ("key" | "ref"), _ -> true
  | _ -> false

let isUnit expr =
  match expr.pexp_desc with
  | Pexp_construct ({ txt = Lident "()"; _ }, _) -> true
  | _ -> false

let constantString ~loc str = Ast_helper.Exp.constant ~loc (Const.string str)

let safeTypeFromValue valueStr =
  let valueStr = getLabel valueStr in
  match String.sub valueStr 0 1 with "_" -> "T" ^ valueStr | _ -> valueStr

let keyType loc =
  Typ.constr ~loc { loc; txt = optionIdent }
    [ Typ.constr ~loc { loc; txt = Lident "string" } [] ]

let refType loc = [%type: ReactDom.domRef]

type 'a children =
  | ListLiteral of 'a
  | Exact of 'a

type componentConfig = { propsName : string }

let revAstList ~loc expr =
  let rec revAstList_ acc = function
    | [%expr []] -> acc
    | [%expr [%e? hd] :: [%e? tl]] -> revAstList_ [%expr [%e hd] :: [%e acc]] tl
    | expr -> expr
  in
  revAstList_ [%expr []] expr

(* unlike reason-react ppx, we don't transform to array, just apply mapper to children *)
let transformChildrenIfListUpper ~loc ~mapper theList =
  (* unlike reason-react ppx, we don't transform to array as it'd be incompatible with
     [@js.variadic] gen_js_api attribute, which requires argument to be a list *)
  let rec transformChildren_ theList accum =
    (* not in the sense of converting a list to an array; convert the AST
       reprensentation of a list to the AST reprensentation of an array *)
    match theList with
    | [%expr []] -> (
        match accum with
        | [%expr [ [%e? singleElement] ]] -> Exact singleElement
        | accum -> ListLiteral (revAstList ~loc accum))
    | [%expr [%e? v] :: [%e? acc]] ->
        transformChildren_ acc [%expr [%e mapper#expression v] :: [%e accum]]
    | notAList -> Exact (mapper#expression notAList)
  in
  transformChildren_ theList [%expr []]

let transformChildrenIfList2 ~loc ~mapper theList =
  let rec transformChildren_ theList accum =
    (* not in the sense of converting a list to an array; convert the AST
       reprensentation of a list to the AST reprensentation of an array *)
    match theList with
    | { pexp_desc = Pexp_construct ({ txt = Lident "[]" }, None) } ->
        Exp.array ~loc (List.rev accum)
    | { pexp_desc =
          Pexp_construct
            ({ txt = Lident "::" }, Some { pexp_desc = Pexp_tuple [ v; acc ] })
      } ->
        transformChildren_ acc (mapper#expression mapper v :: accum)
    | notAList -> mapper#expression mapper notAList
  in
  transformChildren_ theList []

let list_have_tail listExpr =
  match listExpr with
  | Pexp_construct ({ txt = Lident "::" }, Some { pexp_desc = Pexp_tuple _ })
  | Pexp_construct ({ txt = Lident "[]" }, None) ->
      false
  | _ -> true

let transformChildrenIfList ~loc ~mapper children =
  let rec transformChildren_ children accum =
    match children with
    | [%expr []] -> revAstList ~loc accum
    | [%expr [%e? v] :: [%e? acc]] when not (list_have_tail acc.pexp_desc) ->
        [%expr [%e mapper#expression v]]
    | [%expr [%e? v] :: [%e? acc]] ->
        transformChildren_ acc [%expr [%e mapper#expression v] :: [%e accum]]
    | notAList -> mapper#expression notAList
  in
  transformChildren_ children [%expr []]

let extractChildren ?(removeLastPositionUnit = false) ~loc propsAndChildren =
  let rec allButLast_ lst acc =
    match lst with
    | [] -> []
    | [ (Nolabel, { pexp_desc = Pexp_construct ({ txt = Lident "()" }, None) })
      ] ->
        acc
    | (Nolabel, _) :: _rest ->
        raise
          (Invalid_argument
             "JSX: found non-labelled argument before the last position")
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
  | _ ->
      raise
        (Invalid_argument "JSX: somehow there's more than one `children` label")

let unerasableIgnore loc =
  { attr_name = { txt = "warning"; loc }
  ; attr_payload = PStr [ Str.eval (Exp.constant (Const.string "-16")) ]
  ; attr_loc = loc
  }

let merlinFocus =
  { attr_name = { txt = "merlin.focus"; loc = Location.none }
  ; attr_payload = PStr []
  ; attr_loc = Location.none
  }

(* Helper method to look up the [@react.component] attribute *)
let hasAttr { attr_name; _ } = attr_name.txt = "react.component"

(* Helper method to filter out any attribute that isn't [@react.component] *)
let otherAttrsPure { attr_name; _ } = attr_name.txt <> "react.component"

(* Iterate over the attributes and try to find the [@react.component] attribute *)
let hasAttrOnBinding { pvb_attributes } =
  find_opt hasAttr pvb_attributes <> None

(* Filter the [@react.component] attribute and immutably replace them on the binding *)
let filterAttrOnBinding binding =
  { binding with
    pvb_attributes = List.filter otherAttrsPure binding.pvb_attributes
  }

(* Finds the name of the variable the binding is assigned to, otherwise raises Invalid_argument *)
let getFnName binding =
  match binding with
  | { pvb_pat = { ppat_desc = Ppat_var { txt } } } -> txt
  | _ ->
      raise (Invalid_argument "react.component calls cannot be destructured.")

let makeNewBinding binding expression newName =
  match binding with
  | { pvb_pat = { ppat_desc = Ppat_var ppat_var } as pvb_pat } ->
      { binding with
        pvb_pat =
          { pvb_pat with ppat_desc = Ppat_var { ppat_var with txt = newName } }
      ; pvb_expr = expression
      ; pvb_attributes = [ merlinFocus ]
      }
  | _ ->
      raise (Invalid_argument "react.component calls cannot be destructured.")

(* Lookup the value of `props` otherwise raise Invalid_argument error *)
let getPropsNameValue _acc (loc, exp) =
  match (loc, exp) with
  | { txt = Lident "props" }, { pexp_desc = Pexp_ident { txt = Lident str } } ->
      { propsName = str }
  | { txt }, _ ->
      raise
        (Invalid_argument
           ("react.component only accepts props as an option, given: "
          ^ Longident.last_exn txt))

(* Lookup the `props` record or string as part of [@react.component] and store the name for use when rewriting *)
let getPropsAttr payload =
  let defaultProps = { propsName = "Props" } in
  match payload with
  | Some
      (PStr
        ({ pstr_desc =
             Pstr_eval ({ pexp_desc = Pexp_record (recordFields, None) }, _)
         }
        :: _rest)) ->
      List.fold_left getPropsNameValue defaultProps recordFields
  | Some
      (PStr
        ({ pstr_desc =
             Pstr_eval ({ pexp_desc = Pexp_ident { txt = Lident "props" } }, _)
         }
        :: _rest)) ->
      { propsName = "props" }
  | Some (PStr ({ pstr_desc = Pstr_eval (_, _) } :: _rest)) ->
      raise
        (Invalid_argument
           "react.component accepts a record config with props as an options.")
  | _ -> defaultProps

(* Plucks the label, loc, and type_ from an AST node *)
let pluckLabelDefaultLocType (label, default, _, _, loc, type_) =
  (label, default, loc, type_)

(* Lookup the filename from the location information on the AST node and turn it into a valid module identifier *)
let filenameFromLoc (pstr_loc : Location.t) =
  let fileName =
    match pstr_loc.loc_start.pos_fname with
    | "" -> !OCaml_location.input_name
    | fileName -> fileName
  in
  let fileName =
    try Filename.chop_extension (Filename.basename fileName)
    with Invalid_argument _ -> fileName
  in
  let fileName = String.capitalize_ascii fileName in
  fileName

(* Build a string representation of a module name with segments separated by $ *)
let makeModuleName fileName nestedModules fnName =
  let fullModuleName =
    match (fileName, nestedModules, fnName) with
    (* TODO: is this even reachable? It seems like the fileName always exists *)
    | "", nestedModules, "make" -> nestedModules
    | "", nestedModules, fnName -> List.rev (fnName :: nestedModules)
    | fileName, nestedModules, "make" -> fileName :: List.rev nestedModules
    | fileName, nestedModules, fnName ->
        fileName :: List.rev (fnName :: nestedModules)
  in
  let fullModuleName = String.concat "$" fullModuleName in
  fullModuleName

(*
  AST node builders
  These functions help us build AST nodes that are needed when transforming a [@react.component] into a
  constructor and a `makeProps` function
*)

(* Build an AST node representing all named args for the `makeProps` definition for a component's props *)
let rec makeArgsForMakePropsType list args =
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
        | ( label
          , Some
              { ptyp_desc = Ptyp_constr ({ txt = Lident "option"; _ }, [ type_ ])
              ; _
              }
          , _ )
        | ( label
          , Some
              { ptyp_desc =
                  Ptyp_constr
                    ({ txt = Ldot (Lident "*predef*", "option"); _ }, [ type_ ])
              ; _
              }
          , _ )
        (* ~foo: int=? - note this isnt valid. but we want to get a type error *)
        | label, Some type_, _
          when isOptional label ->
            type_
        (* ~foo=? *)
        | label, None, _ when isOptional label ->
            Typ.mk ~loc (Ptyp_var (safeTypeFromValue label))
        (* ~foo *)
        | label, None, _ -> Typ.mk ~loc (Ptyp_var (safeTypeFromValue label))
        | _label, Some type_, _ -> type_
      in
      makeArgsForMakePropsType tl (Typ.arrow ~loc label coreType args)
  | [] -> args

(* Build an AST node for the Js object representing props for a component *)
let makePropsValue fnName loc namedArgListWithKeyAndRef propsType =
  let propsName = fnName ^ "Props" in
  Val.mk ~loc { txt = propsName; loc }
    (makeArgsForMakePropsType namedArgListWithKeyAndRef
       (Typ.arrow Nolabel
          { ptyp_desc = Ptyp_constr ({ txt = Lident "unit"; loc }, [])
          ; ptyp_loc = loc
          ; ptyp_attributes = []
          ; ptyp_loc_stack = []
          }
          propsType))

(* Build an AST node for the signature of the `external` definition *)
let makePropsExternalSig fnName loc namedArgListWithKeyAndRef propsType =
  { psig_loc = loc
  ; psig_desc =
      Psig_value (makePropsValue fnName loc namedArgListWithKeyAndRef propsType)
  }

(* Build an AST node for the props name when converted to a Js.t inside the function signature  *)
let makePropsName ~loc name = Pat.mk ~loc (Ppat_var { txt = name; loc })

let makeObjectField loc (str, _attrs, propType) =
  let type_ = [%type: [%t propType] Js_of_ocaml.Js.readonly_prop] in
  { pof_desc = Otag ({ loc; txt = str }, { type_ with ptyp_attributes = [] })
  ; pof_loc = loc
  ; pof_attributes = []
  }

(* Build an AST node representing a "closed" Js_of_ocaml.Js.t object representing a component's props *)
let makePropsType ~loc namedTypeList =
  Typ.mk ~loc
    (Ptyp_constr
       ( { txt = Ldot (Lident "Js", "t"); loc }
       , [ Typ.mk ~loc
             (Ptyp_object (List.map (makeObjectField loc) namedTypeList, Closed))
         ] ))

let rec makeFunsForMakePropsBody list args =
  match list with
  | (label, _default, loc, _interiorType) :: tl ->
      makeFunsForMakePropsBody tl
        (Exp.fun_ ~loc label None
           { ppat_desc = Ppat_var { txt = getLabel label; loc }
           ; ppat_loc = loc
           ; ppat_attributes = []
           ; ppat_loc_stack = []
           }
           args)
  | [] -> args

let makeAttributeValue ~loc ~isOptional (type_ : DomProps.attributeType) value =
  match (type_, isOptional) with
  | String, true -> [%expr ([%e value] : string option)]
  | String, false -> [%expr ([%e value] : string)]
  | Int, false -> [%expr ([%e value] : int)]
  | Int, true -> [%expr ([%e value] : int option)]
  | Bool, false -> [%expr ([%e value] : bool)]
  | Bool, true -> [%expr ([%e value] : bool option)]
  | Style, false -> [%expr ([%e value] : ReactDom.Style.t)]
  | Style, true -> [%expr ([%e value] : ReactDom.Style.t option)]
  (* Those ReactDom types are currently on ReasonReact, in our implementation they are in React namespace *)
  | Ref, false -> [%expr ([%e value] : React.domRef)]
  | Ref, true -> [%expr ([%e value] : React.domRef option)]
  (* We don't have the runtime type of DangerouslySetInnerHTML, yet. In here we don't add any type constraint *)
  | InnerHtml, false -> [%expr [%e value]]
  | InnerHtml, true -> [%expr [%e value] option]
(* | InnerHtml, false -> [%expr ([%e value] : React.DangerouslySetInnerHTML.t)]
   | InnerHtml, true ->
       [%expr ([%e value] : React.DangerouslySetInnerHTML.t option)] *)

let makeEventValue ~loc ~isOptional (type_ : DomProps.eventType) value =
  match (type_, isOptional) with
  | Clipboard, false -> [%expr ([%e value] : ReactEvent.Clipboard.t -> unit)]
  | Clipboard, true ->
      [%expr ([%e value] : (ReactEvent.Clipboard.t -> unit) option)]
  | Composition, false ->
      [%expr ([%e value] : ReactEvent.Composition.t -> unit)]
  | Composition, true ->
      [%expr ([%e value] : (ReactEvent.Composition.t -> unit) option)]
  | Keyboard, false -> [%expr ([%e value] : ReactEvent.Keyboard.t -> unit)]
  | Keyboard, true ->
      [%expr ([%e value] : (ReactEvent.Keyboard.t -> unit) option)]
  | Focus, false -> [%expr ([%e value] : ReactEvent.Focus.t -> unit)]
  | Focus, true -> [%expr ([%e value] : (ReactEvent.Focus.t -> unit) option)]
  | Form, false -> [%expr ([%e value] : ReactEvent.Form.t -> unit)]
  | Form, true -> [%expr ([%e value] : (ReactEvent.Form.t -> unit) option)]
  | Mouse, false -> [%expr ([%e value] : ReactEvent.Mouse.t -> unit)]
  | Mouse, true -> [%expr ([%e value] : (ReactEvent.Mouse.t -> unit) option)]
  | Selection, false -> [%expr ([%e value] : ReactEvent.Selection.t -> unit)]
  | Selection, true ->
      [%expr ([%e value] : (ReactEvent.Selection.t -> unit) option)]
  | Touch, false -> [%expr ([%e value] : ReactEvent.Touch.t -> unit)]
  | Touch, true -> [%expr ([%e value] : (ReactEvent.Touch.t -> unit) option)]
  | UI, false -> [%expr ([%e value] : ReactEvent.UI.t -> unit)]
  | UI, true -> [%expr ([%e value] : (ReactEvent.UI.t -> unit) option)]
  | Wheel, false -> [%expr ([%e value] : ReactEvent.Wheel.t -> unit)]
  | Wheel, true -> [%expr ([%e value] : (ReactEvent.Wheel.t -> unit) option)]
  | Media, false -> [%expr ([%e value] : ReactEvent.Media.t -> unit)]
  | Media, true -> [%expr ([%e value] : (ReactEvent.Media.t -> unit) option)]
  | Image, false -> [%expr ([%e value] : ReactEvent.Image.t -> unit)]
  | Image, true -> [%expr ([%e value] : (ReactEvent.Image.t -> unit) option)]
  | Animation, false -> [%expr ([%e value] : ReactEvent.Animation.t -> unit)]
  | Animation, true ->
      [%expr ([%e value] : (ReactEvent.Animation.t -> unit) option)]
  | Transition, false -> [%expr ([%e value] : ReactEvent.Transition.t -> unit)]
  | Transition, true ->
      [%expr ([%e value] : (ReactEvent.Transition.t -> unit) option)]
  | Pointer, false -> [%expr ([%e value] : ReactEvent.Syntetic.t -> unit)]
  | Pointer, true ->
      [%expr ([%e value] : (ReactEvent.Syntetic.t -> unit) option)]
  | Inline, false -> [%expr ([%e value] : string)]
  | Inline, true -> [%expr ([%e value] : string option)]
  | Drag, false -> [%expr ([%e value] : ReactEvent.Drag.t -> unit)]
  | Drag, true -> [%expr ([%e value] : (ReactEvent.Drag.t -> unit) option)]

let makeValue ~loc ~isOptional prop value =
  match prop with
  | DomProps.Attribute attribute ->
      makeAttributeValue ~loc ~isOptional attribute.type_ value
  | DomProps.Event event -> makeEventValue ~loc ~isOptional event.type_ value

let makeJsObj ~loc namedArgListWithKeyAndRef =
  let labelToTuple label =
    let l = getLabel label in
    let id = Exp.ident ~loc { txt = Lident l; loc } in
    let make_tuple raw =
      match l = "key" with
      | true ->
          [%expr
            [%e Exp.constant ~loc (Const.string l)]
            , inject (Js_of_ocaml.Js.string [%e raw])]
      | false ->
          [%expr [%e Exp.constant ~loc (Const.string l)], inject [%e raw]]
    in
    match isOptional label with
    | true ->
        [%expr Option.map (fun raw -> [%e make_tuple [%expr raw]]) [%e id]]
    | false -> [%expr Some [%e make_tuple id]]
  in
  [%expr
    obj
      ([%e
         Exp.array ~loc
           (List.map
              (fun (label, _, _, _) -> labelToTuple label)
              namedArgListWithKeyAndRef)]
      |> Array.to_list
      |> List.filter_map (fun x -> x)
      |> Array.of_list)]

let makeValueBinding
    ~loc
    fnName
    namedArgListWithKeyAndRef
    componentImplementation =
  let name = makePropsName ~loc fnName in
  let body =
    makeFunsForMakePropsBody namedArgListWithKeyAndRef componentImplementation
  in

  Vb.mk ~loc name body

let makeStructure ~loc fnName namedArgListWithKeyAndRef componentImplementation
    =
  Str.mk ~loc
    (Pstr_value
       ( Nonrecursive
       , [ makeValueBinding ~loc fnName namedArgListWithKeyAndRef
             componentImplementation
         ] ))

(* Builds an AST node for the modified `make` function *)
let makeDeclaration
    ~loc
    fnName
    namedArgListWithKeyAndRef
    componentImplementation =
  makeValueBinding ~loc fnName
    (List.map pluckLabelDefaultLocType namedArgListWithKeyAndRef)
    componentImplementation

let rec recursivelyTransformNamedArgsForMake mapper expr list =
  let expr = mapper#expression expr in
  match expr.pexp_desc with
  (* TODO: make this show up with a loc. *)
  | Pexp_fun (Labelled "key", _, _, _) | Pexp_fun (Optional "key", _, _, _) ->
      raise
        (Invalid_argument
           "Key cannot be accessed inside of a component. Don't worry - you \
            can always key a component from its parent!")
  | Pexp_fun (Labelled "ref", _, _, _) | Pexp_fun (Optional "ref", _, _, _) ->
      raise
        (Invalid_argument
           "Ref cannot be passed as a normal prop. Please use `forwardRef` API \
            instead.")
  | Pexp_fun (arg, default, pattern, expression)
    when isOptional arg || isLabelled arg ->
      let () =
        match (isOptional arg, pattern, default) with
        | true, { ppat_desc = Ppat_constraint (_, { ptyp_desc }) }, None -> (
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
                  "optional argument annotations must have explicit `option`. \
                   Did you mean `option(%s)=?`?"
                  currentType)
        | _ -> ()
      in
      let alias =
        match pattern with
        | { ppat_desc = Ppat_alias (_, { txt }) | Ppat_var { txt } } -> txt
        | { ppat_desc = Ppat_any } -> "_"
        | _ -> getLabel arg
      in
      let type_ =
        match pattern with
        | { ppat_desc = Ppat_constraint (_, type_) } -> Some type_
        | _ -> None
      in
      recursivelyTransformNamedArgsForMake mapper expression
        ((arg, default, pattern, alias, pattern.ppat_loc, type_) :: list)
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
        "react.component refs only support plain arguments and type \
         annotations."
  | _ -> (list, None)

let argToType types (name, default, _noLabelName, _alias, loc, type_) =
  match (type_, name, default) with
  | ( Some { ptyp_desc = Ptyp_constr ({ txt = Lident "option" }, [ type_ ]) }
    , name
    , _ )
    when isOptional name ->
      ( getLabel name
      , []
      , { type_ with
          ptyp_desc =
            Ptyp_constr ({ loc = type_.ptyp_loc; txt = optionIdent }, [ type_ ])
        } )
      :: types
  | Some type_, name, Some _default ->
      ( getLabel name
      , []
      , { ptyp_desc = Ptyp_constr ({ loc; txt = optionIdent }, [ type_ ])
        ; ptyp_loc = loc
        ; ptyp_attributes = []
        ; ptyp_loc_stack = []
        } )
      :: types
  | Some type_, name, _ -> (getLabel name, [], type_) :: types
  | None, name, _ when isOptional name ->
      ( getLabel name
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
  | None, name, _ when isLabelled name ->
      ( getLabel name
      , []
      , { ptyp_desc = Ptyp_var (safeTypeFromValue name)
        ; ptyp_loc = loc
        ; ptyp_attributes = []
        ; ptyp_loc_stack = []
        } )
      :: types
  | _ -> types

let argToConcreteType types (name, loc, type_) =
  match name with
  | name when isLabelled name -> (getLabel name, [], type_) :: types
  | name when isOptional name ->
      (getLabel name, [], Typ.constr ~loc { loc; txt = optionIdent } [ type_ ])
      :: types
  | _ -> types

let process_value_binding ~loc valueBinding =
  if not (hasAttrOnBinding valueBinding) then valueBinding
  else
    let fileName = filenameFromLoc loc in
    let emptyLoc = Location.in_file fileName in
    let fnName = getFnName valueBinding in
    let bindingLoc = valueBinding.pvb_loc in
    let bindingPatLoc = valueBinding.pvb_pat.ppat_loc in
    let binding =
      { valueBinding with
        pvb_pat = { valueBinding.pvb_pat with ppat_loc = emptyLoc }
      ; pvb_loc = emptyLoc
      }
    in
    let hasApplication = ref false in
    let wrapExpressionWithBinding expressionFn expression =
      Vb.mk ~loc:bindingLoc
        ~attrs:(List.filter otherAttrsPure binding.pvb_attributes)
        (Pat.var ~loc:bindingPatLoc { loc = bindingPatLoc; txt = fnName })
        (expressionFn expression)
    in
    let expression = binding.pvb_expr in
    let unerasableIgnoreExp exp =
      { exp with
        pexp_attributes = unerasableIgnore emptyLoc :: exp.pexp_attributes
      }
    in
    (* TODO: there is a long-tail of unsupported features inside of blocks - Pexp_letmodule , Pexp_letexception , Pexp_ifthenelse *)
    let rec spelunkForFunExpression expression =
      match expression with
      (* let make = (~prop) => ... with no final unit *)
      | { pexp_desc =
            Pexp_fun
              ( ((Labelled _ | Optional _) as label)
              , default
              , pattern
              , ({ pexp_desc = Pexp_fun _ } as internalExpression) )
        } ->
          let wrap, hasUnit, exp = spelunkForFunExpression internalExpression in
          let expression =
            unerasableIgnoreExp
              { expression with
                pexp_desc = Pexp_fun (label, default, pattern, exp)
              }
          in
          (wrap, hasUnit, expression)
      (* let make = (()) => ... *)
      (* let make = (_) => ... *)
      | { pexp_desc =
            Pexp_fun
              ( Nolabel
              , _default
              , { ppat_desc =
                    Ppat_construct ({ txt = Lident "()" }, _) | Ppat_any
                }
              , _internalExpression )
        } ->
          ((fun a -> a), true, expression)
      (* let make = (~prop) => ... *)
      | { pexp_desc = Pexp_fun (label, default, pattern, internalExpression) }
        ->
          let unit_pattern =
            { ppat_desc =
                Ppat_construct ({ txt = Lident "()"; loc = emptyLoc }, None)
            ; ppat_loc = emptyLoc
            ; ppat_loc_stack = []
            ; ppat_attributes = []
            }
          in
          let expression =
            unerasableIgnoreExp
              { expression with
                pexp_desc =
                  Pexp_fun
                    ( label
                    , default
                    , pattern
                    , { pexp_loc = emptyLoc
                      ; pexp_desc =
                          Pexp_fun
                            (Nolabel, None, unit_pattern, internalExpression)
                      ; pexp_loc_stack = []
                      ; pexp_attributes = []
                      } )
              }
          in
          ((fun a -> a), false, unerasableIgnoreExp expression)
      (* let make = {let foo = bar in (~prop) => ...} *)
      | { pexp_desc = Pexp_let (recursive, vbs, internalExpression) } ->
          (* here's where we spelunk! *)
          let wrap, hasUnit, exp = spelunkForFunExpression internalExpression in
          ( wrap
          , hasUnit
          , { expression with pexp_desc = Pexp_let (recursive, vbs, exp) } )
      (* let make = React.forwardRef((~prop) => ...) *)
      | { pexp_desc =
            Pexp_apply (wrapperExpression, [ (Nolabel, internalExpression) ])
        } ->
          let () = hasApplication := true in
          let _, hasUnit, exp = spelunkForFunExpression internalExpression in
          ( (fun exp -> Exp.apply wrapperExpression [ (nolabel, exp) ])
          , hasUnit
          , exp )
      (* let make = React.memoCustomCompareProps((~prop) => ..., (prevPros, nextProps) => true) *)
      | { pexp_desc =
            Pexp_apply
              ( wrapperExpression
              , [ (Nolabel, internalExpression)
                ; ((Nolabel, { pexp_desc = Pexp_fun _ }) as compareProps)
                ] )
        } ->
          let () = hasApplication := true in
          let _, hasUnit, exp = spelunkForFunExpression internalExpression in
          ( (fun exp ->
              Exp.apply wrapperExpression [ (nolabel, exp); compareProps ])
          , hasUnit
          , exp )
      | { pexp_desc = Pexp_sequence (wrapperExpression, internalExpression) } ->
          let wrap, hasUnit, exp = spelunkForFunExpression internalExpression in
          ( wrap
          , hasUnit
          , { expression with
              pexp_desc = Pexp_sequence (wrapperExpression, exp)
            } )
      | e -> ((fun a -> a), false, e)
    in
    let wrapExpression, hasUnit, expression =
      spelunkForFunExpression expression
    in
    let _bindingWrapper, _hasUnit, expression =
      (wrapExpressionWithBinding wrapExpression, hasUnit, expression)
    in
    makeDeclaration ~loc fnName
      [ ( optional "key"
        , None
        , Pat.var { txt = "key"; loc = emptyLoc }
        , "key"
        , emptyLoc
        , Some (keyType emptyLoc) )
      ]
      expression

let makePropField ~loc id (arg_label, value) =
  let isOptional = isOptional arg_label in
  let name = getLabel arg_label in
  let prop =
    match DomProps.findByName id name with
    | Ok p -> p
    | Error err -> (
        match err with
        | `ElementNotFound ->
            raise
            @@ Location.raise_errorf ~loc
                 "HTML tag '%s' doesn't exist.\n\
                  If this isn't correct, please open an issue at %s" id
                 "https://github.com/ml-in-barcelona/server-reason-react/issues"
        | `AttributeNotFound ->
            let suggestion = DomProps.find_closest_name name in
            raise
            @@ Location.raise_errorf ~loc
                 "prop '%s' isn't valid on a '%s' element.\n\
                  Hint: Maybe you mean '%s'?\n\n\
                  If this isn't correct, please open an issue at %s. Meanwhile \
                  you could use `React.createElement`."
                 name id suggestion
                 "https://github.com/ml-in-barcelona/server-reason-react/issues"
        )
  in
  let jsxName = DomProps.getJSXName prop in
  let objectKey = Exp.constant ~loc (Pconst_string (jsxName, loc, None)) in
  let objectValue = makeValue ~isOptional ~loc prop value in
  match (prop, isOptional) with
  | Attribute { type_ = DomProps.String; _ }, false ->
      [%expr Some (React.Attribute.String ([%e objectKey], [%e objectValue]))]
  | Attribute { type_ = DomProps.String; _ }, true ->
      [%expr
        Option.map
          (fun v -> React.Attribute.String ([%e objectKey], v))
          [%e objectValue]]
  | Attribute { type_ = DomProps.Int; _ }, false ->
      [%expr
        Some
          (React.Attribute.String
             ([%e objectKey], string_of_int [%e objectValue]))]
  | Attribute { type_ = DomProps.Int; _ }, true ->
      [%expr
        Option.map
          (fun v -> React.Attribute.String ([%e objectKey], string_of_int v))
          [%e objectValue]]
  | Attribute { type_ = DomProps.Bool; _ }, false ->
      [%expr Some (React.Attribute.Bool ([%e objectKey], [%e objectValue]))]
  | Attribute { type_ = DomProps.Bool; _ }, true ->
      [%expr
        Option.map
          (fun v -> React.Attribute.Bool ([%e objectKey], v))
          [%e objectValue]]
  | Attribute { type_ = DomProps.Style; _ }, false ->
      [%expr Some (React.Attribute.Style [%e value])]
  | Attribute { type_ = DomProps.Style; _ }, true ->
      [%expr Option.map (fun v -> React.Attribute.Style v) [%e value]]
  | Attribute { type_ = DomProps.Ref; _ }, false ->
      [%expr Some (React.Attribute.Ref [%e value])]
  | Attribute { type_ = DomProps.Ref; _ }, true ->
      [%expr Option.map (fun v -> React.Attribute.Ref v) [%e value]]
  | Attribute { type_ = DomProps.InnerHtml; _ }, false -> (
      match value with
      (* Even thought we dont have bs.obj in OCaml, we do in Reason.
         We can extract the field __html and pass it to React.Attribute.DangerouslyInnerHtml *)
      | [%expr [%bs.obj { __html = [%e? inner] }]] ->
          [%expr Some (React.Attribute.DangerouslyInnerHtml [%e inner])]
      | _ ->
          raise
          @@ Location.raise_errorf ~loc
               "unexpected expression found on dangerouslySetInnerHTML")
  | Attribute { type_ = DomProps.InnerHtml; _ }, true -> (
      match value with
      (* Even thought we dont have bs.obj in OCaml, we do in Reason.
         We can extract the field __html and pass it to React.Attribute.DangerouslyInnerHtml *)
      | [%expr [%bs.obj { __html = [%e? inner] }]] ->
          [%expr
            Option.map
              (fun v -> React.Attribute.DangerouslyInnerHtml v)
              [%e inner]]
      | _ ->
          raise
          @@ Location.raise_errorf ~loc
               "unexpected expression found on dangerouslySetInnerHTML")
  | Event { type_ = Mouse; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ([%e constantString ~loc name], React.EventT.Mouse [%e objectValue]))]
  | Event { type_ = Mouse; name }, true ->
      [%expr
        Option.map
          (fun v ->
            React.Attribute.Event
              ([%e constantString ~loc name], React.EventT.Mouse v))
          [%e objectValue]]
  | Event { type_ = Selection; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ( [%e constantString ~loc name]
             , React.EventT.Selection [%e objectValue] ))]
  | Event { type_ = Selection; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Selection v))
              [%e objectValue])]
  | Event { type_ = Touch; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ([%e constantString ~loc name], React.EventT.Touch [%e objectValue]))]
  | Event { type_ = Touch; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Touch v))
              [%e objectValue])]
  | Event { type_ = UI; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ([%e constantString ~loc name], React.EventT.UI [%e objectValue]))]
  | Event { type_ = UI; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.UI v))
              [%e objectValue])]
  | Event { type_ = Wheel; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ([%e constantString ~loc name], React.EventT.Wheel [%e objectValue]))]
  | Event { type_ = Wheel; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Wheel v))
              [%e objectValue])]
  | Event { type_ = Clipboard; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ( [%e constantString ~loc name]
             , React.EventT.Clipboard [%e objectValue] ))]
  | Event { type_ = Clipboard; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Clipboard v))
              [%e objectValue])]
  | Event { type_ = Composition; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ( [%e constantString ~loc name]
             , React.EventT.Composition [%e objectValue] ))]
  | Event { type_ = Composition; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Composition v))
              [%e objectValue])]
  | Event { type_ = Keyboard; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ([%e constantString ~loc name], React.EventT.Keyboard v))]
  | Event { type_ = Keyboard; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Keyboard v))
              [%e objectValue])]
  | Event { type_ = Focus; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ([%e constantString ~loc name], React.EventT.Focus [%e objectValue]))]
  | Event { type_ = Focus; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Focus v))
              [%e objectValue])]
  | Event { type_ = Form; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ([%e constantString ~loc name], React.EventT.Form [%e objectValue]))]
  | Event { type_ = Form; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Form v))
              [%e objectValue])]
  | Event { type_ = Media; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ([%e constantString ~loc name], React.EventT.Media [%e objectValue]))]
  | Event { type_ = Media; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Media v))
              [%e objectValue])]
  | Event { type_ = Inline; name }, false ->
      [%expr
        Some
          (React.Attribute.Event
             ( [%e constantString ~loc name]
             , React.EventT.Inline [%e objectValue] ))]
  | Event { type_ = Inline; name }, true ->
      [%expr
        Option.map (fun v ->
            (React.Attribute.Event
               ([%e constantString ~loc name], React.EventT.Inline v))
              [%e objectValue])]
  | _ -> failwith "Attribute not implemented, open an issue"

let jsxMapper () =
  let transformUppercaseCall modulePath mapper loc attrs _ callArguments =
    let childrenExpr, argsWithLabels =
      extractChildren ~loc ~removeLastPositionUnit:true callArguments
    in
    let modifiedChildrenExpr =
      transformChildrenIfListUpper ~loc ~mapper childrenExpr
    in
    let recursivelyTransformedArgsForMake =
      argsWithLabels
      |> List.map (fun (label, expression) ->
             (label, mapper#expression expression))
    in
    let args =
      recursivelyTransformedArgsForMake
      @ (match modifiedChildrenExpr with
        | Exact children -> [ (labelled "children", [%expr [%e children]]) ]
        | ListLiteral [%expr []] -> []
        | ListLiteral expression -> [ (labelled "children", expression) ])
      @ [ (nolabel, Exp.construct ~loc { loc; txt = Lident "()" } None) ]
    in
    let identifier =
      match modulePath with
      | Lident _ -> Ldot (modulePath, "make")
      | Ldot (_modulePath, value) as fullPath when isCap value ->
          Ldot (fullPath, "make")
      | modulePath -> modulePath
    in
    let makeFnIdentifier =
      match identifier with
      | Lident path -> Lident path
      | Ldot (ident, path) -> Ldot (ident, path)
      | _ ->
          raise
            (Invalid_argument
               "JSX name can't be the result of function applications")
    in
    Exp.apply ~attrs ~loc (Exp.ident ~loc { loc; txt = makeFnIdentifier }) args
  in
  let transformLowercaseCall ~loc mapper attrs callArguments id callLoc =
    let children, nonChildrenProps =
      extractChildren ~loc ~removeLastPositionUnit:true callArguments
    in
    let createElementCall =
      match children with
      (* [@JSX] div(~children=[a]), coming from <div> a </div> *)
      | { pexp_desc =
            ( Pexp_construct
                ({ txt = Lident "::" }, Some { pexp_desc = Pexp_tuple _ })
            | Pexp_construct ({ txt = Lident "[]" }, None) )
        } ->
          "createElement"
      (* [@JSX] div(~children= value), coming from <div> ...(value) </div> *)
      | _ ->
          raise
            (Invalid_argument
               "A spread as a DOM element's children don't make sense written \
                together. You can simply remove the spread.")
    in
    let args =
      let componentNameExpr = constantString ~loc id in
      let propsObj =
        [%expr
          [%e
            Exp.array ~loc
              (List.map (makePropField ~loc:callLoc id) nonChildrenProps)]
          |> Array.to_list
          |> List.filter_map (fun a -> a)
          |> Array.of_list]
      in
      [ (* "div" *)
        (nolabel, componentNameExpr)
      ; (* [React.Attribute.String("key", "value")] *)
        (nolabel, propsObj)
      ; (* [|children aka moreCreateElementCallsHere|] *)
        (nolabel, mapper#expression children)
      ]
    in
    Exp.apply
      ~loc (* throw away the [@JSX] attribute and keep the others, if any *)
      ~attrs
      (* React.createElement *)
      (Exp.ident ~loc { loc; txt = Ldot (Lident "React", createElementCall) })
      args
  in
  let nestedModules = ref [] in
  let transformComponentDefinition _mapper structure returnStructures =
    match structure with
    (* external *)
    | { pstr_loc
      ; pstr_desc =
          Pstr_primitive
            ({ pval_name = { txt = fnName }; pval_attributes; pval_type } as
            value_description)
      } as pstr -> (
        match List.filter hasAttr pval_attributes with
        | [] -> structure :: returnStructures
        | [ _ ] ->
            let rec getPropTypes types ({ ptyp_loc; ptyp_desc } as fullType) =
              match ptyp_desc with
              | Ptyp_arrow (name, type_, ({ ptyp_desc = Ptyp_arrow _ } as rest))
                when isLabelled name || isOptional name ->
                  getPropTypes ((name, ptyp_loc, type_) :: types) rest
              | Ptyp_arrow (Nolabel, _type, rest) -> getPropTypes types rest
              | Ptyp_arrow (name, type_, returnValue)
                when isLabelled name || isOptional name ->
                  (returnValue, (name, returnValue.ptyp_loc, type_) :: types)
              | _ -> (fullType, types)
            in
            let innerType, propTypes = getPropTypes [] pval_type in
            let namedTypeList = List.fold_left argToConcreteType [] propTypes in
            let pluckLabelAndLoc (label, loc, type_) =
              (label, None (* default *), loc, Some type_)
            in
            let retPropsType = makePropsType ~loc:pstr_loc namedTypeList in
            let loc = pstr_loc in
            let externalPropsDecl =
              makeStructure ~loc:pstr_loc fnName
                ((Optional "key", None, pstr_loc, Some (keyType pstr_loc))
                :: List.map pluckLabelAndLoc propTypes)
                [%expr "TODO: externals"]
            in
            (* can't be an arrow because it will defensively uncurry *)
            let newExternalType =
              Ptyp_constr
                ( { loc = pstr_loc
                  ; txt = Ldot (Lident "React", "componentLike")
                  }
                , [ retPropsType; innerType ] )
            in
            let newStructure =
              { pstr with
                pstr_desc =
                  Pstr_primitive
                    { value_description with
                      pval_type = { pval_type with ptyp_desc = newExternalType }
                    ; pval_attributes =
                        List.filter otherAttrsPure pval_attributes
                    }
              }
            in
            externalPropsDecl :: newStructure :: returnStructures
        | _ ->
            raise
              (Invalid_argument
                 "Only one react.component call can exist on a component at \
                  one time"))
    (* let component = ... *)
    | { pstr_loc; pstr_desc = Pstr_value (rec_flag, value_bindings) } ->
        let bindings =
          List.map (process_value_binding ~loc:pstr_loc) value_bindings
        in
        [ { pstr_loc; pstr_desc = Pstr_value (rec_flag, bindings) } ]
        @ returnStructures
    | structure -> structure :: returnStructures
  in
  let reactComponentTransform mapper structures =
    List.fold_right (transformComponentDefinition mapper) structures []
  in
  let transformComponentSignature _mapper signature returnSignatures =
    match signature with
    | { psig_loc
      ; psig_desc =
          Psig_value
            ({ pval_name = { txt = fnName }; pval_attributes; pval_type } as
            psig_desc)
      } as psig -> (
        match List.filter hasAttr pval_attributes with
        | [] -> signature :: returnSignatures
        | [ _ ] ->
            let rec getPropTypes types ({ ptyp_loc; ptyp_desc } as fullType) =
              match ptyp_desc with
              | Ptyp_arrow (name, type_, ({ ptyp_desc = Ptyp_arrow _ } as rest))
                when isOptional name || isLabelled name ->
                  getPropTypes ((name, ptyp_loc, type_) :: types) rest
              | Ptyp_arrow (Nolabel, _type, rest) -> getPropTypes types rest
              | Ptyp_arrow (name, type_, returnValue)
                when isOptional name || isLabelled name ->
                  (returnValue, (name, returnValue.ptyp_loc, type_) :: types)
              | _ -> (fullType, types)
            in
            let innerType, propTypes = getPropTypes [] pval_type in
            let namedTypeList = List.fold_left argToConcreteType [] propTypes in
            let pluckLabelAndLoc (label, loc, type_) =
              (label, None, loc, Some type_)
            in
            let retPropsType = makePropsType ~loc:psig_loc namedTypeList in
            let externalPropsDecl =
              makePropsExternalSig fnName psig_loc
                ((optional "key", None, psig_loc, Some (keyType psig_loc))
                :: List.map pluckLabelAndLoc propTypes)
                retPropsType
            in
            (* can't be an arrow because it will defensively uncurry *)
            let newExternalType =
              Ptyp_constr
                ( { loc = psig_loc
                  ; txt = Ldot (Lident "React", "componentLike")
                  }
                , [ retPropsType; innerType ] )
            in
            let newStructure =
              { psig with
                psig_desc =
                  Psig_value
                    { psig_desc with
                      pval_type = { pval_type with ptyp_desc = newExternalType }
                    ; pval_attributes =
                        List.filter otherAttrsPure pval_attributes
                    }
              }
            in
            externalPropsDecl :: newStructure :: returnSignatures
        | _ ->
            raise
              (Invalid_argument
                 "Only one react.component call can exist on a component at \
                  one time"))
    | signature -> signature :: returnSignatures
  in
  let reactComponentSignatureTransform mapper signatures =
    List.fold_right (transformComponentSignature mapper) signatures []
  in
  let transformJsxCall mapper callExpression callArguments attrs applyLoc =
    match callExpression.pexp_desc with
    | Pexp_ident caller -> (
        match caller with
        | { txt = Lident "createElement" } ->
            raise
              (Invalid_argument
                 "JSX: `createElement` should be preceeded by a module name.")
        (* Foo.createElement(~prop1=foo, ~prop2=bar, ~children=[], ()) *)
        | { loc; txt = Ldot (modulePath, ("createElement" | "make")) } ->
            transformUppercaseCall modulePath mapper loc attrs callExpression
              callArguments
        (* div(~prop1=foo, ~prop2=bar, ~children=[bla], ()) *)
        (* turn that into
           ReactDom.createElement(~props=ReactDom.props(~props1=foo, ~props2=bar, ()), [|bla|]) *)
        | { loc; txt = Lident id } ->
            transformLowercaseCall ~loc mapper attrs callArguments id applyLoc
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

  object (mapper)
    inherit Ast_traverse.map as super

    method! signature signature =
      super#signature @@ reactComponentSignatureTransform mapper signature

    method! structure structure =
      match structure with
      | structures ->
          super#structure @@ reactComponentTransform mapper structures

    method! expression expression =
      match expression with
      (* Does the function application have the @JSX attribute? *)
      | { pexp_desc = Pexp_apply (callExpression, callArguments)
        ; pexp_attributes
        ; pexp_loc = applyLoc
        } -> (
          let jsxAttribute, nonJSXAttributes =
            List.partition
              (fun attribute -> attribute.attr_name.txt = "JSX")
              pexp_attributes
          in
          match (jsxAttribute, nonJSXAttributes) with
          (* no JSX attribute *)
          | [], _ -> super#expression expression
          | _, nonJSXAttributes ->
              transformJsxCall mapper callExpression callArguments
                nonJSXAttributes applyLoc)
      (* is it a list with jsx attribute? Reason <>foo</> desugars to [@JSX][foo]*)
      | { pexp_desc =
            ( Pexp_construct
                ({ txt = Lident "::"; loc }, Some { pexp_desc = Pexp_tuple _ })
            | Pexp_construct ({ txt = Lident "[]"; loc }, None) )
        ; pexp_attributes
        } as listItems -> (
          let jsxAttribute, nonJSXAttributes =
            List.partition
              (fun attribute -> attribute.attr_name.txt = "JSX")
              pexp_attributes
          in
          match (jsxAttribute, nonJSXAttributes) with
          (* no JSX attribute *)
          | [], _ -> super#expression expression
          | _, _nonJSXAttributes ->
              let reactFragmentMake =
                { pexp_desc =
                    Pexp_ident
                      { txt = Longident.parse "React.Fragment.make"; loc }
                ; pexp_attributes = []
                ; pexp_loc = loc
                ; pexp_loc_stack = []
                }
              in
              Exp.apply
                ~loc
                  (* throw away the [@JSX] attribute and keep the others, if any *)
                ~attrs:nonJSXAttributes reactFragmentMake
                [ (Labelled "children", super#expression listItems)
                ; (nolabel, Exp.construct ~loc { loc; txt = Lident "()" } None)
                ])
      (* Delegate to the default mapper, a deep identity traversal *)
      | e -> super#expression e

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

let rewrite_implementation code =
  let mapper = jsxMapper () in
  mapper#structure code

let rewrite_signature code =
  let mapper = jsxMapper () in
  mapper#signature code

let () =
  Driver.register_transformation "native-react-ppx" ~impl:rewrite_implementation
    ~intf:rewrite_signature
