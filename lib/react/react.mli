[@@@warning "-67"] (* There's an unused parameter on functor Fragment *)

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

module rec Lower_case_element : sig
  type t =
    { tag : string
    ; attributes : Attribute.t array
    ; children : Element.t list
    }
end

and Lower_case_closed_element : sig
  type t =
    { tag : string
    ; attributes : Attribute.t array
    }
end

and Element : sig
  type t =
    | Lower_case_element of Lower_case_element.t
    | Lower_case_closed_element of Lower_case_closed_element.t
    | Upper_case_element of (unit -> t)
    | List of t array
    | Text of string
    | InnerHtml of string
    | Fragment of t list
    | Empty
    | Provider of (unit -> t) list
    | Consumer of (unit -> t list)
end

and EventT : sig
  type t =
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
    | Inline of string
end

and Attribute : sig
  type t =
    | Bool of (string * bool)
    | String of (string * string)
    | Style of string
    | DangerouslyInnerHtml of string
    | Ref of domRef
    | Event of string * EventT.t
end

and Fragment : sig
  type t = Element.t list

  val make : children:t -> unit -> Element.t
end

exception Invalid_children of string

val createElement : string -> Attribute.t array -> Element.t list -> Element.t
val cloneElement : Element.t -> Attribute.t array -> Element.t list -> Element.t
val memo : ('props * 'props -> bool) -> 'a -> 'props * 'props -> bool

type 'a context =
  { current_value : 'a ref
  ; provider : value:'a -> children:(unit -> Element.t) list -> Element.t
  ; consumer : children:('a -> Element.t list) -> Element.t
  }

val createContext : 'a -> 'a context
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
     (unit -> (unit -> unit) option)
  -> 'dependency1 * 'dependency2 * 'dependency3
  -> unit

val useEffect4 :
     (unit -> (unit -> unit) option)
  -> 'dependency1 * 'dependency2 * 'dependency3 * 'dependency4
  -> unit

val useEffect5 :
     (unit -> (unit -> unit) option)
  -> 'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 * 'dependency5
  -> unit

val useEffect6 :
     (unit -> (unit -> unit) option)
  -> 'dependency1
     * 'dependency2
     * 'dependency3
     * 'dependency4
     * 'dependency5
     * 'dependency6
  -> unit

val useLayoutEffect0 : (unit -> (unit -> unit) option) -> unit

val useLayoutEffect1 :
  (unit -> (unit -> unit) option) -> 'dependency array -> unit

val useLayoutEffect2 :
  (unit -> (unit -> unit) option) -> 'dependency1 * 'dependency2 -> unit

val useLayoutEffect3 :
     (unit -> (unit -> unit) option)
  -> 'dependency1 * 'dependency2 * 'dependency3
  -> unit

val useLayoutEffect4 :
     (unit -> (unit -> unit) option)
  -> 'dependency1 * 'dependency2 * 'dependency3 * 'dependency4
  -> unit

val useLayoutEffect5 :
     (unit -> (unit -> unit) option)
  -> 'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 * 'dependency5
  -> unit

val useLayoutEffect6 :
     (unit -> (unit -> unit) option)
  -> 'dependency1
     * 'dependency2
     * 'dependency3
     * 'dependency4
     * 'dependency5
     * 'dependency6
  -> unit

val setDisplayName : 'component -> string -> unit
val string : string -> Element.t
val null : Element.t
val int : int -> Element.t
val float : float -> Element.t
val array : Element.t array -> Element.t
val list : Element.t list -> Element.t
