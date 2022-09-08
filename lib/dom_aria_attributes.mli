type t = Dom_dsl_core.Prop.t

val any : string -> 'a -> t
val string : string -> string -> t
val bool : string -> bool -> t
val int : string -> int -> t
val float_ : string -> float -> t
val event : string -> ('a Event.synthetic -> unit) -> t
val maybe : ('a -> t) -> 'a option -> t
val key : string -> t
val ref_ : Dom.dom_ref -> t
val ariaActivedescendant : string -> t
val ariaAtomic : string -> t
val ariaAutocomplete : string -> t
val ariaBusy : string -> t
val ariaChecked : string -> t
val ariaColcount : int -> t
val ariaColindex : int -> t
val ariaColspan : int -> t
val ariaControls : string -> t
val ariaCurrent : string -> t
val ariaDescribedby : string -> t
val ariaDetails : string -> t
val ariaDisabled : string -> t
val ariaDropeffect : string -> t
val ariaErrormessage : string -> t
val ariaExpanded : string -> t
val ariaFlowto : string -> t
val ariaGrabbed : string -> t
val ariaHaspopup : string -> t
val ariaHidden : string -> t
val ariaInvalid : string -> t
val ariaKeyshortcuts : string -> t
val ariaLabel : string -> t
val ariaLabelledby : string -> t
val ariaLevel : int -> t
val ariaLive : string -> t
val ariaModal : string -> t
val ariaMultiline : string -> t
val ariaMultiselectable : string -> t
val ariaOrientation : string -> t
val ariaOwns : string -> t
val ariaPlaceholder : string -> t
val ariaPosinset : int -> t
val ariaPressed : string -> t
val ariaReadonly : string -> t
val ariaRelevant : string -> t
val ariaRequired : string -> t
val ariaRoledescription : string -> t
val ariaRowcount : int -> t
val ariaRowindex : int -> t
val ariaRowspan : int -> t
val ariaSelected : string -> t
val ariaSetsize : int -> t
val ariaSort : string -> t
val ariaValuemax : int -> t
val ariaValuemin : int -> t
val ariaValuenow : int -> t
val ariaValuetext : string -> t
