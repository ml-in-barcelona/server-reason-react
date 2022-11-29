type domRef

open Webapi

module Ref = struct
  type t = domRef
  type currentDomRef = Dom.element Js.nullable ref
  type callbackDomRef

  external domRef : currentDomRef -> domRef = "%identity"
  external callbackDomRef : callbackDomRef -> domRef = "%identity"
end

let createRef () = ref None
let useRef value = ref value
let forwardRef f = f ()

(* Self referencing modules to have recursive type records without collission *)
module rec Lower_case_element : sig
  type t =
    { tag : string
    ; attributes : Attribute.t array
    ; children : Element.t list
    }
end =
  Lower_case_element

and Lower_case_closed_element : sig
  type t =
    { tag : string
    ; attributes : Attribute.t array
    }
end =
  Lower_case_closed_element

and Element : sig
  type t =
    | Lower_case_element of Lower_case_element.t
    | Lower_case_closed_element of Lower_case_closed_element.t
    | Upper_case_element of (unit -> t)
    | List of t array
    | Text of string
    | Fragment of t list
    | Empty
    | Provider of (unit -> t) list
    | Consumer of (unit -> t list)
end =
  Element

and EventT : sig
  type t =
    (* | Drag of Event.Drag.t *)
    | Mouse of (ReactEvent.Mouse.t -> unit)
    | Selection of (ReactEvent.Selection.t -> unit)
    | Touch of (ReactEvent.Touch.t -> unit)
    | UI of (ReactEvent.UI.t -> unit)
    | Wheel of (ReactEvent.Wheel.t -> unit)
    | Clipboard of (ReactEvent.Clipboard.t -> unit)
    | Composition of (ReactEvent.Composition.t -> unit)
    | Keyboard of (ReactEvent.Keyboard.t -> unit)
    | Focus of (ReactEvent.Focus.t -> unit)
    | Form of (ReactEvent.Form.t -> unit)
    | Media of (ReactEvent.Media.t -> unit)
end =
  EventT

and Attribute : sig
  type t =
    | Bool of (string * bool)
    | String of (string * string)
    | Style of string
    | DangerouslyInnerHtml of string
    | Ref of Ref.t
    | Event of string * EventT.t
end =
  Attribute

and Fragment : sig
  type t = Element.t list

  val make : children:t -> unit -> Element.t
end = struct
  type t = Element.t list

  let make ~children () = Element.Fragment children
end

