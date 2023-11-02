type domRef

module Dom : sig
  type element
end

type 'value ref = { mutable current : 'value }

module Ref : sig
  type t = domRef
  type currentDomRef = Dom.element Js.nullable ref
  type callbackDomRef = Dom.element Js.nullable -> unit

  external domRef : currentDomRef -> domRef = "%identity"
  external callbackDomRef : callbackDomRef -> domRef = "%identity"
end

val createRef : unit -> 'a option ref
val useRef : 'a -> 'a ref
val forwardRef : (unit -> 'a) -> 'a

module Event : sig
  type 'a synthetic

  module MakeEventWithType : functor
    (Type : sig
       type t
     end)
    -> sig
    val bubbles : Type.t -> bool
    val cancelable : Type.t -> bool
    val currentTarget : Type.t -> < >
    val defaultPrevented : Type.t -> bool
    val eventPhase : Type.t -> int
    val isTrusted : Type.t -> bool
    val nativeEvent : Type.t -> < >
    val preventDefault : Type.t -> unit
    val isDefaultPrevented : Type.t -> bool
    val stopPropagation : Type.t -> unit
    val isPropagationStopped : Type.t -> bool
    val target : Type.t -> < >
    val timeStamp : Type.t -> float
    val type_ : Type.t -> string
    val persist : Type.t -> unit
  end

  module Synthetic : sig
    type tag
    type t = tag synthetic

    val bubbles : 'a synthetic -> bool
    val cancelable : 'a synthetic -> bool
    val currentTarget : 'a synthetic -> < >
    val defaultPrevented : 'a synthetic -> bool
    val eventPhase : 'a synthetic -> int
    val isTrusted : 'a synthetic -> bool
    val nativeEvent : 'a synthetic -> < >
    val preventDefault : 'a synthetic -> unit
    val isDefaultPrevented : 'a synthetic -> bool
    val stopPropagation : 'a synthetic -> unit
    val isPropagationStopped : 'a synthetic -> bool
    val target : 'a synthetic -> < >
    val timeStamp : 'a synthetic -> float
    val type_ : 'a synthetic -> string
    val persist : 'a synthetic -> unit
  end

  module Clipboard : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val clipboardData : t -> < >
  end

  module Composition : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val data : t -> string
  end

  module Keyboard : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val altKey : t -> bool
    val charCode : t -> int
    val ctrlKey : t -> bool
    val getModifierState : t -> string -> bool
    val key : t -> string
    val keyCode : t -> int
    val locale : t -> string
    val location : t -> int
    val metaKey : t -> bool
    val repeat : t -> bool
    val shiftKey : t -> bool
    val which : t -> int
  end

  module Focus : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val relatedTarget : t -> < .. > option
  end

  module Form : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
  end

  module Mouse : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val altKey : t -> bool
    val button : t -> int
    val buttons : t -> int
    val clientX : t -> int
    val clientY : t -> int
    val ctrlKey : t -> bool
    val getModifierState : t -> string -> bool
    val metaKey : t -> bool
    val movementX : t -> int
    val movementY : t -> int
    val pageX : t -> int
    val pageY : t -> int
    val relatedTarget : t -> < .. > option
    val screenX : t -> int
    val screenY : t -> int
    val shiftKey : t -> bool
  end

  module Pointer : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val detail : t -> int
    val screenX : t -> int
    val screenY : t -> int
    val clientX : t -> int
    val clientY : t -> int
    val pageX : t -> int
    val pageY : t -> int
    val movementX : t -> int
    val movementY : t -> int
    val ctrlKey : t -> bool
    val shiftKey : t -> bool
    val altKey : t -> bool
    val metaKey : t -> bool
    val getModifierState : t -> string -> bool
    val button : t -> int
    val buttons : t -> int
    val relatedTarget : t -> < .. > option
    val width : t -> float
    val height : t -> float
    val pressure : t -> float
    val tangentialPressure : t -> float
    val tiltX : t -> int
    val tiltY : t -> int
    val twist : t -> int
    val pointerType : t -> string
    val isPrimary : t -> bool
  end

  module Selection : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
  end

  module Touch : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val altKey : t -> bool
    val changedTouches : t -> < >
    val ctrlKey : t -> bool
    val getModifierState : t -> string -> bool
    val metaKey : t -> bool
    val shiftKey : t -> bool
    val targetTouches : t -> < >
    val touches : t -> < >
  end

  module UI : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val detail : t -> int
  end

  module Wheel : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val deltaMode : t -> int
    val deltaX : t -> float
    val deltaY : t -> float
    val deltaZ : t -> float
  end

  module Media : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
  end

  module Image : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
  end

  module Animation : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val animationName : t -> string
    val pseudoElement : t -> string
    val elapsedTime : t -> float
  end

  module Transition : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val propertyName : t -> string
    val pseudoElement : t -> string
    val elapsedTime : t -> float
  end

  module Drag : sig
    type tag
    type t = tag synthetic

    val bubbles : t -> bool
    val cancelable : t -> bool
    val currentTarget : t -> < >
    val defaultPrevented : t -> bool
    val eventPhase : t -> int
    val isTrusted : t -> bool
    val nativeEvent : t -> < >
    val preventDefault : t -> unit
    val isDefaultPrevented : t -> bool
    val stopPropagation : t -> unit
    val isPropagationStopped : t -> bool
    val target : t -> < >
    val timeStamp : t -> float
    val type_ : t -> string
    val persist : t -> unit
    val altKey : t -> bool
    val button : t -> int
    val buttons : t -> int
    val clientX : t -> int
    val clientY : t -> int
    val ctrlKey : t -> bool
    val getModifierState : t -> string -> bool
    val metaKey : t -> bool
    val movementX : t -> int
    val movementY : t -> int
    val pageX : t -> int
    val pageY : t -> int
    val relatedTarget : t -> < .. > option
    val screenX : t -> int
    val screenY : t -> int
    val shiftKey : t -> bool
    val dataTransfer : t -> < .. > option
  end
end

(** All of those types are used by the server-reason-react.ppx internally to represent valid React code from the server. It currently different from reason-react-ppx due to a need for knowing the types since ReactDOM needs to render differently depending on the type. *)
module JSX : sig
  (** All event callbacks *)
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

  (** JSX.prop is the representation of HTML/SVG attributes and DOM events *)
  type prop =
    | Bool of (string * bool)
    | String of (string * string)
    | Style of string
    | DangerouslyInnerHtml of string
    | Ref of domRef
    | Event of string * event

  (** Helpers to create JSX.prop without variants, helpful for function application *)

  val bool : string -> bool -> prop
  val string : string -> string -> prop
  val style : string -> prop
  val dangerouslyInnerHtml : string -> prop
  val int : string -> int -> prop
  val float : string -> float -> prop
  val ref : domRef -> prop
  val event : string -> event -> prop

  module Event : sig
    val drag : string -> (Event.Drag.t -> unit) -> prop
    val mouse : string -> (Event.Mouse.t -> unit) -> prop
    val selection : string -> (Event.Selection.t -> unit) -> prop
    val touch : string -> (Event.Touch.t -> unit) -> prop
    val ui : string -> (Event.UI.t -> unit) -> prop
    val wheel : string -> (Event.Wheel.t -> unit) -> prop
    val clipboard : string -> (Event.Clipboard.t -> unit) -> prop
    val composition : string -> (Event.Composition.t -> unit) -> prop
    val transition : string -> (Event.Transition.t -> unit) -> prop
    val animation : string -> (Event.Animation.t -> unit) -> prop
    val pointer : string -> (Event.Pointer.t -> unit) -> prop
    val keyboard : string -> (Event.Keyboard.t -> unit) -> prop
    val focus : string -> (Event.Focus.t -> unit) -> prop
    val form : string -> (Event.Form.t -> unit) -> prop
    val media : string -> (Event.Media.t -> unit) -> prop
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

(* type ('props, 'return) componentLike = 'props -> 'return *)
(* type 'props component = ('props, element) componentLike *)
(* external component : ('props, element) componentLike -> 'props component = "%identity" *)

val createElement : string -> JSX.prop array -> element list -> element
val fragment : children:element -> unit -> element
val cloneElement : element -> JSX.prop array -> element
val string : string -> element
val null : element
val int : int -> element
val float : float -> element
val array : element array -> element
val list : element list -> element

type 'a provider = value:'a -> children:element -> unit -> element

type 'a context = {
  current_value : 'a ref;
  provider : 'a provider;
  consumer : children:element -> element;
}

