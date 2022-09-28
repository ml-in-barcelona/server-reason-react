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

    (* let view : t -> Dom.window = (fun _ -> object end) *)
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
end

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
    | Mouse of (Event.Mouse.t -> unit)
    | Selection of (Event.Selection.t -> unit)
    | Touch of (Event.Touch.t -> unit)
    | UI of (Event.UI.t -> unit)
    | Wheel of (Event.Wheel.t -> unit)
    | Clipboard of (Event.Clipboard.t -> unit)
    | Composition of (Event.Composition.t -> unit)
    | Keyboard of (Event.Keyboard.t -> unit)
    | Focus of (Event.Focus.t -> unit)
    | Form of (Event.Form.t -> unit)
    | Media of (Event.Media.t -> unit)
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

  val make : t -> Element.t
end = struct
  type t = Element.t list

  let make f = Element.Fragment f
end

let is_self_closing_tag = function
  | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link"
  | "meta" | "param" | "source" | "track" | "wbr" ->
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

let useState f_initial_value =
  let setState _ = () in
  (f_initial_value (), setState)

let useStateValue initial_value =
  let setState _ = () in
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
