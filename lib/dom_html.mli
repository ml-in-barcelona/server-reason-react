module Prop : sig
  include module type of Dom_aria_attributes

  type t = Dom_dsl_core.Prop.t

  (** Common *)

  val any : string -> 'a -> t
  val string : string -> string -> t
  val bool : string -> bool -> t
  val int : string -> int -> t
  val float_ : string -> float -> t
  val event : string -> ('a Event.synthetic -> unit) -> t
  val key : string -> t
  val ref_ : Dom.dom_ref -> t

  (** Modifiers *)

  val maybe : ('a -> t) -> 'a option -> t

  (** HTML props *)

  val defaultChecked : bool -> t
  val defaultValue : string -> t
  val accessKey : string -> t
  val className : string -> t
  val classNames : string list -> t
  val contentEditable : bool -> t
  val contextMenu : string -> t
  val dir : string -> t
  val draggable : bool -> t
  val hidden : bool -> t
  val id : string -> t
  val lang : string -> t
  val role : string -> t
  val style : Dom.Style.t -> t
  val spellCheck : bool -> t
  val tabIndex : int -> t
  val title : string -> t
  val itemID : string -> t
  val itemProp : string -> t
  val itemRef : string -> t
  val itemScope : bool -> t
  val itemType : string -> t
  val accept : string -> t
  val acceptCharset : string -> t
  val action : string -> t
  val allowFullScreen : bool -> t
  val alt : string -> t
  val async : bool -> t
  val autoComplete : string -> t
  val autoCapitalize : string -> t
  val autoFocus : bool -> t
  val autoPlay : bool -> t
  val challenge : string -> t
  val charSet : string -> t
  val checked : bool -> t
  val cite : string -> t
  val crossOrigin : string -> t
  val cols : int -> t
  val colSpan : int -> t
  val content : string -> t
  val controls : bool -> t
  val coords : string -> t
  val data : string -> t
  val dateTime : string -> t
  val default : bool -> t
  val defer : bool -> t
  val disabled : bool -> t
  val download : string -> t
  val encType : string -> t
  val form : string -> t
  val formAction : string -> t
  val formTarget : string -> t
  val formMethod : string -> t
  val headers : string -> t
  val height : string -> t
  val high : int -> t
  val href : string -> t
  val hrefLang : string -> t
  val htmlFor : string -> t
  val httpEquiv : string -> t
  val icon : string -> t
  val inputMode : string -> t
  val integrity : string -> t
  val keyType : string -> t
  val kind : string -> t
  val label : string -> t
  val list : string -> t
  val loop : bool -> t
  val low : int -> t
  val manifest : string -> t
  val max : string -> t
  val maxLength : int -> t
  val media : string -> t
  val mediaGroup : string -> t
  val method_ : string -> t
  val min : string -> t
  val minLength : int -> t
  val multiple : bool -> t
  val muted : bool -> t
  val name : string -> t
  val nonce : string -> t
  val noValidate : bool -> t
  val open_ : bool -> t
  val optimum : int -> t
  val pattern : string -> t
  val placeholder : string -> t
  val playsInline : bool -> t
  val poster : string -> t
  val preload : string -> t
  val radioGroup : string -> t
  val readOnly : bool -> t
  val rel : string -> t
  val required : bool -> t
  val reversed : bool -> t
  val rows : int -> t
  val rowSpan : int -> t
  val sandbox : string -> t
  val scope : string -> t
  val scoped : bool -> t
  val scrolling : string -> t
  val selected : bool -> t
  val shape : string -> t
  val size : int -> t
  val sizes : string -> t
  val span : int -> t
  val src : string -> t
  val srcDoc : string -> t
  val srcLang : string -> t
  val srcSet : string -> t
  val start : int -> t
  val step : float -> t
  val summary : string -> t
  val target : string -> t
  val type_ : string -> t
  val useMap : string -> t
  val value : string -> t
  val width : string -> t
  val wrap : string -> t
  val onCopy : (Event.Clipboard.t -> unit) -> t
  val onCut : (Event.Clipboard.t -> unit) -> t
  val onPaste : (Event.Clipboard.t -> unit) -> t
  val onCompositionEnd : (Event.Composition.t -> unit) -> t
  val onCompositionStart : (Event.Composition.t -> unit) -> t
  val onCompositionUpdate : (Event.Composition.t -> unit) -> t
  val onKeyDown : (Event.Keyboard.t -> unit) -> t
  val onKeyPress : (Event.Keyboard.t -> unit) -> t
  val onKeyUp : (Event.Keyboard.t -> unit) -> t
  val onFocus : (Event.Focus.t -> unit) -> t
  val onBlur : (Event.Focus.t -> unit) -> t
  val onChange : (Event.Form.t -> unit) -> t
  val onInput : (Event.Form.t -> unit) -> t
  val onSubmit : (Event.Form.t -> unit) -> t
  val onInvalid : (Event.Form.t -> unit) -> t
  val onClick : (Event.Mouse.t -> unit) -> t
  val onContextMenu : (Event.Mouse.t -> unit) -> t
  val onDoubleClick : (Event.Mouse.t -> unit) -> t
  val onDrag : (Event.Mouse.t -> unit) -> t
  val onDragEnd : (Event.Mouse.t -> unit) -> t
  val onDragEnter : (Event.Mouse.t -> unit) -> t
  val onDragExit : (Event.Mouse.t -> unit) -> t
  val onDragLeave : (Event.Mouse.t -> unit) -> t
  val onDragOver : (Event.Mouse.t -> unit) -> t
  val onDragStart : (Event.Mouse.t -> unit) -> t
  val onDrop : (Event.Mouse.t -> unit) -> t
  val onMouseDown : (Event.Mouse.t -> unit) -> t
  val onMouseEnter : (Event.Mouse.t -> unit) -> t
  val onMouseLeave : (Event.Mouse.t -> unit) -> t
  val onMouseMove : (Event.Mouse.t -> unit) -> t
  val onMouseOut : (Event.Mouse.t -> unit) -> t
  val onMouseOver : (Event.Mouse.t -> unit) -> t
  val onMouseUp : (Event.Mouse.t -> unit) -> t
  val onSelect : (Event.Selection.t -> unit) -> t
  val onTouchCancel : (Event.Touch.t -> unit) -> t
  val onTouchEnd : (Event.Touch.t -> unit) -> t
  val onTouchMove : (Event.Touch.t -> unit) -> t
  val onTouchStart : (Event.Touch.t -> unit) -> t
  val onPointerOver : (Event.Pointer.t -> unit) -> t
  val onPointerEnter : (Event.Pointer.t -> unit) -> t
  val onPointerDown : (Event.Pointer.t -> unit) -> t
  val onPointerMove : (Event.Pointer.t -> unit) -> t
  val onPointerUp : (Event.Pointer.t -> unit) -> t
  val onPointerCancel : (Event.Pointer.t -> unit) -> t
  val onPointerOut : (Event.Pointer.t -> unit) -> t
  val onPointerLeave : (Event.Pointer.t -> unit) -> t
  val onGotPointerCapture : (Event.Pointer.t -> unit) -> t
  val onLostPointerCapture : (Event.Pointer.t -> unit) -> t
  val onScroll : (Event.UI.t -> unit) -> t
  val onWheel : (Event.Wheel.t -> unit) -> t
  val onAbort : (Event.Media.t -> unit) -> t
  val onCanPlay : (Event.Media.t -> unit) -> t
  val onCanPlayThrough : (Event.Media.t -> unit) -> t
  val onDurationChange : (Event.Media.t -> unit) -> t
  val onEmptied : (Event.Media.t -> unit) -> t
  val onEncrypted : (Event.Media.t -> unit) -> t
  val onEnded : (Event.Media.t -> unit) -> t
  val onError : (Event.Media.t -> unit) -> t
  val onLoadedData : (Event.Media.t -> unit) -> t
  val onLoadedMetadata : (Event.Media.t -> unit) -> t
  val onLoadStart : (Event.Media.t -> unit) -> t
  val onPause : (Event.Media.t -> unit) -> t
  val onPlay : (Event.Media.t -> unit) -> t
  val onPlaying : (Event.Media.t -> unit) -> t
  val onProgress : (Event.Media.t -> unit) -> t
  val onRateChange : (Event.Media.t -> unit) -> t
  val onSeeked : (Event.Media.t -> unit) -> t
  val onSeeking : (Event.Media.t -> unit) -> t
  val onStalled : (Event.Media.t -> unit) -> t
  val onSuspend : (Event.Media.t -> unit) -> t
  val onTimeUpdate : (Event.Media.t -> unit) -> t
  val onVolumeChange : (Event.Media.t -> unit) -> t
  val onWaiting : (Event.Media.t -> unit) -> t
  val onLoad : (Event.Image.t -> unit) -> t
  val onAnimationStart : (Event.Animation.t -> unit) -> t
  val onAnimationEnd : (Event.Animation.t -> unit) -> t
  val onAnimationIteration : (Event.Animation.t -> unit) -> t
  val onTransitionEnd : (Event.Transition.t -> unit) -> t
  val dangerouslySetInnerHTML : Dom.SafeString.t -> t
  val suppressContentEditableWarning : bool -> t
end

include module type of Prop

(** Common *)

module Context : sig
  module Provider : sig
    val make :
      'a Core.Context.t -> value:'a -> Core.element list -> Core.element
  end
end

val fragment : Core.element list -> Core.element
val none : Core.element
val string : string -> Core.element
val int : int -> Core.element
val float : float -> Core.element
val maybe : ('a -> Core.element) -> 'a option -> Core.element
val h : string -> Prop.t array -> Core.element list -> Core.element

(** HTML elements *)

val a : Prop.t array -> Core.element list -> Core.element
val abbr : Prop.t array -> Core.element list -> Core.element
val address : Prop.t array -> Core.element list -> Core.element
val area : Prop.t array -> Core.element list -> Core.element
val article : Prop.t array -> Core.element list -> Core.element
val aside : Prop.t array -> Core.element list -> Core.element
val audio : Prop.t array -> Core.element list -> Core.element
val b : Prop.t array -> Core.element list -> Core.element
val base : Prop.t array -> Core.element list -> Core.element
val bdi : Prop.t array -> Core.element list -> Core.element
val bdo : Prop.t array -> Core.element list -> Core.element
val big : Prop.t array -> Core.element list -> Core.element
val blockquote : Prop.t array -> Core.element list -> Core.element
val body : Prop.t array -> Core.element list -> Core.element
val br : Prop.t array -> Core.element list -> Core.element
val button : Prop.t array -> Core.element list -> Core.element
val canvas : Prop.t array -> Core.element list -> Core.element
val caption : Prop.t array -> Core.element list -> Core.element
val cite : Prop.t array -> Core.element list -> Core.element
val code : Prop.t array -> Core.element list -> Core.element
val col : Prop.t array -> Core.element list -> Core.element
val colgroup : Prop.t array -> Core.element list -> Core.element
val data : Prop.t array -> Core.element list -> Core.element
val datalist : Prop.t array -> Core.element list -> Core.element
val dd : Prop.t array -> Core.element list -> Core.element
val del : Prop.t array -> Core.element list -> Core.element
val details : Prop.t array -> Core.element list -> Core.element
val dfn : Prop.t array -> Core.element list -> Core.element
val dialog : Prop.t array -> Core.element list -> Core.element
val div : Prop.t array -> Core.element list -> Core.element
val dl : Prop.t array -> Core.element list -> Core.element
val dt : Prop.t array -> Core.element list -> Core.element
val em : Prop.t array -> Core.element list -> Core.element
val embed : Prop.t array -> Core.element list -> Core.element
val fieldset : Prop.t array -> Core.element list -> Core.element
val figcaption : Prop.t array -> Core.element list -> Core.element
val figure : Prop.t array -> Core.element list -> Core.element
val footer : Prop.t array -> Core.element list -> Core.element
val form : Prop.t array -> Core.element list -> Core.element
val h1 : Prop.t array -> Core.element list -> Core.element
val h2 : Prop.t array -> Core.element list -> Core.element
val h3 : Prop.t array -> Core.element list -> Core.element
val h4 : Prop.t array -> Core.element list -> Core.element
val h5 : Prop.t array -> Core.element list -> Core.element
val h6 : Prop.t array -> Core.element list -> Core.element
val head : Prop.t array -> Core.element list -> Core.element
val header : Prop.t array -> Core.element list -> Core.element
val hr : Prop.t array -> Core.element list -> Core.element
val html : Prop.t array -> Core.element list -> Core.element
val i : Prop.t array -> Core.element list -> Core.element
val iframe : Prop.t array -> Core.element list -> Core.element
val img : Prop.t array -> Core.element list -> Core.element
val input : Prop.t array -> Core.element list -> Core.element
val ins : Prop.t array -> Core.element list -> Core.element
val kbd : Prop.t array -> Core.element list -> Core.element
val keygen : Prop.t array -> Core.element list -> Core.element
val label : Prop.t array -> Core.element list -> Core.element
val legend : Prop.t array -> Core.element list -> Core.element
val li : Prop.t array -> Core.element list -> Core.element
val link : Prop.t array -> Core.element list -> Core.element
val main : Prop.t array -> Core.element list -> Core.element
val map : Prop.t array -> Core.element list -> Core.element
val mark : Prop.t array -> Core.element list -> Core.element
val menu : Prop.t array -> Core.element list -> Core.element
val menuitem : Prop.t array -> Core.element list -> Core.element
val meta : Prop.t array -> Core.element list -> Core.element
val meter : Prop.t array -> Core.element list -> Core.element
val nav : Prop.t array -> Core.element list -> Core.element
val noscript : Prop.t array -> Core.element list -> Core.element
val object_ : Prop.t array -> Core.element list -> Core.element
val ol : Prop.t array -> Core.element list -> Core.element
val optgroup : Prop.t array -> Core.element list -> Core.element
val option : Prop.t array -> Core.element list -> Core.element
val output : Prop.t array -> Core.element list -> Core.element
val p : Prop.t array -> Core.element list -> Core.element
val param : Prop.t array -> Core.element list -> Core.element
val picture : Prop.t array -> Core.element list -> Core.element
val pre : Prop.t array -> Core.element list -> Core.element
val progress : Prop.t array -> Core.element list -> Core.element
val q : Prop.t array -> Core.element list -> Core.element
val rp : Prop.t array -> Core.element list -> Core.element
val rt : Prop.t array -> Core.element list -> Core.element
val ruby : Prop.t array -> Core.element list -> Core.element
val s : Prop.t array -> Core.element list -> Core.element
val samp : Prop.t array -> Core.element list -> Core.element
val script : Prop.t array -> Core.element list -> Core.element
val section : Prop.t array -> Core.element list -> Core.element
val select : Prop.t array -> Core.element list -> Core.element
val small : Prop.t array -> Core.element list -> Core.element
val source : Prop.t array -> Core.element list -> Core.element
val span : Prop.t array -> Core.element list -> Core.element
val strong : Prop.t array -> Core.element list -> Core.element
val style : Prop.t array -> Core.element list -> Core.element
val sub : Prop.t array -> Core.element list -> Core.element
val summary : Prop.t array -> Core.element list -> Core.element
val sup : Prop.t array -> Core.element list -> Core.element
val table : Prop.t array -> Core.element list -> Core.element
val tbody : Prop.t array -> Core.element list -> Core.element
val td : Prop.t array -> Core.element list -> Core.element
val textarea : Prop.t array -> Core.element list -> Core.element
val tfoot : Prop.t array -> Core.element list -> Core.element
val th : Prop.t array -> Core.element list -> Core.element
val thead : Prop.t array -> Core.element list -> Core.element
val time : Prop.t array -> Core.element list -> Core.element
val title : Prop.t array -> Core.element list -> Core.element
val tr : Prop.t array -> Core.element list -> Core.element
val track : Prop.t array -> Core.element list -> Core.element
val u : Prop.t array -> Core.element list -> Core.element
val ul : Prop.t array -> Core.element list -> Core.element
val var : Prop.t array -> Core.element list -> Core.element
val video : Prop.t array -> Core.element list -> Core.element
val wbr : Prop.t array -> Core.element list -> Core.element