let is_self_closing_tag = function
  (* https://github.com/facebook/react/blob/97d75c9c8bcddb0daed1ed062101c7f5e9b825f4/packages/react-dom-bindings/src/shared/omittedCloseTags.js *)
  | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link"
  | "meta" | "param" | "source" | "track" | "wbr" (* | "menuitem" *) ->
      true
  | _ -> false

exception Invalid_children of string

let compare_attribute left right =
  let open Attribute in
  match (left, right) with
  | Bool (left_key, _), Bool (right_key, _) -> String.compare left_key right_key
  | String (left_key, _), String (right_key, _) ->
      String.compare left_key right_key
  | Style left_styles, Style right_styles ->
      String.compare left_styles right_styles
  | _ -> 0

let clone_attribute acc attr new_attr =
  let open Attribute in
  match (attr, new_attr) with
  | Bool (left, _), Bool (right, value) when left == right ->
      Bool (left, value) :: acc
  | String (left, _), String (right, value) when left == right ->
      String (left, value) :: acc
  | _ -> new_attr :: acc

module StringMap = Map.Make (String)

type attributes = Attribute.t StringMap.t

let attributes_to_map attrs =
  Array.fold_left
    (fun acc attr ->
      match attr with
      | Attribute.Bool (key, value) ->
          acc |> StringMap.add key (Attribute.Bool (key, value))
      | Attribute.String (key, value) ->
          acc |> StringMap.add key (Attribute.String (key, value))
      (* We don't add to the Map, the following constructors: *)
      | Attribute.DangerouslyInnerHtml _ -> acc
      | Attribute.Ref _ -> acc
      | Attribute.Event _ -> acc
      | Attribute.Style _ -> acc)
    StringMap.empty attrs

let clone_attributes (attributes : 'a array) new_attributes =
  let attribute_map = attributes_to_map attributes in
  let new_attribute_map = attributes_to_map new_attributes in
  StringMap.merge
    (fun _key attr new_attr ->
      match (attr, new_attr) with
      | Some attr, Some new_attr -> Some (clone_attribute [] attr new_attr)
      | Some attr, None -> Some [ attr ]
      | None, Some new_attr -> Some [ new_attr ]
      | None, None -> None)
    attribute_map new_attribute_map
  |> StringMap.bindings
  |> List.map (fun (_, attrs) -> attrs)
  |> List.flatten |> List.rev
  |> List.sort compare_attribute
  |> Array.of_list

let create_element_inner tag attributes children =
  let dangerouslySetInnerHTML =
    Array.find_opt
      (function Attribute.DangerouslyInnerHtml _ -> true | _ -> false)
      attributes
  in
  let children =
    match (dangerouslySetInnerHTML, children) with
    | None, children -> children
    | Some (Attribute.DangerouslyInnerHtml innerHtml), [] ->
        [ Element.Text innerHtml ]
    | Some _, _children -> raise (Invalid_children tag)
  in
  Element.Lower_case_element { tag; attributes; children }

let createElement tag attributes children =
  match is_self_closing_tag tag with
  | true when List.length children > 0 ->
      (* TODO: Add test for this *)
      (* Q: should raise or return monad? *)
      raise @@ Invalid_children "closing tag with children isn't valid"
  | true -> Element.Lower_case_closed_element { tag; attributes }
  | false -> create_element_inner tag attributes children

(* cloneElements overrides childrens *)
let cloneElement element new_attributes new_childrens =
  let open Element in
  match element with
  | Lower_case_element { tag; attributes; children = _ } ->
      Lower_case_element
        { tag
        ; attributes = clone_attributes attributes new_attributes
        ; children = new_childrens
        }
  | Lower_case_closed_element { tag; attributes } ->
      Lower_case_closed_element
        { tag; attributes = clone_attributes attributes new_attributes }
  | Fragment _childrens -> Fragment new_childrens
  | Text t -> Text t
  | Empty -> Empty
  | List l -> List l
  | Provider child -> Provider child
  | Consumer child -> Consumer child
  | Upper_case_element f -> Upper_case_element f

let createElementVariadic tag ~props children = createElement tag props children
let memo f _compare : 'props * 'props -> bool = f

type 'a context =
  { current_value : 'a ref
  ; provider : value:'a -> children:(unit -> Element.t) list -> Element.t
  ; consumer : children:('a -> Element.t list) -> Element.t
  }

let createContext (initial_value : 'a) : 'a context =
  let ref_value = ref initial_value in
  let provider ~value ~children =
    ref_value.contents <- value;
    Element.Provider children
  in
  let consumer ~children =
    Element.Consumer (fun () -> children ref_value.contents)
  in
  { current_value = ref_value; provider; consumer }

let useContext context = context.current_value.contents

let useState (make_initial_value : unit -> 'state) =
  let initial_value : 'state = make_initial_value () in
  let setState (fn : 'state -> 'state) =
    let _ = fn initial_value in
    ()
  in
  (initial_value, setState)

let useMemo fn = fn ()
let useMemo1 fn _ = fn ()
let useMemo2 fn _ = fn ()
let useMemo3 fn _ = fn ()
let useMemo4 fn _ = fn ()
let useMemo5 fn _ = fn ()
let useMemo6 fn _ = fn ()
let useCallback fn = fn
let useCallback1 fn _ = fn
let useCallback2 fn _ = fn
let useCallback3 fn _ = fn
let useCallback4 fn _ = fn
let useCallback5 fn _ = fn
let useCallback6 (fn : 'a -> 'b) = fn

let useReducer :
    ('state -> 'action -> 'state) -> 'state -> 'state * ('action -> unit) =
 fun _ s -> (s, fun _ -> ())

let useEffect0 : (unit -> (unit -> unit) option) -> unit = fun _ -> ()

let useEffect1 : (unit -> (unit -> unit) option) -> 'dependency array -> unit =
 fun _ _ -> ()

let useEffect2 :
    (unit -> (unit -> unit) option) -> 'dependency1 * 'dependency2 -> unit =
 fun _ _ -> ()

let useEffect3 :
       (unit -> (unit -> unit) option)
    -> 'dependency1 * 'dependency2 * 'dependency3
    -> unit =
 fun _ _ -> ()

let useEffect4 :
       (unit -> (unit -> unit) option)
    -> 'dependency1 * 'dependency2 * 'dependency3 * 'dependency4
    -> unit =
 fun _ _ -> ()

let useEffect5 :
       (unit -> (unit -> unit) option)
    -> 'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 * 'dependency5
    -> unit =
 fun _ _ -> ()

let useEffect6 :
       (unit -> (unit -> unit) option)
    -> 'dependency1
       * 'dependency2
       * 'dependency3
       * 'dependency4
       * 'dependency5
       * 'dependency6
    -> unit =
 fun _ _ -> ()

(* ReasonReact APIs *)
let string txt = Element.Text txt
let null = Element.Empty
let int i = Element.Text (string_of_int i)

(* FIXME: float_of_string might be different on the browser *)
let float f = Element.Text (string_of_float f)
let array arr = Element.List arr

let list_to_array list =
  let rec to_array i res =
    match i < 0 with
    | true -> res
    | false ->
        let item = List.nth list i in
        let rest = Array.append [| item |] res in
        to_array (i - 1) rest
  in
  to_array (List.length list - 1) [||]

let list l = Element.List (list_to_array l)
