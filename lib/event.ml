(* Adapted from reason-react ReactEvent.re, commit 0f73a307 *)
type 'a synthetic = Ojs.t

module CommonApi = struct
  include
    [%js:
    type tag = Ojs.t
    type t = Ojs.t

    val t_of_js : Ojs.t -> t
    val t_to_js : t -> Ojs.t
    val bubbles : Ojs.t -> bool [@@js.get "bubbles"]
    val cancelable : t -> bool [@@js.get "cancelable"]
    val current_target : t -> Ojs.t [@@js.get "currentTarget"]
    (* Should return Dom.eventTarget *)

    val default_prevented : t -> bool [@@js.get "defaultPrevented"]
    val event_phase : t -> int [@@js.get "eventPhase"]
    val is_trusted : t -> bool [@@js.get "isTrusted"]
    val native_event : t -> Ojs.t [@@js.get "nativeEvent"]
    (* Should return Dom.event *)

    val prevent_default : t -> unit [@@js.call "preventDefault"]
    val is_default_prevented : t -> bool [@@js.call "isDefaultPrevented"]
    val stop_propagation : t -> unit [@@js.call "stopPropagation"]
    val is_propagation_stopped : t -> bool [@@js.call "isPropagationStopped"]
    val target : t -> Ojs.t [@@js.get "target"]
    (* Should return Dom.eventTarget *)

    val time_stamp : t -> float [@@js.get "timeStamp"]
    val type_ : t -> string [@@js.get "type"]
    val persist : t -> unit [@@js.call "persist"]]
end

module Synthetic = CommonApi

(* Cast any event type to the general synthetic type. This is safe, since synthetic is more general *)
external to_synthetic_event : 'a synthetic -> Synthetic.t = "%identity"

module Clipboard = struct
  include CommonApi
  include [%js: val clipboard_data : t -> Ojs.t [@@js.get "clipboardData"]]

  (* Should return Dom.dataTransfer *)
end

module Composition = struct
  include CommonApi
  include [%js: val data : t -> string [@@js.get "data"]]
end

module Keyboard = struct
  include CommonApi

  include
    [%js:
    val alt_key : t -> bool [@@js.get "altKey"]
    val char_code : t -> int [@@js.get "charCode"]
    val ctrl_key : t -> bool [@@js.get "ctrlKey"]
    val get_modifier_state : t -> string -> bool [@@js.call "getModifierState"]
    val key : t -> string [@@js.get "key"]
    val key_code : t -> int [@@js.get "keyCode"]
    val locale : t -> string [@@js.get "locale"]
    val location : t -> int [@@js.get "location"]
    val meta_key : t -> bool [@@js.get "metaKey"]
    val repeat : t -> bool [@@js.get "repeat"]
    val shift_key : t -> bool [@@js.get "shiftKey"]
    val which : t -> int [@@js.get "which"]]
end

module Focus = struct
  include CommonApi

  include
    [%js:
    val related_target : t -> Ojs.t option [@@js.get "relatedTarget"]]

  (* Should return Dom.eventTarget *)
end

module Form = struct
  include CommonApi
end

module Mouse = struct
  include CommonApi

  include
    [%js:
    val alt_key : t -> bool [@@js.get "altKey"]
    val button : t -> int [@@js.get "button"]
    val buttons : t -> int [@@js.get "buttons"]
    val client_x : t -> int [@@js.get "clientX"]
    val client_y : t -> int [@@js.get "clientY"]
    val ctrl_key : t -> bool [@@js.get "ctrlKey"]
    val get_modifier_state : t -> string -> bool [@@js.call "getModifierState"]
    val meta_key : t -> bool [@@js.get "metaKey"]
    val page_x : t -> int [@@js.get "pageX"]
    val page_y : t -> int [@@js.get "pageY"]
    val related_target : t -> Ojs.t option [@@js.get "relatedTarget"]

    (* Should return Dom.eventTarget *)

    val screen_x : t -> int [@@js.get "screenX"]
    val screen_y : t -> int [@@js.get "screenY"]
    val shift_key : t -> bool [@@js.get "shiftKey"]]
end

module Selection = struct
  include CommonApi
end

module Touch = struct
  include CommonApi

  include
    [%js:
    val alt_key : t -> bool [@@js.get "altKey"]
    val changed_touches : t -> Ojs.t [@@js.get "changedTouches"]
    (* Should return Dom.touchList *)

    val ctrl_key : t -> bool [@@js.get "ctrlKey"]
    val get_modifier_state : t -> string -> bool [@@js.call "getModifierState"]
    val meta_key : t -> bool [@@js.get "metaKey"]
    val shift_key : t -> bool [@@js.get "shiftKey"]
    val target_touches : t -> Ojs.t [@@js.get "targetTouches"]
    (* Should return Dom.touchList *)

    val touches : t -> Ojs.t [@@js.get "touches"]]

  (* Should return Dom.touchList *)
end

module Pointer = struct
  include Mouse

  include
    [%js:
    val pointerId : t -> int [@@js.get]
    val pressure : t -> float [@@js.get]
    val tangentialPressure : t -> float [@@js.get]
    val tiltX : t -> float [@@js.get]
    val tiltY : t -> float [@@js.get]
    val twist : t -> float [@@js.get]
    val width : t -> float [@@js.get]
    val height : t -> float [@@js.get]
    val pointerType : t -> string [@@js.get]
    val isPrimary : t -> bool [@@js.get]]
end

type window = Js_of_ocaml.Dom_html.window

module UI = struct
  external window_of_js : Ojs.t -> Js_of_ocaml.Dom_html.window = "%identity"

  include CommonApi

  include
    [%js:
    val detail : t -> int [@@js.get "detail"]
    val view : t -> window [@@js.get "view"]]

  (* Should return DOMAbstractView/WindowProxy *)
end

module Wheel = struct
  include CommonApi

  include
    [%js:
    val delta_mode : t -> int [@@js.get "deltaMode"]
    val delta_x : t -> float [@@js.get "deltaX"]
    val delta_y : t -> float [@@js.get "deltaY"]
    val delta_z : t -> float [@@js.get "deltaZ"]]
end

module Media = struct
  include CommonApi
end

module Image = struct
  include CommonApi
end

module Animation = struct
  include CommonApi

  include
    [%js:
    val animation_name : t -> string [@@js.get "animationName"]
    val pseudo_element : t -> string [@@js.get "pseudoElement"]
    val elapsed_time : t -> float [@@js.get "elapsedTime"]]
end

module Transition = struct
  include CommonApi

  include
    [%js:
    val property_name : t -> string [@@js.get "propertyName"]
    val pseudo_element : t -> string [@@js.get "pseudoElement"]
    val elapsed_time : t -> float [@@js.get "elapsedTime"]]
end
