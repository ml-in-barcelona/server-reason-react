(** The ReactDOM library *)

val renderToString : React.element -> string
(** renderToString renders a React tree to as an HTML string.

    Similar to {:https://react.dev/reference/react-dom/server/renderToString} *)

val renderToStaticMarkup : React.element -> string
(** renderToStaticMarkup renders a non-interactive React tree to an HTML string.

    Similar to {:https://react.dev/reference/react-dom/server/renderToStaticMarkup} *)

val renderToStream : ?pipe:(string -> unit Lwt.t) -> React.element -> (string Lwt_stream.t * (unit -> unit)) Lwt.t
(** renderToStream renders a React tree into a Lwt_stream.t.

    Similar to {:https://react.dev/reference/react-dom/server/renderToPipeableStream} *)

val attributes_to_html : React.JSX.prop list -> Html.attribute list
(** attributes_to_html converts a list of React.JSX.prop to a list of Html.attribute. *)

val getDangerouslyInnerHtml : React.JSX.prop list -> string option
(** getDangerouslyInnerHtml returns the value of the dangerouslySetInnerHTML prop if it exists, otherwise None. *)

val write_to_buffer : Buffer.t -> React.element -> unit
val escape_to_buffer : Buffer.t -> string -> unit

(** {2: The rest of the API is there for compatibility with ReactDOM's reason-react} *)

module Ref = React.Ref

type domRef = Ref.t

val querySelector : 'a -> 'b option
(** Does nothing on the server, always returns None *)

val render : 'a -> 'b -> 'c
(** Does nothing on the server *)

val hydrate : 'a -> 'b -> 'c
(** Does nothing on the server *)

val createPortal : 'a -> 'b -> 'a
(** Does nothing on the server *)

module Style = ReactDOMStyle
(** ReactDOM.Style generates the inline styles for the `style` prop. *)

val createDOMElementVariadic : string -> props:React.JSX.prop list -> React.element array -> React.element
(** Create a React.element by giving the HTML tag, an array of props and children *)

type dangerouslySetInnerHTML = < __html : string >

(* JSX props for HTML and SVG elements, including React specific ones. *)
val domProps :
  ?key:string ->
  ?ref:React.domRef ->
  ?ariaDetails:string ->
  ?ariaDisabled:bool ->
  ?ariaHidden:bool ->
  ?ariaKeyshortcuts:string ->
  ?ariaLabel:string ->
  ?ariaRoledescription:string ->
  ?ariaExpanded:bool ->
  ?ariaLevel:int ->
  ?ariaModal:bool ->
  ?ariaMultiline:bool ->
  ?ariaMultiselectable:bool ->
  ?ariaPlaceholder:string ->
  ?ariaReadonly:bool ->
  ?ariaRequired:bool ->
  ?ariaSelected:bool ->
  ?ariaSort:string ->
  ?ariaValuemax:float ->
  ?ariaValuemin:float ->
  ?ariaValuenow:float ->
  ?ariaValuetext:string ->
  ?ariaAtomic:bool ->
  ?ariaBusy:bool ->
  ?ariaRelevant:string ->
  ?ariaGrabbed:bool ->
  ?ariaActivedescendant:string ->
  ?ariaColcount:int ->
  ?ariaColindex:int ->
  ?ariaColspan:int ->
  ?ariaControls:string ->
  ?ariaDescribedby:string ->
  ?ariaErrormessage:string ->
  ?ariaFlowto:string ->
  ?ariaLabelledby:string ->
  ?ariaOwns:string ->
  ?ariaPosinset:int ->
  ?ariaRowcount:int ->
  ?ariaRowindex:int ->
  ?ariaRowspan:int ->
  ?ariaSetsize:int ->
  ?defaultChecked:bool ->
  ?defaultValue:string ->
  ?accessKey:string ->
  ?className:string ->
  ?contentEditable:bool ->
  ?contextMenu:string ->
  ?dir:string ->
  ?draggable:bool ->
  ?hidden:bool ->
  ?id:string ->
  ?lang:string ->
  ?role:string ->
  ?style:ReactDOMStyle.t ->
  ?spellCheck:bool ->
  ?tabIndex:int ->
  ?title:string ->
  ?itemID:string ->
  ?itemProp:string ->
  ?itemRef:string ->
  ?itemScope:bool ->
  ?itemType:string ->
  ?accept:string ->
  ?acceptCharset:string ->
  ?action:string ->
  ?allowFullScreen:bool ->
  ?alt:string ->
  ?async:bool ->
  ?autoComplete:string ->
  ?autoCapitalize:string ->
  ?autoFocus:bool ->
  ?autoPlay:bool ->
  ?challenge:string ->
  ?charSet:string ->
  ?checked:bool ->
  ?cite:string ->
  ?crossOrigin:string ->
  ?cols:int ->
  ?colSpan:int ->
  ?content:string ->
  ?controls:bool ->
  ?coords:string ->
  ?data:string ->
  ?dateTime:string ->
  ?default:bool ->
  ?defer:bool ->
  ?disabled:bool ->
  ?download:string ->
  ?encType:string ->
  ?form:string ->
  ?formAction:string ->
  ?formTarget:string ->
  ?formMethod:string ->
  ?headers:string ->
  ?height:string ->
  ?high:int ->
  ?href:string ->
  ?hrefLang:string ->
  ?htmlFor:string ->
  ?httpEquiv:string ->
  ?icon:string ->
  ?inputMode:string ->
  ?integrity:string ->
  ?keyType:string ->
  ?kind:string ->
  ?label:string ->
  ?list:string ->
  ?loop:bool ->
  ?low:int ->
  ?manifest:string ->
  ?max:string ->
  ?maxLength:int ->
  ?media:string ->
  ?mediaGroup:string ->
  ?method_:string ->
  ?min:string ->
  ?minLength:int ->
  ?multiple:bool ->
  ?muted:bool ->
  ?name:string ->
  ?nonce:string ->
  ?noValidate:bool ->
  ?open_:bool ->
  ?optimum:int ->
  ?pattern:string ->
  ?placeholder:string ->
  ?playsInline:bool ->
  ?poster:string ->
  ?preload:string ->
  ?radioGroup:string ->
  ?readOnly:bool ->
  ?rel:string ->
  ?required:bool ->
  ?reversed:bool ->
  ?rows:int ->
  ?rowSpan:int ->
  ?sandbox:string ->
  ?scope:string ->
  ?scoped:bool ->
  ?scrolling:string ->
  ?selected:bool ->
  ?shape:string ->
  ?size:int ->
  ?sizes:string ->
  ?span:int ->
  ?src:string ->
  ?srcDoc:string ->
  ?srcLang:string ->
  ?srcSet:string ->
  ?start:int ->
  ?step:float ->
  ?summary:string ->
  ?target:string ->
  ?type_:string ->
  ?useMap:string ->
  ?value:string ->
  ?width:string ->
  ?wrap:string ->
  ?onCopy:(React.Event.Clipboard.t -> unit) ->
  ?onCut:(React.Event.Clipboard.t -> unit) ->
  ?onPaste:(React.Event.Clipboard.t -> unit) ->
  ?onCompositionEnd:(React.Event.Composition.t -> unit) ->
  ?onCompositionStart:(React.Event.Composition.t -> unit) ->
  ?onCompositionUpdate:(React.Event.Composition.t -> unit) ->
  ?onKeyDown:(React.Event.Keyboard.t -> unit) ->
  ?onKeyPress:(React.Event.Keyboard.t -> unit) ->
  ?onKeyUp:(React.Event.Keyboard.t -> unit) ->
  ?onFocus:(React.Event.Focus.t -> unit) ->
  ?onBlur:(React.Event.Focus.t -> unit) ->
  ?onChange:(React.Event.Form.t -> unit) ->
  ?onInput:(React.Event.Form.t -> unit) ->
  ?onSubmit:(React.Event.Form.t -> unit) ->
  ?onInvalid:(React.Event.Form.t -> unit) ->
  ?onClick:(React.Event.Mouse.t -> unit) ->
  ?onContextMenu:(React.Event.Mouse.t -> unit) ->
  ?onDoubleClick:(React.Event.Mouse.t -> unit) ->
  ?onDrag:(React.Event.Mouse.t -> unit) ->
  ?onDragEnd:(React.Event.Mouse.t -> unit) ->
  ?onDragEnter:(React.Event.Mouse.t -> unit) ->
  ?onDragExit:(React.Event.Mouse.t -> unit) ->
  ?onDragLeave:(React.Event.Mouse.t -> unit) ->
  ?onDragOver:(React.Event.Mouse.t -> unit) ->
  ?onDragStart:(React.Event.Mouse.t -> unit) ->
  ?onDrop:(React.Event.Mouse.t -> unit) ->
  ?onMouseDown:(React.Event.Mouse.t -> unit) ->
  ?onMouseEnter:(React.Event.Mouse.t -> unit) ->
  ?onMouseLeave:(React.Event.Mouse.t -> unit) ->
  ?onMouseMove:(React.Event.Mouse.t -> unit) ->
  ?onMouseOut:(React.Event.Mouse.t -> unit) ->
  ?onMouseOver:(React.Event.Mouse.t -> unit) ->
  ?onMouseUp:(React.Event.Mouse.t -> unit) ->
  ?onSelect:(React.Event.Selection.t -> unit) ->
  ?onTouchCancel:(React.Event.Touch.t -> unit) ->
  ?onTouchEnd:(React.Event.Touch.t -> unit) ->
  ?onTouchMove:(React.Event.Touch.t -> unit) ->
  ?onTouchStart:(React.Event.Touch.t -> unit) ->
  ?onPointerOver:(React.Event.Pointer.t -> unit) ->
  ?onPointerEnter:(React.Event.Pointer.t -> unit) ->
  ?onPointerDown:(React.Event.Pointer.t -> unit) ->
  ?onPointerMove:(React.Event.Pointer.t -> unit) ->
  ?onPointerUp:(React.Event.Pointer.t -> unit) ->
  ?onPointerCancel:(React.Event.Pointer.t -> unit) ->
  ?onPointerOut:(React.Event.Pointer.t -> unit) ->
  ?onPointerLeave:(React.Event.Pointer.t -> unit) ->
  ?onGotPointerCapture:(React.Event.Pointer.t -> unit) ->
  ?onLostPointerCapture:(React.Event.Pointer.t -> unit) ->
  ?onScroll:(React.Event.UI.t -> unit) ->
  ?onWheel:(React.Event.Wheel.t -> unit) ->
  ?onAbort:(React.Event.Media.t -> unit) ->
  ?onCanPlay:(React.Event.Media.t -> unit) ->
  ?onCanPlayThrough:(React.Event.Media.t -> unit) ->
  ?onDurationChange:(React.Event.Media.t -> unit) ->
  ?onEmptied:(React.Event.Media.t -> unit) ->
  ?onEncrypetd:(React.Event.Media.t -> unit) ->
  ?onEnded:(React.Event.Media.t -> unit) ->
  ?onError:(React.Event.Media.t -> unit) ->
  ?onLoadedData:(React.Event.Media.t -> unit) ->
  ?onLoadedMetadata:(React.Event.Media.t -> unit) ->
  ?onLoadStart:(React.Event.Media.t -> unit) ->
  ?onPause:(React.Event.Media.t -> unit) ->
  ?onPlay:(React.Event.Media.t -> unit) ->
  ?onPlaying:(React.Event.Media.t -> unit) ->
  ?onProgress:(React.Event.Media.t -> unit) ->
  ?onRateChange:(React.Event.Media.t -> unit) ->
  ?onSeeked:(React.Event.Media.t -> unit) ->
  ?onSeeking:(React.Event.Media.t -> unit) ->
  ?onStalled:(React.Event.Media.t -> unit) ->
  ?onSuspend:(React.Event.Media.t -> unit) ->
  ?onTimeUpdate:(React.Event.Media.t -> unit) ->
  ?onVolumeChange:(React.Event.Media.t -> unit) ->
  ?onWaiting:(React.Event.Media.t -> unit) ->
  ?onAnimationStart:(React.Event.Animation.t -> unit) ->
  ?onAnimationEnd:(React.Event.Animation.t -> unit) ->
  ?onAnimationIteration:(React.Event.Animation.t -> unit) ->
  ?onTransitionEnd:(React.Event.Transition.t -> unit) ->
  ?accentHeight:string ->
  ?accumulate:string ->
  ?additive:string ->
  ?alignmentBaseline:string ->
  ?allowReorder:string ->
  ?alphabetic:string ->
  ?amplitude:string ->
  ?arabicForm:string ->
  ?ascent:string ->
  ?attributeName:string ->
  ?attributeType:string ->
  ?autoReverse:string ->
  ?azimuth:string ->
  ?baseFrequency:string ->
  ?baseProfile:string ->
  ?baselineShift:string ->
  ?bbox:string ->
  ?begin_:string ->
  ?bias:string ->
  ?by:string ->
  ?calcMode:string ->
  ?capHeight:string ->
  ?clip:string ->
  ?clipPath:string ->
  ?clipPathUnits:string ->
  ?clipRule:string ->
  ?colorInterpolation:string ->
  ?colorInterpolationFilters:string ->
  ?colorProfile:string ->
  ?colorRendering:string ->
  ?contentScriptType:string ->
  ?contentStyleType:string ->
  ?cursor:string ->
  ?cx:string ->
  ?cy:string ->
  ?d:string ->
  ?decelerate:string ->
  ?descent:string ->
  ?diffuseConstant:string ->
  ?direction:string ->
  ?display:string ->
  ?divisor:string ->
  ?dominantBaseline:string ->
  ?dur:string ->
  ?dx:string ->
  ?dy:string ->
  ?edgeMode:string ->
  ?elevation:string ->
  ?enableBackground:string ->
  ?end_:string ->
  ?exponent:string ->
  ?externalResourcesRequired:string ->
  ?fill:string ->
  ?fillOpacity:string ->
  ?fillRule:string ->
  ?filter:string ->
  ?filterRes:string ->
  ?filterUnits:string ->
  ?floodColor:string ->
  ?floodOpacity:string ->
  ?focusable:string ->
  ?fontFamily:string ->
  ?fontSize:string ->
  ?fontSizeAdjust:string ->
  ?fontStretch:string ->
  ?fontStyle:string ->
  ?fontVariant:string ->
  ?fontWeight:string ->
  ?fomat:string ->
  ?from:string ->
  ?fx:string ->
  ?fy:string ->
  ?g1:string ->
  ?g2:string ->
  ?glyphName:string ->
  ?glyphOrientationHorizontal:string ->
  ?glyphOrientationVertical:string ->
  ?glyphRef:string ->
  ?gradientTransform:string ->
  ?gradientUnits:string ->
  ?hanging:string ->
  ?horizAdvX:string ->
  ?horizOriginX:string ->
  ?ideographic:string ->
  ?imageRendering:string ->
  ?in_:string ->
  ?in2:string ->
  ?intercept:string ->
  ?k:string ->
  ?k1:string ->
  ?k2:string ->
  ?k3:string ->
  ?k4:string ->
  ?kernelMatrix:string ->
  ?kernelUnitLength:string ->
  ?kerning:string ->
  ?keyPoints:string ->
  ?keySplines:string ->
  ?keyTimes:string ->
  ?lengthAdjust:string ->
  ?letterSpacing:string ->
  ?lightingColor:string ->
  ?limitingConeAngle:string ->
  ?local:string ->
  ?markerEnd:string ->
  ?markerHeight:string ->
  ?markerMid:string ->
  ?markerStart:string ->
  ?markerUnits:string ->
  ?markerWidth:string ->
  ?mask:string ->
  ?maskContentUnits:string ->
  ?maskUnits:string ->
  ?mathematical:string ->
  ?mode:string ->
  ?numOctaves:string ->
  ?offset:string ->
  ?opacity:string ->
  ?operator:string ->
  ?order:string ->
  ?orient:string ->
  ?orientation:string ->
  ?origin:string ->
  ?overflow:string ->
  ?overflowX:string ->
  ?overflowY:string ->
  ?overlinePosition:string ->
  ?overlineThickness:string ->
  ?paintOrder:string ->
  ?panose1:string ->
  ?pathLength:string ->
  ?patternContentUnits:string ->
  ?patternTransform:string ->
  ?patternUnits:string ->
  ?pointerEvents:string ->
  ?points:string ->
  ?pointsAtX:string ->
  ?pointsAtY:string ->
  ?pointsAtZ:string ->
  ?preserveAlpha:string ->
  ?preserveAspectRatio:string ->
  ?primitiveUnits:string ->
  ?r:string ->
  ?radius:string ->
  ?refX:string ->
  ?refY:string ->
  ?renderingIntent:string ->
  ?repeatCount:string ->
  ?repeatDur:string ->
  ?requiredExtensions:string ->
  ?requiredFeatures:string ->
  ?restart:string ->
  ?result:string ->
  ?rotate:string ->
  ?rx:string ->
  ?ry:string ->
  ?scale:string ->
  ?seed:string ->
  ?shapeRendering:string ->
  ?slope:string ->
  ?spacing:string ->
  ?specularConstant:string ->
  ?specularExponent:string ->
  ?speed:string ->
  ?spreadMethod:string ->
  ?startOffset:string ->
  ?stdDeviation:string ->
  ?stemh:string ->
  ?stemv:string ->
  ?stitchTiles:string ->
  ?stopColor:string ->
  ?stopOpacity:string ->
  ?strikethroughPosition:string ->
  ?strikethroughThickness:string ->
  ?stroke:string ->
  ?strokeDasharray:string ->
  ?strokeDashoffset:string ->
  ?strokeLinecap:string ->
  ?strokeLinejoin:string ->
  ?strokeMiterlimit:string ->
  ?strokeOpacity:string ->
  ?strokeWidth:string ->
  ?surfaceScale:string ->
  ?systemLanguage:string ->
  ?tableValues:string ->
  ?targetX:string ->
  ?targetY:string ->
  ?textAnchor:string ->
  ?textDecoration:string ->
  ?textLength:string ->
  ?textRendering:string ->
  ?to_:string ->
  ?transform:string ->
  ?u1:string ->
  ?u2:string ->
  ?underlinePosition:string ->
  ?underlineThickness:string ->
  ?unicode:string ->
  ?unicodeBidi:string ->
  ?unicodeRange:string ->
  ?unitsPerEm:string ->
  ?vAlphabetic:string ->
  ?vHanging:string ->
  ?vIdeographic:string ->
  ?vMathematical:string ->
  ?values:string ->
  ?vectorEffect:string ->
  ?version:string ->
  ?vertAdvX:string ->
  ?vertAdvY:string ->
  ?vertOriginX:string ->
  ?vertOriginY:string ->
  ?viewBox:string ->
  ?viewTarget:string ->
  ?visibility:string ->
  ?widths:string ->
  ?wordSpacing:string ->
  ?writingMode:string ->
  ?x:string ->
  ?x1:string ->
  ?x2:string ->
  ?xChannelSelector:string ->
  ?xHeight:string ->
  ?xlinkActuate:string ->
  ?xlinkArcrole:string ->
  ?xlinkHref:string ->
  ?xlinkRole:string ->
  ?xlinkShow:string ->
  ?xlinkTitle:string ->
  ?xlinkType:string ->
  ?xmlns:string ->
  ?xmlnsXlink:string ->
  ?xmlBase:string ->
  ?xmlLang:string ->
  ?xmlSpace:string ->
  ?y:string ->
  ?y1:string ->
  ?y2:string ->
  ?yChannelSelector:string ->
  ?z:string ->
  ?zoomAndPan:string ->
  ?about:string ->
  ?datatype:string ->
  ?inlist:string ->
  ?prefix:string ->
  ?property:string ->
  ?resource:string ->
  ?typeof:string ->
  ?vocab:string ->
  ?dangerouslySetInnerHTML:dangerouslySetInnerHTML ->
  ?suppressContentEditableWarning:bool ->
  ?suppressHydrationWarning:bool ->
  unit ->
  React.JSX.prop list
