val renderToString : React.element -> string
(** renderToString renders a React tree to an HTML string.contents *)

val renderToStaticMarkup : React.element -> string
(** renderToStaticMarkup renders a non-interactive React tree to an HTML string. *)

val renderToLwtStream : React.element -> string Lwt_stream.t * (unit -> unit)
(** renderToPipeableStream renders a React tree to a Lwt_stream.t. *)

val querySelector : 'a -> 'b option

val render : 'a -> 'b -> 'c
(** Do nothing on the server *)

val hydrate : 'a -> 'b -> 'c
(** Do nothing on the server *)

val createPortal : 'a -> 'b -> 'a
(** Do nothing on the server *)

module Style = ReactDOMStyle
(** ReactDOM.Style generates the inline styles for the `style` prop. *)

val createDOMElementVariadic :
  string -> props:React.JSX.prop array -> React.element array -> React.element
(** Create a React.element by giving the HTML tag, an array of props and children *)

type dangerouslySetInnerHTML = { __html : string } [@@boxed]

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
  ?onCopy:(ReactEvent.Clipboard.t -> unit) ->
  ?onCut:(ReactEvent.Clipboard.t -> unit) ->
  ?onPaste:(ReactEvent.Clipboard.t -> unit) ->
  ?onCompositionEnd:(ReactEvent.Composition.t -> unit) ->
  ?onCompositionStart:(ReactEvent.Composition.t -> unit) ->
  ?onCompositionUpdate:(ReactEvent.Composition.t -> unit) ->
  ?onKeyDown:(ReactEvent.Keyboard.t -> unit) ->
  ?onKeyPress:(ReactEvent.Keyboard.t -> unit) ->
  ?onKeyUp:(ReactEvent.Keyboard.t -> unit) ->
  ?onFocus:(ReactEvent.Focus.t -> unit) ->
  ?onBlur:(ReactEvent.Focus.t -> unit) ->
  ?onChange:(ReactEvent.Form.t -> unit) ->
  ?onInput:(ReactEvent.Form.t -> unit) ->
  ?onSubmit:(ReactEvent.Form.t -> unit) ->
  ?onInvalid:(ReactEvent.Form.t -> unit) ->
  ?onClick:(ReactEvent.Mouse.t -> unit) ->
  ?onContextMenu:(ReactEvent.Mouse.t -> unit) ->
  ?onDoubleClick:(ReactEvent.Mouse.t -> unit) ->
  ?onDrag:(ReactEvent.Mouse.t -> unit) ->
  ?onDragEnd:(ReactEvent.Mouse.t -> unit) ->
  ?onDragEnter:(ReactEvent.Mouse.t -> unit) ->
  ?onDragExit:(ReactEvent.Mouse.t -> unit) ->
  ?onDragLeave:(ReactEvent.Mouse.t -> unit) ->
  ?onDragOver:(ReactEvent.Mouse.t -> unit) ->
  ?onDragStart:(ReactEvent.Mouse.t -> unit) ->
  ?onDrop:(ReactEvent.Mouse.t -> unit) ->
  ?onMouseDown:(ReactEvent.Mouse.t -> unit) ->
  ?onMouseEnter:(ReactEvent.Mouse.t -> unit) ->
  ?onMouseLeave:(ReactEvent.Mouse.t -> unit) ->
  ?onMouseMove:(ReactEvent.Mouse.t -> unit) ->
  ?onMouseOut:(ReactEvent.Mouse.t -> unit) ->
  ?onMouseOver:(ReactEvent.Mouse.t -> unit) ->
  ?onMouseUp:(ReactEvent.Mouse.t -> unit) ->
  ?onSelect:(ReactEvent.Selection.t -> unit) ->
  ?onTouchCancel:(ReactEvent.Touch.t -> unit) ->
  ?onTouchEnd:(ReactEvent.Touch.t -> unit) ->
  ?onTouchMove:(ReactEvent.Touch.t -> unit) ->
  ?onTouchStart:(ReactEvent.Touch.t -> unit) ->
  ?onPointerOver:(ReactEvent.Pointer.t -> unit) ->
  ?onPointerEnter:(ReactEvent.Pointer.t -> unit) ->
  ?onPointerDown:(ReactEvent.Pointer.t -> unit) ->
  ?onPointerMove:(ReactEvent.Pointer.t -> unit) ->
  ?onPointerUp:(ReactEvent.Pointer.t -> unit) ->
  ?onPointerCancel:(ReactEvent.Pointer.t -> unit) ->
  ?onPointerOut:(ReactEvent.Pointer.t -> unit) ->
  ?onPointerLeave:(ReactEvent.Pointer.t -> unit) ->
  ?onGotPointerCapture:(ReactEvent.Pointer.t -> unit) ->
  ?onLostPointerCapture:(ReactEvent.Pointer.t -> unit) ->
  ?onScroll:(ReactEvent.UI.t -> unit) ->
  ?onWheel:(ReactEvent.Wheel.t -> unit) ->
  ?onAbort:(ReactEvent.Media.t -> unit) ->
  ?onCanPlay:(ReactEvent.Media.t -> unit) ->
  ?onCanPlayThrough:(ReactEvent.Media.t -> unit) ->
  ?onDurationChange:(ReactEvent.Media.t -> unit) ->
  ?onEmptied:(ReactEvent.Media.t -> unit) ->
  ?onEncrypetd:(ReactEvent.Media.t -> unit) ->
  ?onEnded:(ReactEvent.Media.t -> unit) ->
  ?onError:(ReactEvent.Media.t -> unit) ->
  ?onLoadedData:(ReactEvent.Media.t -> unit) ->
  ?onLoadedMetadata:(ReactEvent.Media.t -> unit) ->
  ?onLoadStart:(ReactEvent.Media.t -> unit) ->
  ?onPause:(ReactEvent.Media.t -> unit) ->
  ?onPlay:(ReactEvent.Media.t -> unit) ->
  ?onPlaying:(ReactEvent.Media.t -> unit) ->
  ?onProgress:(ReactEvent.Media.t -> unit) ->
  ?onRateChange:(ReactEvent.Media.t -> unit) ->
  ?onSeeked:(ReactEvent.Media.t -> unit) ->
  ?onSeeking:(ReactEvent.Media.t -> unit) ->
  ?onStalled:(ReactEvent.Media.t -> unit) ->
  ?onSuspend:(ReactEvent.Media.t -> unit) ->
  ?onTimeUpdate:(ReactEvent.Media.t -> unit) ->
  ?onVolumeChange:(ReactEvent.Media.t -> unit) ->
  ?onWaiting:(ReactEvent.Media.t -> unit) ->
  ?onAnimationStart:(ReactEvent.Animation.t -> unit) ->
  ?onAnimationEnd:(ReactEvent.Animation.t -> unit) ->
  ?onAnimationIteration:(ReactEvent.Animation.t -> unit) ->
  ?onTransitionEnd:(ReactEvent.Transition.t -> unit) ->
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
  React.JSX.prop array

module Ref = React.Ref
