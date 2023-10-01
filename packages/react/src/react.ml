type domRef

module Dom = struct
  type element
end

type 'value ref = { mutable current : 'value }

module Ref = struct
  type t = domRef
  type currentDomRef = Dom.element Js.nullable ref
  type callbackDomRef

  external domRef : currentDomRef -> domRef = "%identity"
  external callbackDomRef : callbackDomRef -> domRef = "%identity"
end

let createRef () = { current = None }
let useRef value = { current = value }
let forwardRef f = f ()

module JSX = struct
  type event =
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

  type prop =
    | Bool of (string * bool)
    | String of (string * string)
    | Style of string
    | DangerouslyInnerHtml of string
    | Ref of Ref.t
    | Event of string * event

  let bool key value = Bool (key, value)
  let string key value = String (key, value)
  let style value = Style value
  let int key value = String (key, string_of_int value)
  let float key value = String (key, string_of_float value)
  let dangerouslyInnerHtml value = DangerouslyInnerHtml value
  let ref value = Ref value
  let event key value = Event (key, value)

  module Event = struct
    let drag key value = event key (Drag value)
    let mouse key value = event key (Mouse value)
    let selection key value = event key (Selection value)
    let touch key value = event key (Touch value)
    let ui key value = event key (UI value)
    let wheel key value = event key (Wheel value)
    let clipboard key value = event key (Clipboard value)
    let composition key value = event key (Composition value)
    let transition key value = event key (Transition value)
    let animation key value = event key (Animation value)
    let pointer key value = event key (Pointer value)
    let keyboard key value = event key (Keyboard value)
    let focus key value = event key (Focus value)
    let form key value = event key (Form value)
    let media key value = event key (Media value)
  end
end

type lower_case_element = {
  tag : string;
  attributes : JSX.prop array;
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
  | Provider of element
  | Consumer of element
  | Suspense of { children : element; fallback : element }

exception Invalid_children of string

let compare_attribute left right =
  match (left, right) with
  | JSX.Bool (left_key, _), JSX.Bool (right_key, _) ->
      String.compare left_key right_key
  | String (left_key, _), String (right_key, _) ->
      String.compare left_key right_key
  | Style left_styles, Style right_styles ->
      String.compare left_styles right_styles
  | _ -> 0

let clone_attribute acc attr new_attr =
  let open JSX in
  match (attr, new_attr) with
  | Bool (left, _), Bool (right, value) when left == right ->
      Bool (left, value) :: acc
  | String (left, _), String (right, value) when left == right ->
      String (left, value) :: acc
  | _ -> new_attr :: acc

module StringMap = Map.Make (String)

let attributes_to_map (attributes : JSX.prop array) =
  let open JSX in
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

let clone_attributes (attributes : JSX.prop array) new_attributes =
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
      (function JSX.DangerouslyInnerHtml _ -> true | _ -> false)
      attributes
  in
  let children =
    match (dangerouslySetInnerHTML, children) with
    | None, children -> children
    | Some (JSX.DangerouslyInnerHtml innerHtml), [] ->
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

(* cloneElements overrides childrens but is not always obvious what to do with
   Provider, Consumer or Suspense. TODO: Check original (JS) implementation *)
let cloneElement element new_attributes =
  match element with
  | Lower_case_element { tag; attributes; children } ->
      Lower_case_element
        {
          tag;
          attributes = clone_attributes attributes new_attributes;
          children;
        }
  | Fragment _childrens -> Fragment _childrens
  | Text t -> Text t
  | InnerHtml t -> InnerHtml t
  | Empty -> Empty
  | List l -> List l
  | Provider child -> Provider child
  | Consumer child -> Consumer child
  | Upper_case_component f -> Upper_case_component f
  | Suspense { fallback; children } -> Suspense { fallback; children }

module Fragment = struct
  let make ~children () = Fragment children
end

let fragment ~children () = Fragment.make ~children ()

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

type 'a provider = value:'a -> children:element -> unit -> element

type 'a context = {
  current_value : 'a ref;
  provider : 'a provider;
  consumer : children:element -> element;
}

module Context = struct
  type 'a t = 'a context

  let provider ctx = ctx.provider
end

let createContext (initial_value : 'a) : 'a Context.t =
  let ref_value = { current = initial_value } in
  let provider ~value ~children () =
    ref_value.current <- value;
    Provider children
  in
  let consumer ~children = Consumer children in
  { current_value = ref_value; provider; consumer }

module Suspense = struct
  let or_react_null = function None -> null | Some x -> x

  let make ?fallback ?children () =
    Suspense
      { fallback = or_react_null fallback; children = or_react_null children }
end

(* let memo f : 'props * 'props -> bool = f
   let memoCustomCompareProps f _compare : 'props * 'props -> bool = f *)

(* `exception Suspend of 'a Lwt`
    exceptions can't have type params, this is called existential wrapper *)
type any_promise = Any_promise : 'a Lwt.t -> any_promise

exception Suspend of any_promise

let use promise =
  match Lwt.state promise with
  | Sleep -> raise (Suspend (Any_promise promise))
  (* TODO: Fail should raise a FailedSupense and catch at renderTo* *)
  | Fail e -> raise e
  | Return v -> v

let useContext context = context.current_value.current

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
