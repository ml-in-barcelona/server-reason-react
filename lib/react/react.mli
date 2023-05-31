type domRef

module Ref : sig
  type t = domRef
  type currentDomRef = Webapi.Dom.element Js.nullable ref
  type callbackDomRef

  external domRef : currentDomRef -> domRef = "%identity"
  external callbackDomRef : callbackDomRef -> domRef = "%identity"
end

val createRef : unit -> 'a option ref
val useRef : 'a -> 'a ref
val forwardRef : (unit -> 'a) -> 'a

module Attribute : sig
  module Event : sig
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
    | Ref of domRef
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

(* type ('props, 'return) componentLike = 'props -> 'return *)
(* type 'props component = ('props, element) componentLike *)
(* external component : ('props, element) componentLike -> 'props component = "%identity" *)

val createElement : string -> Attribute.t array -> element list -> element
val fragment : children:element -> unit -> element
val cloneElement : element -> Attribute.t array -> element list -> element
val string : string -> element
val null : element
val int : int -> element
val float : float -> element
val array : element array -> element
val list : element list -> element

type 'a context = {
  current_value : 'a ref;
  provider : value:'a -> children:(unit -> element) list -> element;
  consumer : children:('a -> element list) -> element;
}

val createContext : 'a -> 'a context

(* val memo : ('props * 'props -> bool) -> 'a -> 'props * 'props -> bool *)
val useContext : 'a context -> 'a
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
