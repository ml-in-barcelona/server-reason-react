(* Adapted from reason-react ReactEvent.re, commit 0f73a307type 'a synthetic *)
type 'a synthetic

module Synthetic : sig
  type tag
  type t = tag synthetic

  val bubbles : 'a synthetic -> bool
  val cancelable : 'a synthetic -> bool
  val current_target : 'a synthetic -> Ojs.t
  val default_prevented : 'a synthetic -> bool
  val event_phase : 'a synthetic -> int
  val is_trusted : 'a synthetic -> bool
  val native_event : 'a synthetic -> Ojs.t
  val prevent_default : 'a synthetic -> unit
  val is_default_prevented : 'a synthetic -> bool
  val stop_propagation : 'a synthetic -> unit
  val is_propagation_stopped : 'a synthetic -> bool
  val target : 'a synthetic -> Ojs.t
  val time_stamp : 'a synthetic -> float
  val type_ : 'a synthetic -> string
  val persist : 'a synthetic -> unit
end

(* Cast any event type to the general synthetic type. This is safe, since synthetic is more general *)
val to_synthetic_event : 'a synthetic -> Synthetic.t

module Clipboard : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val clipboard_data : t -> Ojs.t
end

module Composition : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val data : t -> string
end

module Keyboard : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val alt_key : t -> bool
  val char_code : t -> int
  val ctrl_key : t -> bool
  val get_modifier_state : t -> string -> bool
  val key : t -> string
  val key_code : t -> int
  val locale : t -> string
  val location : t -> int
  val meta_key : t -> bool
  val repeat : t -> bool
  val shift_key : t -> bool
  val which : t -> int
end

module Focus : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val related_target : t -> Ojs.t option
end

module Form : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
end

module Mouse : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val alt_key : t -> bool
  val button : t -> int
  val buttons : t -> int
  val client_x : t -> int
  val client_y : t -> int
  val ctrl_key : t -> bool
  val get_modifier_state : t -> string -> bool
  val meta_key : t -> bool
  val page_x : t -> int
  val page_y : t -> int
  val related_target : t -> Ojs.t option
  val screen_x : t -> int
  val screen_y : t -> int
  val shift_key : t -> bool
end

module Selection : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
end

module Touch : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val alt_key : t -> bool
  val changed_touches : t -> Ojs.t
  val ctrl_key : t -> bool
  val get_modifier_state : t -> string -> bool
  val meta_key : t -> bool
  val shift_key : t -> bool
  val target_touches : t -> Ojs.t
  val touches : t -> Ojs.t
end

module Pointer : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val pointerId : t -> int
  val pressure : t -> float
  val tangentialPressure : t -> float
  val tiltX : t -> float
  val tiltY : t -> float
  val twist : t -> float
  val width : t -> float
  val height : t -> float
  val pointerType : t -> string (* 'mouse' | 'pen' | 'touch' *)
  val isPrimary : t -> bool

  (** Inherited from Mouse *)

  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val alt_key : t -> bool
  val button : t -> int
  val buttons : t -> int
  val client_x : t -> int
  val client_y : t -> int
  val ctrl_key : t -> bool
  val get_modifier_state : t -> string -> bool
  val meta_key : t -> bool
  val page_x : t -> int
  val page_y : t -> int
  val related_target : t -> Ojs.t option
  val screen_x : t -> int
  val screen_y : t -> int
  val shift_key : t -> bool
end

module UI : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val detail : t -> int
  val view : t -> Js_of_ocaml.Dom_html.window
end

module Wheel : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val delta_mode : t -> int
  val delta_x : t -> float
  val delta_y : t -> float
  val delta_z : t -> float
end

module Media : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
end

module Image : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
end

module Animation : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val animation_name : t -> string
  val pseudo_element : t -> string
  val elapsed_time : t -> float
end

module Transition : sig
  type tag
  type t = tag synthetic

  val t_of_js : Ojs.t -> t
  val t_to_js : t -> Ojs.t
  val bubbles : t -> bool
  val cancelable : t -> bool
  val current_target : t -> Ojs.t
  val default_prevented : t -> bool
  val event_phase : t -> int
  val is_trusted : t -> bool
  val native_event : t -> Ojs.t
  val prevent_default : t -> unit
  val is_default_prevented : t -> bool
  val stop_propagation : t -> unit
  val is_propagation_stopped : t -> bool
  val target : t -> Ojs.t
  val time_stamp : t -> float
  val type_ : t -> string
  val persist : t -> unit
  val property_name : t -> string
  val pseudo_element : t -> string
  val elapsed_time : t -> float
end
