type domRef

module Dom = struct
  (* TODO: This should point to Dom.element from melange.dom, but melange.dom isn't compatible with native yet. https://github.com/melange-re/melange/pull/756 *)
  type element
end

type 'value ref = { mutable current : 'value }

module Ref = struct
  type t = domRef
  type currentDomRef = Dom.element Js.nullable ref
  type callbackDomRef = Dom.element Js.nullable -> unit

  external domRef : currentDomRef -> domRef = "%identity"
  external callbackDomRef : callbackDomRef -> domRef = "%identity"
end

let createRef () = { current = None }
let useRef value = { current = value }
let forwardRef f = f ()

module Event = struct
  type 'a synthetic

  module MakeEventWithType (Type : sig
    type t
  end) =
  struct
    let bubbles : Type.t -> bool = fun _ -> false
    let cancelable : Type.t -> bool = fun _ -> false
    let currentTarget : Type.t -> < .. > Js.t = fun _ -> object end
    let defaultPrevented : Type.t -> bool = fun _ -> false
    let eventPhase : Type.t -> int = fun _ -> 0
    let isTrusted : Type.t -> bool = fun _ -> false
    let nativeEvent : Type.t -> < .. > Js.t = fun _ -> object end
    let preventDefault : Type.t -> unit = fun _ -> ()
    let isDefaultPrevented : Type.t -> bool = fun _ -> false
    let stopPropagation : Type.t -> unit = fun _ -> ()
    let isPropagationStopped : Type.t -> bool = fun _ -> false
    let target : Type.t -> < .. > Js.t = fun _ -> object end
    let timeStamp : Type.t -> float = fun _ -> 0.
    let type_ : Type.t -> string = fun _ -> ""
    let persist : Type.t -> unit = fun _ -> ()
  end

  module Synthetic = struct
    type tag
    type t = tag synthetic

    let bubbles : 'a synthetic -> bool = fun _ -> false
    let cancelable : 'a synthetic -> bool = fun _ -> false
    let currentTarget : 'a synthetic -> < .. > Js.t = fun _ -> object end
    let defaultPrevented : 'a synthetic -> bool = fun _ -> false
    let eventPhase : 'a synthetic -> int = fun _ -> 0
    let isTrusted : 'a synthetic -> bool = fun _ -> false
    let nativeEvent : 'a synthetic -> < .. > Js.t = fun _ -> object end
    let preventDefault : 'a synthetic -> unit = fun _ -> ()
    let isDefaultPrevented : 'a synthetic -> bool = fun _ -> false
    let stopPropagation : 'a synthetic -> unit = fun _ -> ()
    let isPropagationStopped : 'a synthetic -> bool = fun _ -> false
    let target : 'a synthetic -> < .. > Js.t = fun _ -> object end
    let timeStamp : 'a synthetic -> float = fun _ -> 0.
    let type_ : 'a synthetic -> string = fun _ -> ""
    let persist : 'a synthetic -> unit = fun _ -> ()
  end

  (* let toSyntheticEvent : 'a synthetic -> Synthetic.t = i -> i *)

  module Clipboard = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let clipboardData : t -> < .. > Js.t = fun _ -> object end
  end

  module Composition = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let data : t -> string = fun _ -> ""
  end

  module Keyboard = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let altKey : t -> bool = fun _ -> false
    let charCode : t -> int = fun _ -> 0
    let ctrlKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let key : t -> string = fun _ -> ""
    let keyCode : t -> int = fun _ -> 0
    let locale : t -> string = fun _ -> ""
    let location : t -> int = fun _ -> 0
    let metaKey : t -> bool = fun _ -> false
    let repeat : t -> bool = fun _ -> false
    let shiftKey : t -> bool = fun _ -> false
    let which : t -> int = fun _ -> 0
  end

  module Focus = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let relatedTarget : t -> < .. > Js.t option = fun _ -> None
  end

  module Form = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)
  end

  module Mouse = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let altKey : t -> bool = fun _ -> false
    let button : t -> int = fun _ -> 0
    let buttons : t -> int = fun _ -> 0
    let clientX : t -> int = fun _ -> 0
    let clientY : t -> int = fun _ -> 0
    let ctrlKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let metaKey : t -> bool = fun _ -> false
    let movementX : t -> int = fun _ -> 0
    let movementY : t -> int = fun _ -> 0
    let pageX : t -> int = fun _ -> 0
    let pageY : t -> int = fun _ -> 0
    let relatedTarget : t -> < .. > Js.t option = fun _ -> None
    let screenX : t -> int = fun _ -> 0
    let screenY : t -> int = fun _ -> 0
    let shiftKey : t -> bool = fun _ -> false
  end

  module Pointer = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let detail : t -> int = fun _ -> 0

    (* let view : t -> Dom.window = fun _ -> object end *)
    let screenX : t -> int = fun _ -> 0
    let screenY : t -> int = fun _ -> 0
    let clientX : t -> int = fun _ -> 0
    let clientY : t -> int = fun _ -> 0
    let pageX : t -> int = fun _ -> 0
    let pageY : t -> int = fun _ -> 0
    let movementX : t -> int = fun _ -> 0
    let movementY : t -> int = fun _ -> 0
    let ctrlKey : t -> bool = fun _ -> false
    let shiftKey : t -> bool = fun _ -> false
    let altKey : t -> bool = fun _ -> false
    let metaKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let button : t -> int = fun _ -> 0
    let buttons : t -> int = fun _ -> 0
    let relatedTarget : t -> < .. > Js.t option = fun _ -> None

    (* let pointerId : t -> Dom.eventPointerId *)
    let width : t -> float = fun _ -> 0.
    let height : t -> float = fun _ -> 0.
    let pressure : t -> float = fun _ -> 0.
    let tangentialPressure : t -> float = fun _ -> 0.
    let tiltX : t -> int = fun _ -> 0
    let tiltY : t -> int = fun _ -> 0
    let twist : t -> int = fun _ -> 0
    let pointerType : t -> string = fun _ -> ""
    let isPrimary : t -> bool = fun _ -> false
  end

  module Selection = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)
  end

  module Touch = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let altKey : t -> bool = fun _ -> false
    let changedTouches : t -> < .. > Js.t = fun _ -> object end
    let ctrlKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let metaKey : t -> bool = fun _ -> false
    let shiftKey : t -> bool = fun _ -> false
    let targetTouches : t -> < .. > Js.t = fun _ -> object end
    let touches : t -> < .. > Js.t = fun _ -> object end
  end

  module UI = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let detail : t -> int = fun _ -> 0
    (* let view : t -> Dom.window *)
  end

  module Wheel = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let deltaMode : t -> int = fun _ -> 0
    let deltaX : t -> float = fun _ -> 0.
    let deltaY : t -> float = fun _ -> 0.
    let deltaZ : t -> float = fun _ -> 0.
  end

  module Media = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)
  end

  module Image = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)
  end

  module Animation = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let animationName : t -> string = fun _ -> ""
    let pseudoElement : t -> string = fun _ -> ""
    let elapsedTime : t -> float = fun _ -> 0.
  end

  module Transition = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let propertyName : t -> string = fun _ -> ""
    let pseudoElement : t -> string = fun _ -> ""
    let elapsedTime : t -> float = fun _ -> 0.
  end

  module Drag = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let altKey : t -> bool = fun _ -> false
    let button : t -> int = fun _ -> 0
    let buttons : t -> int = fun _ -> 0
    let clientX : t -> int = fun _ -> 0
    let clientY : t -> int = fun _ -> 0
    let ctrlKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let metaKey : t -> bool = fun _ -> false
    let movementX : t -> int = fun _ -> 0
    let movementY : t -> int = fun _ -> 0
    let pageX : t -> int = fun _ -> 0
    let pageY : t -> int = fun _ -> 0
    let relatedTarget : t -> < .. > Js.t option = fun _ -> None
    let screenX : t -> int = fun _ -> 0
    let screenY : t -> int = fun _ -> 0
    let shiftKey : t -> bool = fun _ -> false
    let dataTransfer : t -> < .. > Js.t option = fun _ -> None
  end
