type domRef

module Dom : sig
  type element
end

type 'value ref = { mutable current : 'value }

module Ref : sig
  type t = domRef
  type currentDomRef = Dom.element Js.nullable ref
  type callbackDomRef

  external domRef : currentDomRef -> domRef = "%identity"
  external callbackDomRef : callbackDomRef -> domRef = "%identity"
end

val createRef : unit -> 'a option ref
val useRef : 'a -> 'a ref
val forwardRef : (unit -> 'a) -> 'a

(** All of those types are used by the server-reason-react.ppx internally to represent valid React code from the server. It currently different from reason-react-ppx due to a need for knowing the types since ReactDOM needs to render differently depending on the type. *)
module JSX : sig
  (** All event callbacks *)
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
    val drag : string -> (ReactEvent.Drag.t -> unit) -> prop
    val mouse : string -> (ReactEvent.Mouse.t -> unit) -> prop
    val selection : string -> (ReactEvent.Selection.t -> unit) -> prop
    val touch : string -> (ReactEvent.Touch.t -> unit) -> prop
    val ui : string -> (ReactEvent.UI.t -> unit) -> prop
    val wheel : string -> (ReactEvent.Wheel.t -> unit) -> prop
    val clipboard : string -> (ReactEvent.Clipboard.t -> unit) -> prop
    val composition : string -> (ReactEvent.Composition.t -> unit) -> prop
    val transition : string -> (ReactEvent.Transition.t -> unit) -> prop
    val animation : string -> (ReactEvent.Animation.t -> unit) -> prop
    val pointer : string -> (ReactEvent.Pointer.t -> unit) -> prop
    val keyboard : string -> (ReactEvent.Keyboard.t -> unit) -> prop
    val focus : string -> (ReactEvent.Focus.t -> unit) -> prop
    val form : string -> (ReactEvent.Form.t -> unit) -> prop
    val media : string -> (ReactEvent.Media.t -> unit) -> prop
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
val use : 'a Lwt.t -> 'a
val useContext : 'a Context.t -> 'a
val useState : (unit -> 'state) -> 'state * (('state -> 'state) -> unit)
val useMemo : (unit -> 'a) -> 'a
val useMemo1 : (unit -> 'a) -> 'b -> 'a
val useMemo2 : (unit -> 'a) -> 'b -> 'a
val useMemo3 : (unit -> 'a) -> 'b -> 'a
val useMemo4 : (unit -> 'a) -> 'b -> 'a
val useMemo5 : (unit -> 'a) -> 'b -> 'a
val useMemo6 : (unit -> 'a) -> 'b -> 'a
val useCallback : 'a -> 'a
val useCallback1 : 'a -> 'b -> 'a
val useCallback2 : 'a -> 'b -> 'a
val useCallback3 : 'a -> 'b -> 'a
val useCallback4 : 'a -> 'b -> 'a
val useCallback5 : 'a -> 'b -> 'a
val useCallback6 : ('a -> 'b) -> 'a -> 'b

val useReducer :
  ('state -> 'action -> 'state) -> 'state -> 'state * ('action -> unit)

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
