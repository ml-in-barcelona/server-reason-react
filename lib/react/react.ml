type domRef

module Ref = struct
  type t = domRef
  type currentDomRef = Webapi.Dom.element Js.nullable ref
  type callbackDomRef

  external domRef : currentDomRef -> domRef = "%identity"
  external callbackDomRef : callbackDomRef -> domRef = "%identity"
end

let createRef () = ref None
let useRef value = ref value
let forwardRef f = f ()

module Attribute = struct
  module Event = struct
    type t =
      | Drag of (ReactEvent.Drag.t -> unit)
      | Mouse of (ReactEvent.Mouse.t -> unit)
      | Selection of (ReactEvent.Selection.t -> unit)
      | Touch of (ReactEvent.Touch.t -> unit)
      | UI of (ReactEvent.UI.t -> unit)
      | Wheel of (ReactEvent.Wheel.t -> unit)
      | Clipboard of (ReactEvent.Clipboard.t -> unit)
      | Composition of (ReactEvent.Composition.t -> unit)
      | Transition of (ReactEvent.Transition.t -> unit)
      | Animation of (ReactEvent.Animation.t -> unit)
      | Pointer of (ReactEvent.Pointer.t -> unit)
      | Keyboard of (ReactEvent.Keyboard.t -> unit)
      | Focus of (ReactEvent.Focus.t -> unit)
      | Form of (ReactEvent.Form.t -> unit)
      | Media of (ReactEvent.Media.t -> unit)
      | Inline of string
  end

  type t =
    | Bool of (string * bool)
    | String of (string * string)
    | Style of string
    | DangerouslyInnerHtml of string
    | Ref of Ref.t
    | Event of string * Event.t
end

type lower_case_element = {
  tag : string;
  attributes : Attribute.t array;
  children : element list;
}

and element =
  | Lower_case_element of lower_case_element
  | Upper_case_component of (unit -> element)
  | List of element array
  | Text of string
  | InnerHtml of string
  | Fragment of element
  | Empty
  | Provider of (unit -> element) list
  | Consumer of (unit -> element list)

exception Invalid_children of string

let compare_attribute left right =
  match (left, right) with
  | Attribute.Bool (left_key, _), Attribute.Bool (right_key, _) ->
      String.compare left_key right_key
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

let attributes_to_map (attributes : Attribute.t array) =
  let open Attribute in
  Array.fold_left
    (fun acc attr ->
      match attr with
      | Bool (key, value) -> acc |> StringMap.add key (Bool (key, value))
      | String (key, value) -> acc |> StringMap.add key (String (key, value))
      (* The following constructors shoudn't be part of the Map: *)
      | DangerouslyInnerHtml _ -> acc
      | Ref _ -> acc
      | Event _ -> acc
      | Style _ -> acc)
    StringMap.empty attributes

let clone_attributes (attributes : Attribute.t array) new_attributes =
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
        (* This adds as children the innerHTML, and we treat it differently
           from Element.Text to avoid encoding to HTML their content *)
        [ InnerHtml innerHtml ]
    | Some _, _children -> raise (Invalid_children tag)
  in
  Lower_case_element { tag; attributes; children }

let createElement tag attributes children =
  match Html.is_self_closing_tag tag with
  | true when List.length children > 0 ->
      (* TODO: Add test for this *)
      raise @@ Invalid_children "closing tag with children isn't valid"
  | true -> Lower_case_element { tag; attributes; children = [] }
  | false -> create_element_inner tag attributes children

(* cloneElements overrides childrens *)
let cloneElement element new_attributes new_childrens =
  match element with
  | Lower_case_element { tag; attributes; children = _ } ->
      Lower_case_element
        {
          tag;
          attributes = clone_attributes attributes new_attributes;
          children = new_childrens;
        }
  | Fragment _childrens -> Fragment _childrens
  | Text t -> Text t
  | InnerHtml t -> InnerHtml t
  | Empty -> Empty
  | List l -> List l
  | Provider child -> Provider child
  | Consumer child -> Consumer child
  | Upper_case_component f -> Upper_case_component f

let fragment ~children () = Fragment children

(* ReasonReact APIs *)
let string txt = Text txt
let null = Empty
let int i = Text (string_of_int i)

(* FIXME: float_of_string might be different from the browser *)
let float f = Text (string_of_float f)
let array arr = List arr

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

let list l = List (list_to_array l)

type 'a context = {
  current_value : 'a ref;
  provider : value:'a -> children:(unit -> element) list -> element;
  consumer : children:('a -> element list) -> element;
}

let createContext (initial_value : 'a) : 'a context =
  let ref_value = ref initial_value in
  let provider ~value ~children =
    ref_value.contents <- value;
    Provider children
  in
  let consumer ~children = Consumer (fun () -> children ref_value.contents) in
  { current_value = ref_value; provider; consumer }

(* let memo f : 'props * 'props -> bool = f
   let memoCustomCompareProps f _compare : 'props * 'props -> bool = f *)

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
    (unit -> (unit -> unit) option) ->
    'dependency1 * 'dependency2 * 'dependency3 ->
    unit =
 fun _ _ -> ()

let useEffect4 :
    (unit -> (unit -> unit) option) ->
    'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 ->
    unit =
 fun _ _ -> ()

let useEffect5 :
    (unit -> (unit -> unit) option) ->
    'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 * 'dependency5 ->
    unit =
 fun _ _ -> ()

let useEffect6 :
    (unit -> (unit -> unit) option) ->
    'dependency1
    * 'dependency2
    * 'dependency3
    * 'dependency4
    * 'dependency5
    * 'dependency6 ->
    unit =
 fun _ _ -> ()

let useLayoutEffect0 : (unit -> (unit -> unit) option) -> unit = fun _ -> ()

let useLayoutEffect1 :
    (unit -> (unit -> unit) option) -> 'dependency array -> unit =
 fun _ _ -> ()

let useLayoutEffect2 :
    (unit -> (unit -> unit) option) -> 'dependency1 * 'dependency2 -> unit =
 fun _ _ -> ()

let useLayoutEffect3 :
    (unit -> (unit -> unit) option) ->
    'dependency1 * 'dependency2 * 'dependency3 ->
    unit =
 fun _ _ -> ()

let useLayoutEffect4 :
    (unit -> (unit -> unit) option) ->
    'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 ->
    unit =
 fun _ _ -> ()

let useLayoutEffect5 :
    (unit -> (unit -> unit) option) ->
    'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 * 'dependency5 ->
    unit =
 fun _ _ -> ()

let useLayoutEffect6 :
    (unit -> (unit -> unit) option) ->
    'dependency1
    * 'dependency2
    * 'dependency3
    * 'dependency4
    * 'dependency5
    * 'dependency6 ->
    unit =
 fun _ _ -> ()

let setDisplayName : 'component -> string -> unit = fun _ _ -> ()

module Children = struct
  let map fn elements = Array.map fn elements
  let mapWithIndex fn elements = Array.mapi fn elements
  let forEach fn elements = Array.iter fn elements
  let forEachWithIndex fn elements = Array.iteri fn elements
  let count elements = Array.length elements

  let only elements =
    if Array.length elements >= 1 then Array.get elements 0
    else raise (Invalid_argument "Expected at least one child")

  let toArray element = [| element |]
end