module Context : sig
  type 'a t = 'a context

  val provider : 'a t -> 'a provider
end

val createContext : 'a -> 'a Context.t

module Suspense : sig
  val make : ?fallback:element -> ?children:element -> unit -> element
end

type any_promise = Any_promise : 'a Lwt.t -> any_promise

exception Suspend of any_promise

(* val memo : ('props * 'props -> bool) -> 'a -> 'props * 'props -> bool *)
val useContext : 'a Context.t -> 'a
val useState : (unit -> 'state) -> 'state * (('state -> 'state) -> unit)
val useMemo : (unit -> 'a) -> 'a
val useMemo0 : (unit -> 'a) -> 'a
val useMemo1 : (unit -> 'a) -> 'b -> 'a
val useMemo2 : (unit -> 'a) -> 'b -> 'a
val useMemo3 : (unit -> 'a) -> 'b -> 'a
val useMemo4 : (unit -> 'a) -> 'b -> 'a
val useMemo5 : (unit -> 'a) -> 'b -> 'a
val useMemo6 : (unit -> 'a) -> 'b -> 'a
val useCallback : 'a -> 'a
val useCallback0 : 'a -> 'a
val useCallback1 : 'a -> 'b -> 'a
val useCallback2 : 'a -> 'b -> 'a
val useCallback3 : 'a -> 'b -> 'a
val useCallback4 : 'a -> 'b -> 'a
val useCallback5 : 'a -> 'b -> 'a
val useCallback6 : 'a -> 'b -> 'a
val useId : unit -> string

val useReducer :
  ('state -> 'action -> 'state) -> 'state -> 'state * ('action -> unit)

val useReducerWithMapState :
  ('state -> 'action -> 'initialState) ->
  'initialState ->
  ('initialState -> 'state) ->
  'state * ('action -> unit)

val useEffect0 : (unit -> (unit -> unit) option) -> unit
val useEffect1 : (unit -> (unit -> unit) option) -> 'dependency array -> unit

val useEffect2 :
  (unit -> (unit -> unit) option) -> 'dependency1 * 'dependency2 -> unit

val useEffect3 :
  (unit -> (unit -> unit) option) ->
  'dependency1 * 'dependency2 * 'dependency3 ->
  unit

val useEffect4 :
  (unit -> (unit -> unit) option) ->
  'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 ->
  unit

val useEffect5 :
  (unit -> (unit -> unit) option) ->
  'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 * 'dependency5 ->
  unit

val useEffect6 :
  (unit -> (unit -> unit) option) ->
  'dependency1
  * 'dependency2
  * 'dependency3
  * 'dependency4
  * 'dependency5
  * 'dependency6 ->
  unit

val useLayoutEffect0 : (unit -> (unit -> unit) option) -> unit

val useLayoutEffect1 :
  (unit -> (unit -> unit) option) -> 'dependency array -> unit

val useLayoutEffect2 :
  (unit -> (unit -> unit) option) -> 'dependency1 * 'dependency2 -> unit

val useLayoutEffect3 :
  (unit -> (unit -> unit) option) ->
  'dependency1 * 'dependency2 * 'dependency3 ->
  unit

val useLayoutEffect4 :
  (unit -> (unit -> unit) option) ->
  'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 ->
  unit

val useLayoutEffect5 :
  (unit -> (unit -> unit) option) ->
  'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 * 'dependency5 ->
  unit

val useLayoutEffect6 :
  (unit -> (unit -> unit) option) ->
  'dependency1
  * 'dependency2
  * 'dependency3
  * 'dependency4
  * 'dependency5
  * 'dependency6 ->
  unit

val setDisplayName : 'component -> string -> unit

module Children : sig
  val map : (element -> element) -> element array -> element array

  val mapWithIndex :
    (int -> element -> element) -> element array -> element array

  val forEach : (element -> unit) -> element array -> unit
  val forEachWithIndex : (int -> element -> unit) -> element array -> unit
  val count : element array -> int
  val only : element array -> element
  val toArray : element -> element array
end

module Experimental : sig
  val use : 'a Lwt.t -> 'a
end

val useTransition : unit -> bool * ((unit -> unit) -> unit)
val useDebugValue : 'value -> ?format:('value -> string) -> unit
val useDeferredValue : 'value -> 'value
