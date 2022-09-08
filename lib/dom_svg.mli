module Prop : sig
  include module type of Dom_aria_attributes

  type t = Dom_dsl_core.Prop.t

  (** Common *)

  val any : string -> 'a -> t
  val bool : string -> bool -> t
  val int : string -> int -> t
  val float_ : string -> float -> t
  val event : string -> ('a Event.synthetic -> unit) -> t
  val key : string -> t
  val ref_ : Dom.dom_ref -> t

  (** Modifiers *)

  val maybe : ('a -> t) -> 'a option -> t

  (** SVG props *)

  val accentHeight : string -> t
  val accumulate : string -> t
  val additive : string -> t
  val alignmentBaseline : string -> t
  val allowReorder : string -> t
  val alphabetic : string -> t
  val amplitude : string -> t
  val arabicForm : string -> t
  val ascent : string -> t
  val attributeName : string -> t
  val attributeType : string -> t
  val autoReverse : string -> t
  val azimuth : string -> t
  val baseFrequency : string -> t
  val baseProfile : string -> t
  val baselineShift : string -> t
  val bbox : string -> t
  val begin_ : string -> t
  val bias : string -> t
  val by : string -> t
  val calcMode : string -> t
  val capHeight : string -> t
  val className : string -> t
  val classNames : string list -> t
  val clip : string -> t
  val clipPath : string -> t
  val clipPathUnits : string -> t
  val clipRule : string -> t
  val colorInterpolation : string -> t
  val colorInterpolationFilters : string -> t
  val colorProfile : string -> t
  val colorRendering : string -> t
  val contentScriptType : string -> t
  val contentStyleType : string -> t
  val cursor : string -> t
  val cx : string -> t
  val cy : string -> t
  val d : string -> t
  val decelerate : string -> t
  val descent : string -> t
  val diffuseConstant : string -> t
  val direction : string -> t
  val display : string -> t
  val divisor : string -> t
  val dominantBaseline : string -> t
  val dur : string -> t
  val dx : string -> t
  val dy : string -> t
  val edgeMode : string -> t
  val elevation : string -> t
  val enableBackground : string -> t
  val end_ : string -> t
  val exponent : string -> t
  val externalResourcesRequired : string -> t
  val fill : string -> t
  val fillOpacity : string -> t
  val fillRule : string -> t
  val filter : string -> t
  val filterRes : string -> t
  val filterUnits : string -> t
  val floodColor : string -> t
  val floodOpacity : string -> t
  val focusable : string -> t
  val fontFamily : string -> t
  val fontSize : string -> t
  val fontSizeAdjust : string -> t
  val fontStretch : string -> t
  val fontStyle : string -> t
  val fontVariant : string -> t
  val fontWeight : string -> t
  val fomat : string -> t
  val from : string -> t
  val fx : string -> t
  val fy : string -> t
  val g1 : string -> t
  val g2 : string -> t
  val glyphName : string -> t
  val glyphOrientationHorizontal : string -> t
  val glyphOrientationVertical : string -> t
  val glyphRef : string -> t
  val gradientTransform : string -> t
  val gradientUnits : string -> t
  val hanging : string -> t
  val height : string -> t
  val horizAdvX : string -> t
  val horizOriginX : string -> t
  val href : string -> t
  val id : string -> t
  val ideographic : string -> t
  val imageRendering : string -> t
  val in_ : string -> t
  val in2 : string -> t
  val intercept : string -> t
  val k : string -> t
  val k1 : string -> t
  val k2 : string -> t
  val k3 : string -> t
  val k4 : string -> t
  val kernelMatrix : string -> t
  val kernelUnitLength : string -> t
  val kerning : string -> t
  val keyPoints : string -> t
  val keySplines : string -> t
  val keyTimes : string -> t
  val lang : string -> t
  val lengthAdjust : string -> t
  val letterSpacing : string -> t
  val lightingColor : string -> t
  val limitingConeAngle : string -> t
  val local : string -> t
  val markerEnd : string -> t
  val markerHeight : string -> t
  val markerMid : string -> t
  val markerStart : string -> t
  val markerUnits : string -> t
  val markerWidth : string -> t
  val mask : string -> t
  val maskContentUnits : string -> t
  val maskUnits : string -> t
  val mathematical : string -> t
  val mode : string -> t
  val numOctaves : string -> t
  val offset : string -> t
  val opacity : string -> t
  val operator : string -> t
  val order : string -> t
  val orient : string -> t
  val orientation : string -> t
  val origin : string -> t
  val overflow : string -> t
  val overflowX : string -> t
  val overflowY : string -> t
  val overlinePosition : string -> t
  val overlineThickness : string -> t
  val paintOrder : string -> t
  val panose1 : string -> t
  val pathLength : string -> t
  val patternContentUnits : string -> t
  val patternTransform : string -> t
  val patternUnits : string -> t
  val pointerEvents : string -> t
  val points : string -> t
  val pointsAtX : string -> t
  val pointsAtY : string -> t
  val pointsAtZ : string -> t
  val preserveAlpha : string -> t
  val preserveAspectRatio : string -> t
  val primitiveUnits : string -> t
  val r : string -> t
  val radius : string -> t
  val refX : string -> t
  val refY : string -> t
  val renderingIntent : string -> t
  val repeatCount : string -> t
  val repeatDur : string -> t
  val requiredExtensions : string -> t
  val requiredFeatures : string -> t
  val restart : string -> t
  val result : string -> t
  val rotate : string -> t
  val rx : string -> t
  val ry : string -> t
  val scale : string -> t
  val seed : string -> t
  val shapeRendering : string -> t
  val slope : string -> t
  val spacing : string -> t
  val specularConstant : string -> t
  val specularExponent : string -> t
  val speed : string -> t
  val spreadMethod : string -> t
  val startOffset : string -> t
  val stdDeviation : string -> t
  val stemh : string -> t
  val stemv : string -> t
  val stitchTiles : string -> t
  val stopColor : string -> t
  val stopOpacity : string -> t
  val strikethroughPosition : string -> t
  val strikethroughThickness : string -> t
  val string : string -> t
  val stroke : string -> t
  val strokeDasharray : string -> t
  val strokeDashoffset : string -> t
  val strokeLinecap : string -> t
  val strokeLinejoin : string -> t
  val strokeMiterlimit : string -> t
  val strokeOpacity : string -> t
  val strokeWidth : string -> t
  val style : Dom.Style.t -> t
  val surfaceScale : string -> t
  val systemLanguage : string -> t
  val tabIndex : int -> t
  val tableValues : string -> t
  val targetX : string -> t
  val targetY : string -> t
  val textAnchor : string -> t
  val textDecoration : string -> t
  val textLength : string -> t
  val textRendering : string -> t
  val to_ : string -> t
  val transform : string -> t
  val u1 : string -> t
  val u2 : string -> t
  val underlinePosition : string -> t
  val underlineThickness : string -> t
  val unicode : string -> t
  val unicodeBidi : string -> t
  val unicodeRange : string -> t
  val unitsPerEm : string -> t
  val vAlphabetic : string -> t
  val vHanging : string -> t
  val vIdeographic : string -> t
  val vMathematical : string -> t
  val values : string -> t
  val vectorEffect : string -> t
  val version : string -> t
  val vertAdvX : string -> t
  val vertAdvY : string -> t
  val vertOriginX : string -> t
  val vertOriginY : string -> t
  val viewBox : string -> t
  val viewTarget : string -> t
  val visibility : string -> t
  val width : string -> t
  val widths : string -> t
  val wordSpacing : string -> t
  val writingMode : string -> t
  val x : string -> t
  val x1 : string -> t
  val x2 : string -> t
  val xChannelSelector : string -> t
  val xHeight : string -> t
  val xlinkActuate : string -> t
  val xlinkArcrole : string -> t
  val xlinkHref : string -> t
  val xlinkRole : string -> t
  val xlinkShow : string -> t
  val xlinkTitle : string -> t
  val xlinkType : string -> t
  val xmlns : string -> t
  val xmlnsXlink : string -> t
  val xmlBase : string -> t
  val xmlLang : string -> t
  val xmlSpace : string -> t
  val y : string -> t
  val y1 : string -> t
  val y2 : string -> t
  val yChannelSelector : string -> t
  val z : string -> t
  val zoomAndPan : string -> t
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

(** SVG elements *)

val a : Prop.t array -> Core.element list -> Core.element
val animate : Prop.t array -> Core.element list -> Core.element
val animateMotion : Prop.t array -> Core.element list -> Core.element
val animateTransform : Prop.t array -> Core.element list -> Core.element
val circle : Prop.t array -> Core.element list -> Core.element
val clipPath : Prop.t array -> Core.element list -> Core.element
val defs : Prop.t array -> Core.element list -> Core.element
val desc : Prop.t array -> Core.element list -> Core.element
val discard : Prop.t array -> Core.element list -> Core.element
val ellipse : Prop.t array -> Core.element list -> Core.element
val feBlend : Prop.t array -> Core.element list -> Core.element
val feColorMatrix : Prop.t array -> Core.element list -> Core.element
val feComponentTransfer : Prop.t array -> Core.element list -> Core.element
val feComposite : Prop.t array -> Core.element list -> Core.element
val feConvolveMatrix : Prop.t array -> Core.element list -> Core.element
val feDiffuseLighting : Prop.t array -> Core.element list -> Core.element
val feDisplacementMap : Prop.t array -> Core.element list -> Core.element
val feDistantLight : Prop.t array -> Core.element list -> Core.element
val feDropShadow : Prop.t array -> Core.element list -> Core.element
val feFlood : Prop.t array -> Core.element list -> Core.element
val feFuncA : Prop.t array -> Core.element list -> Core.element
val feFuncB : Prop.t array -> Core.element list -> Core.element
val feFuncG : Prop.t array -> Core.element list -> Core.element
val feFuncR : Prop.t array -> Core.element list -> Core.element
val feGaussianBlur : Prop.t array -> Core.element list -> Core.element
val feImage : Prop.t array -> Core.element list -> Core.element
val feMerge : Prop.t array -> Core.element list -> Core.element
val feMergeNode : Prop.t array -> Core.element list -> Core.element
val feMorphology : Prop.t array -> Core.element list -> Core.element
val feOffset : Prop.t array -> Core.element list -> Core.element
val fePointLight : Prop.t array -> Core.element list -> Core.element
val feSpecularLighting : Prop.t array -> Core.element list -> Core.element
val feSpotLight : Prop.t array -> Core.element list -> Core.element
val feTile : Prop.t array -> Core.element list -> Core.element
val feTurbulence : Prop.t array -> Core.element list -> Core.element
val filter : Prop.t array -> Core.element list -> Core.element
val foreignObject : Prop.t array -> Core.element list -> Core.element
val g : Prop.t array -> Core.element list -> Core.element
val hatch : Prop.t array -> Core.element list -> Core.element
val hatchpath : Prop.t array -> Core.element list -> Core.element
val image : Prop.t array -> Core.element list -> Core.element
val line : Prop.t array -> Core.element list -> Core.element
val linearGradient : Prop.t array -> Core.element list -> Core.element
val marker : Prop.t array -> Core.element list -> Core.element
val mask : Prop.t array -> Core.element list -> Core.element
val metadata : Prop.t array -> Core.element list -> Core.element
val mpath : Prop.t array -> Core.element list -> Core.element
val path : Prop.t array -> Core.element list -> Core.element
val pattern : Prop.t array -> Core.element list -> Core.element
val polygon : Prop.t array -> Core.element list -> Core.element
val polyline : Prop.t array -> Core.element list -> Core.element
val radialGradient : Prop.t array -> Core.element list -> Core.element
val rect : Prop.t array -> Core.element list -> Core.element
val script : Prop.t array -> Core.element list -> Core.element
val set : Prop.t array -> Core.element list -> Core.element
val stop : Prop.t array -> Core.element list -> Core.element
val style : Prop.t array -> Core.element list -> Core.element
val svg : Prop.t array -> Core.element list -> Core.element
val switch : Prop.t array -> Core.element list -> Core.element
val symbol : Prop.t array -> Core.element list -> Core.element
val text : Prop.t array -> Core.element list -> Core.element
val textPath : Prop.t array -> Core.element list -> Core.element
val title : Prop.t array -> Core.element list -> Core.element
val tspan : Prop.t array -> Core.element list -> Core.element
val use : Prop.t array -> Core.element list -> Core.element
val view : Prop.t array -> Core.element list -> Core.element