end

module JSX = struct
  type event =
    | Drag of (Event.Drag.t -> unit)
    | Mouse of (Event.Mouse.t -> unit)
    | Selection of (Event.Selection.t -> unit)
    | Touch of (Event.Touch.t -> unit)
    | UI of (Event.UI.t -> unit)
    | Wheel of (Event.Wheel.t -> unit)
    | Clipboard of (Event.Clipboard.t -> unit)
    | Composition of (Event.Composition.t -> unit)
    | Transition of (Event.Transition.t -> unit)
    | Animation of (Event.Animation.t -> unit)
    | Pointer of (Event.Pointer.t -> unit)
    | Keyboard of (Event.Keyboard.t -> unit)
    | Focus of (Event.Focus.t -> unit)
    | Form of (Event.Form.t -> unit)
    | Media of (Event.Media.t -> unit)
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

let useContext context = context.current_value.current

let useState (make_initial_value : unit -> 'state) =
  let initial_value : 'state = make_initial_value () in
  let setState (fn : 'state -> 'state) =
    let _ = fn initial_value in
    ()
  in
  (initial_value, setState)

let internal_id = ref 0

let useId () =
  internal_id := !internal_id + 1;
  Int.to_string !internal_id

let useMemo fn = fn ()
let useMemo0 fn = fn ()
let useMemo1 fn _ = fn ()
let useMemo2 fn _ = fn ()
let useMemo3 fn _ = fn ()
let useMemo4 fn _ = fn ()
let useMemo5 fn _ = fn ()
let useMemo6 fn _ = fn ()
let useCallback fn = fn
let useCallback0 fn = fn
let useCallback1 fn _ = fn
let useCallback2 fn _ = fn
let useCallback3 fn _ = fn
let useCallback4 fn _ = fn
let useCallback5 fn _ = fn
let useCallback6 fn _ = fn
let useReducer _ s = (s, fun _ -> ())
let useReducerWithMapState _ s mapper = (mapper s, fun _ -> ())
let useEffect0 _ = ()
let useEffect1 _ _ = ()
let useEffect2 _ _ = ()
let useEffect3 _ _ = ()
let useEffect4 _ _ = ()
let useEffect5 _ _ = ()
let useEffect6 _ _ = ()
let useLayoutEffect0 _ = ()
let useLayoutEffect1 _ _ = ()
let useLayoutEffect2 _ _ = ()
let useLayoutEffect3 _ _ = ()
let useLayoutEffect4 _ _ = ()
let useLayoutEffect5 _ _ = ()
let useLayoutEffect6 _ _ = ()

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

let setDisplayName _ _ = ()
let useTransition () = (false, fun (_cb : unit -> unit) -> ())

let useDebugValue : 'value -> ?format:('value -> string) -> unit =
 fun [@warning "-16"] _ ?format:_ -> ()

let useDeferredValue value = value

(* `exception Suspend of 'a Lwt`
    exceptions can't have type params, this is called existential wrapper *)
type any_promise = Any_promise : 'a Lwt.t -> any_promise

exception Suspend of any_promise

module Experimental = struct
  let use promise =
    match Lwt.state promise with
    | Sleep -> raise (Suspend (Any_promise promise))
    (* TODO: Fail should raise a FailedSupense and catch at renderTo* *)
    | Fail e -> raise e
    | Return v -> v
end
