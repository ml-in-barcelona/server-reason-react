open React

let attribute_name_to_jsx k =
  match k with
  | "className" -> "class"
  | "htmlFor" -> "for"
  (* serialize defaultX props to the X attribute *)
  (* FIXME: Add link *)
  | "defaultValue" -> "value"
  | "defaultChecked" -> "checked"
  | "defaultSelected" -> "selected"
  | _ -> k

let is_onclick_event event =
  match event with
  | Attribute.Event (name, _) when String.equal name "_onclick" -> true
  | _ -> false

let attribute_is_html tag attr_name =
  match DomProps.findByName tag attr_name with Ok _ -> true | Error _ -> false

let replace_reserved_names attr =
  match attr with "type" -> "type_" | "as" -> "as_" | _ -> attr

let get_key = function
  | Attribute.Bool (k, _) -> k
  | String (k, _) -> replace_reserved_names k
  | Ref _ -> "ref"
  | DangerouslyInnerHtml _ -> "dangerouslySetInnerHTML"
  | Style _ -> "style"
  | Event (name, _) -> (* FIXME: tolowercase? does it even matter? *) name

let is_react_custom_attribute attr =
  match get_key attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning"
  | "suppressHydrationWarning" ->
      true
  | _ -> false

let attribute_is_not_event attr =
  match attr with
  (* We treat _onclick as "not an event", so attribute_is_valid turns it true *)
  | Attribute.Event _ as event when is_onclick_event event -> true
  | Event _ -> false
  | _ -> true

let attribute_is_valid tag attr =
  attribute_is_html tag (get_key attr)
  && attribute_is_not_event attr
  && not (is_react_custom_attribute attr)

let attribute_to_string attr =
  match attr with
  (* ignores "ref" prop *)
  | Attribute.Ref _ -> ""
  (* false attributes don't get rendered *)
  | Bool (_, false) -> ""
  (* true attributes render solely the attribute name *)
  | Bool (k, true) -> k
  (* Since we extracted the attribute as children (Element.InnerHtml),
     we don't want to render anything here *)
  | DangerouslyInnerHtml _ -> ""
  (* We ignore events on SSR, the only exception is "_onclick" which renders as string onclick *)
  | Event (name, Inline value) when String.equal name "_onclick" ->
      Printf.sprintf "onclick=\"%s\"" value
  | Event _ -> ""
  | Style styles -> Printf.sprintf "style=\"%s\"" styles
  | String (k, v) ->
      Printf.sprintf "%s=\"%s\"" (attribute_name_to_jsx k) (Html.encode v)

let attributes_to_string tag attrs =
  let valid_attributes =
    attrs |> Array.to_list
    |> List.filter_map (fun attr ->
           if attribute_is_valid tag attr then Some (attribute_to_string attr)
           else None)
  in
  match valid_attributes with
  | [] -> ""
  | rest -> " " ^ (rest |> String.concat " " |> String.trim)

let react_root_attr_name = "data-reactroot"
let data_react_root_attr = Printf.sprintf " %s=\"\"" react_root_attr_name

type mode = String | Markup

let render_tree ~mode element =
  let buff = Buffer.create 16 in
  let push = Buffer.add_string buff in
  (* is_root starts at true (when renderToString) and only goes to false
     when renders an lower-case element or closed element *)
  let is_mode_to_string = mode = String in
  let is_root = ref is_mode_to_string in
  (* previous_was_text_node is the flag to enable rendering comments
     <!-- --> between text nodes *)
  let previous_was_text_node = ref false in
  let rec render_inner element =
    let root_attribute =
      match is_root.contents with true -> data_react_root_attr | false -> ""
    in
    match element with
    | Empty -> push ""
    | Provider childrens ->
        childrens |> List.map (fun f -> f ()) |> List.iter render_inner
    | Consumer children -> children () |> List.iter render_inner
    | Fragment children -> render_inner children
    | List list -> list |> Array.iter render_inner
    | Upper_case_component f -> render_inner (f ())
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        is_root.contents <- false;
        push "<";
        push tag;
        push (attributes_to_string tag attributes);
        push " />"
    | Lower_case_element { tag; attributes; children } ->
        is_root.contents <- false;
        push "<";
        push tag;
        push root_attribute;
        push (attributes_to_string tag attributes);
        push ">";
        children |> List.iter render_inner;
        push "</";
        push tag;
        push ">"
    | Text text -> (
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        match mode with
        | String when is_previous_text_node ->
            push (Printf.sprintf "<!-- -->%s" (Html.encode text))
        | _ -> push (Html.encode text))
    | InnerHtml text -> push text
  in
  render_inner element;
  buff |> Buffer.contents

let renderToString element = render_tree ~mode:String element
let renderToStaticMarkup element = render_tree ~mode:Markup element
let querySelector _str = None

let fail_impossible_action_in_ssr =
  (* failwith seems bad, but I don't know any other way
     of warning the user without changing the types. Doing a unit *)
  (* failwith
     (Printf.sprintf "render shouldn't run on the server %s, line %d" __FILE__
        __LINE__) *)
  ()

let render _element _node = fail_impossible_action_in_ssr
let hydrate _element _node = fail_impossible_action_in_ssr
let createPortal _reactElement _domElement = _reactElement

module Style = ReactDOMStyle

type domRef
type dangerouslySetInnerHTML = { __html : string } [@@boxed]

type domProps = {
  key : string option; [@optional]
  ref : domRef option; [@optional] [@as "aria-activedescendant"]
  ariaActivedescendant : string option; [@optional] [@as "aria-atomic"]
  ariaAtomic : bool option; [@optional] [@as "aria-autocomplete"]
  ariaAutocomplete : string option; [@optional] [@as "aria-busy"]
  ariaBusy : bool option; [@optional] [@as "aria-checked"]
  ariaChecked : string option; [@optional] [@as "aria-colcount"]
  ariaColcount : int option; [@optional] [@as "aria-colindex"]
  ariaColindex : int option; [@optional] [@as "aria-colspan"]
  ariaColspan : int option; [@optional] [@as "aria-controls"]
  ariaControls : string option; [@optional] [@as "aria-current"]
  ariaCurrent : string option; [@optional] [@as "aria-describedby"]
  ariaDescribedby : string option; [@optional] [@as "aria-details"]
  ariaDetails : string option; [@optional] [@as "aria-disabled"]
  ariaDisabled : bool option; [@optional] [@as "aria-errormessage"]
  ariaErrormessage : string option; [@optional] [@as "aria-expanded"]
  ariaExpanded : bool option; [@optional] [@as "aria-flowto"]
  ariaFlowto : string option; [@optional] [@as "aria-grabbed"]
  ariaGrabbed : bool option; [@optional] [@as "aria-haspopup"]
  ariaHaspopup : string option; [@optional] [@as "aria-hidden"]
  ariaHidden : bool option; [@optional] [@as "aria-invalid"]
  ariaInvalid : string option; [@optional] [@as "aria-keyshortcuts"]
  ariaKeyshortcuts : string option; [@optional] [@as "aria-label"]
  ariaLabel : string option; [@optional] [@as "aria-labelledby"]
  ariaLabelledby : string option; [@optional] [@as "aria-level"]
  ariaLevel : int option; [@optional] [@as "aria-live"]
  ariaLive : string option; [@optional] [@as "aria-modal"]
  ariaModal : bool option; [@optional] [@as "aria-multiline"]
  ariaMultiline : bool option; [@optional] [@as "aria-multiselectable"]
  ariaMultiselectable : bool option; [@optional] [@as "aria-orientation"]
  ariaOrientation : string option; [@optional] [@as "aria-owns"]
  ariaOwns : string option; [@optional] [@as "aria-placeholder"]
  ariaPlaceholder : string option; [@optional] [@as "aria-posinset"]
  ariaPosinset : int option; [@optional] [@as "aria-pressed"]
  ariaPressed : string option; [@optional] [@as "aria-readonly"]
  ariaReadonly : bool option; [@optional] [@as "aria-relevant"]
  ariaRelevant : string option; [@optional] [@as "aria-required"]
  ariaRequired : bool option; [@optional] [@as "aria-roledescription"]
  ariaRoledescription : string option; [@optional] [@as "aria-rowcount"]
  ariaRowcount : int option; [@optional] [@as "aria-rowindex"]
  ariaRowindex : int option; [@optional] [@as "aria-rowindextext"]
  ariaRowindextext : string option; [@optional] [@as "aria-rowspan"]
  ariaRowspan : int option; [@optional] [@as "aria-selected"]
  ariaSelected : bool option; [@optional] [@as "aria-setsize"]
  ariaSetsize : int option; [@optional] [@as "aria-sort"]
  ariaSort : string option; [@optional] [@as "aria-valuemax"]
  ariaValuemax : float option; [@optional] [@as "aria-valuemin"]
  ariaValuemin : float option; [@optional] [@as "aria-valuenow"]
  ariaValuenow : float option; [@optional] [@as "aria-valuetext"]
  ariaValuetext : string option; [@optional]
  defaultChecked : bool option; [@optional]
  defaultValue : string option; [@optional]
  accessKey : string option; [@optional]
  className : string option; [@optional]
  contentEditable : bool option; [@optional]
  contextMenu : string option; [@optional]
  dir : string option; [@optional]
  draggable : bool option; [@optional]
  hidden : bool option; [@optional]
  id : string option; [@optional]
  lang : string option; [@optional]
  role : string option; [@optional]
  style : ReactDOMStyle.t option; [@optional]
  spellCheck : bool option; [@optional]
  tabIndex : int option; [@optional]
  title : string option; [@optional]
  itemID : string option; [@optional]
  itemProp : string option; [@optional]
  itemRef : string option; [@optional]
  itemScope : bool option; [@optional]
  itemType : string option; [@optional] [@as "as"]
  as_ : string option; [@optional]
  accept : string option; [@optional]
  acceptCharset : string option; [@optional]
  action : string option; [@optional]
  allowFullScreen : bool option; [@optional]
  alt : string option; [@optional]
  async : bool option; [@optional]
  autoComplete : string option; [@optional]
  autoCapitalize : string option; [@optional]
  autoFocus : bool option; [@optional]
  autoPlay : bool option; [@optional]
  challenge : string option; [@optional]
  charSet : string option; [@optional]
  checked : bool option; [@optional]
  cite : string option; [@optional]
  crossOrigin : string option; [@optional]
  cols : int option; [@optional]
  colSpan : int option; [@optional]
  content : string option; [@optional]
  controls : bool option; [@optional]
  coords : string option; [@optional]
  data : string option; [@optional]
  dateTime : string option; [@optional]
  default : bool option; [@optional]
  defer : bool option; [@optional]
  disabled : bool option; [@optional]
  download : string option; [@optional]
  encType : string option; [@optional]
  form : string option; [@optional]
  formAction : string option; [@optional]
  formTarget : string option; [@optional]
  formMethod : string option; [@optional]
  headers : string option; [@optional]
  height : string option; [@optional]
  high : int option; [@optional]
  href : string option; [@optional]
  hrefLang : string option; [@optional]
  htmlFor : string option; [@optional]
  httpEquiv : string option; [@optional]
  icon : string option; [@optional]
  inputMode : string option; [@optional]
  integrity : string option; [@optional]
  keyType : string option; [@optional]
  kind : string option; [@optional]
  label : string option; [@optional]
  list : string option; [@optional]
  loop : bool option; [@optional]
  low : int option; [@optional]
  manifest : string option; [@optional]
  max : string option; [@optional]
  maxLength : int option; [@optional]
  media : string option; [@optional]
  mediaGroup : string option; [@optional] [@as "method"]
  method_ : string option; [@optional]
  min : string option; [@optional]
  minLength : int option; [@optional]
  multiple : bool option; [@optional]
  muted : bool option; [@optional]
  name : string option; [@optional]
  nonce : string option; [@optional]
  noValidate : bool option; [@optional] [@as "open"]
  open_ : bool option; [@optional]
  optimum : int option; [@optional]
  pattern : string option; [@optional]
  placeholder : string option; [@optional]
  playsInline : bool option; [@optional]
  poster : string option; [@optional]
  preload : string option; [@optional]
  radioGroup : string option; [@optional]
  readOnly : bool option; [@optional]
  rel : string option; [@optional]
  required : bool option; [@optional]
  reversed : bool option; [@optional]
  rows : int option; [@optional]
  rowSpan : int option; [@optional]
  sandbox : string option; [@optional]
  scope : string option; [@optional]
  scoped : bool option; [@optional]
  scrolling : string option; [@optional]
  selected : bool option; [@optional]
  shape : string option; [@optional]
  size : int option; [@optional]
  sizes : string option; [@optional]
  span : int option; [@optional]
  src : string option; [@optional]
  srcDoc : string option; [@optional]
  srcLang : string option; [@optional]
  srcSet : string option; [@optional]
  start : int option; [@optional]
  step : float option; [@optional]
  summary : string option; [@optional]
  target : string option; [@optional] [@as "type"]
  type_ : string option; [@optional]
  useMap : string option; [@optional]
  value : string option; [@optional]
  width : string option; [@optional]
  wrap : string option; [@optional]
  onCopy : (ReactEvent.Clipboard.t -> unit) option; [@optional]
  onCut : (ReactEvent.Clipboard.t -> unit) option; [@optional]
  onPaste : (ReactEvent.Clipboard.t -> unit) option; [@optional]
  onCompositionEnd : (ReactEvent.Composition.t -> unit) option; [@optional]
  onCompositionStart : (ReactEvent.Composition.t -> unit) option; [@optional]
  onCompositionUpdate : (ReactEvent.Composition.t -> unit) option; [@optional]
  onKeyDown : (ReactEvent.Keyboard.t -> unit) option; [@optional]
  onKeyPress : (ReactEvent.Keyboard.t -> unit) option; [@optional]
  onKeyUp : (ReactEvent.Keyboard.t -> unit) option; [@optional]
  onFocus : (ReactEvent.Focus.t -> unit) option; [@optional]
  onBlur : (ReactEvent.Focus.t -> unit) option; [@optional]
  onChange : (ReactEvent.Form.t -> unit) option; [@optional]
  onInput : (ReactEvent.Form.t -> unit) option; [@optional]
  onSubmit : (ReactEvent.Form.t -> unit) option; [@optional]
  onInvalid : (ReactEvent.Form.t -> unit) option; [@optional]
  onClick : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onContextMenu : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onDoubleClick : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onDrag : (ReactEvent.Drag.t -> unit) option; [@optional]
  onDragEnd : (ReactEvent.Drag.t -> unit) option; [@optional]
  onDragEnter : (ReactEvent.Drag.t -> unit) option; [@optional]
  onDragExit : (ReactEvent.Drag.t -> unit) option; [@optional]
  onDragLeave : (ReactEvent.Drag.t -> unit) option; [@optional]
  onDragOver : (ReactEvent.Drag.t -> unit) option; [@optional]
  onDragStart : (ReactEvent.Drag.t -> unit) option; [@optional]
  onDrop : (ReactEvent.Drag.t -> unit) option; [@optional]
  onMouseDown : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onMouseEnter : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onMouseLeave : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onMouseMove : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onMouseOut : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onMouseOver : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onMouseUp : (ReactEvent.Mouse.t -> unit) option; [@optional]
  onSelect : (ReactEvent.Selection.t -> unit) option; [@optional]
  onTouchCancel : (ReactEvent.Touch.t -> unit) option; [@optional]
  onTouchEnd : (ReactEvent.Touch.t -> unit) option; [@optional]
  onTouchMove : (ReactEvent.Touch.t -> unit) option; [@optional]
  onTouchStart : (ReactEvent.Touch.t -> unit) option; [@optional]
  onPointerOver : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onPointerEnter : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onPointerDown : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onPointerMove : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onPointerUp : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onPointerCancel : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onPointerOut : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onPointerLeave : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onGotPointerCapture : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onLostPointerCapture : (ReactEvent.Pointer.t -> unit) option; [@optional]
  onScroll : (ReactEvent.UI.t -> unit) option; [@optional]
  onWheel : (ReactEvent.Wheel.t -> unit) option; [@optional]
  onAbort : (ReactEvent.Media.t -> unit) option; [@optional]
  onCanPlay : (ReactEvent.Media.t -> unit) option; [@optional]
  onCanPlayThrough : (ReactEvent.Media.t -> unit) option; [@optional]
  onDurationChange : (ReactEvent.Media.t -> unit) option; [@optional]
  onEmptied : (ReactEvent.Media.t -> unit) option; [@optional]
  onEncrypetd : (ReactEvent.Media.t -> unit) option; [@optional]
  onEnded : (ReactEvent.Media.t -> unit) option; [@optional]
  onError : (ReactEvent.Media.t -> unit) option; [@optional]
  onLoadedData : (ReactEvent.Media.t -> unit) option; [@optional]
  onLoadedMetadata : (ReactEvent.Media.t -> unit) option; [@optional]
  onLoadStart : (ReactEvent.Media.t -> unit) option; [@optional]
  onPause : (ReactEvent.Media.t -> unit) option; [@optional]
  onPlay : (ReactEvent.Media.t -> unit) option; [@optional]
  onPlaying : (ReactEvent.Media.t -> unit) option; [@optional]
  onProgress : (ReactEvent.Media.t -> unit) option; [@optional]
  onRateChange : (ReactEvent.Media.t -> unit) option; [@optional]
  onSeeked : (ReactEvent.Media.t -> unit) option; [@optional]
  onSeeking : (ReactEvent.Media.t -> unit) option; [@optional]
  onStalled : (ReactEvent.Media.t -> unit) option; [@optional]
  onSuspend : (ReactEvent.Media.t -> unit) option; [@optional]
  onTimeUpdate : (ReactEvent.Media.t -> unit) option; [@optional]
  onVolumeChange : (ReactEvent.Media.t -> unit) option; [@optional]
  onWaiting : (ReactEvent.Media.t -> unit) option; [@optional]
  onLoad : (ReactEvent.Image.t -> unit) option; [@optional]
  onAnimationStart : (ReactEvent.Animation.t -> unit) option; [@optional]
  onAnimationEnd : (ReactEvent.Animation.t -> unit) option; [@optional]
  onAnimationIteration : (ReactEvent.Animation.t -> unit) option; [@optional]
  onTransitionEnd : (ReactEvent.Transition.t -> unit) option; [@optional]
  accentHeight : string option; [@optional]
  accumulate : string option; [@optional]
  additive : string option; [@optional]
  alignmentBaseline : string option; [@optional]
  allowReorder : string option; [@optional]
  alphabetic : string option; [@optional]
  amplitude : string option; [@optional]
  arabicForm : string option; [@optional]
  ascent : string option; [@optional]
  attributeName : string option; [@optional]
  attributeType : string option; [@optional]
  autoReverse : string option; [@optional]
  azimuth : string option; [@optional]
  baseFrequency : string option; [@optional]
  baseProfile : string option; [@optional]
  baselineShift : string option; [@optional]
  bbox : string option; [@optional] [@as "begin"]
  begin_ : string option; [@optional]
  bias : string option; [@optional]
  by : string option; [@optional]
  calcMode : string option; [@optional]
  capHeight : string option; [@optional]
  clip : string option; [@optional]
  clipPath : string option; [@optional]
  clipPathUnits : string option; [@optional]
  clipRule : string option; [@optional]
  colorInterpolation : string option; [@optional]
  colorInterpolationFilters : string option; [@optional]
  colorProfile : string option; [@optional]
  colorRendering : string option; [@optional]
  contentScriptType : string option; [@optional]
  contentStyleType : string option; [@optional]
  cursor : string option; [@optional]
  cx : string option; [@optional]
  cy : string option; [@optional]
  d : string option; [@optional]
  decelerate : string option; [@optional]
  descent : string option; [@optional]
  diffuseConstant : string option; [@optional]
  direction : string option; [@optional]
  display : string option; [@optional]
  divisor : string option; [@optional]
  dominantBaseline : string option; [@optional]
  dur : string option; [@optional]
  dx : string option; [@optional]
  dy : string option; [@optional]
  edgeMode : string option; [@optional]
  elevation : string option; [@optional]
  enableBackground : string option; [@optional] [@as "end"]
  end_ : string option; [@optional]
  exponent : string option; [@optional]
  externalResourcesRequired : string option; [@optional]
  fill : string option; [@optional]
  fillOpacity : string option; [@optional]
  fillRule : string option; [@optional]
  filter : string option; [@optional]
  filterRes : string option; [@optional]
  filterUnits : string option; [@optional]
  floodColor : string option; [@optional]
  floodOpacity : string option; [@optional]
  focusable : string option; [@optional]
  fontFamily : string option; [@optional]
  fontSize : string option; [@optional]
  fontSizeAdjust : string option; [@optional]
  fontStretch : string option; [@optional]
  fontStyle : string option; [@optional]
  fontVariant : string option; [@optional]
  fontWeight : string option; [@optional]
  fomat : string option; [@optional]
  from : string option; [@optional]
  fx : string option; [@optional]
  fy : string option; [@optional]
  g1 : string option; [@optional]
  g2 : string option; [@optional]
  glyphName : string option; [@optional]
  glyphOrientationHorizontal : string option; [@optional]
  glyphOrientationVertical : string option; [@optional]
  glyphRef : string option; [@optional]
  gradientTransform : string option; [@optional]
  gradientUnits : string option; [@optional]
  hanging : string option; [@optional]
  horizAdvX : string option; [@optional]
  horizOriginX : string option; [@optional]
  ideographic : string option; [@optional]
  imageRendering : string option; [@optional] [@as "in"]
  in_ : string option; [@optional]
  in2 : string option; [@optional]
  intercept : string option; [@optional]
  k : string option; [@optional]
  k1 : string option; [@optional]
  k2 : string option; [@optional]
  k3 : string option; [@optional]
  k4 : string option; [@optional]
  kernelMatrix : string option; [@optional]
  kernelUnitLength : string option; [@optional]
  kerning : string option; [@optional]
  keyPoints : string option; [@optional]
  keySplines : string option; [@optional]
  keyTimes : string option; [@optional]
  lengthAdjust : string option; [@optional]
  letterSpacing : string option; [@optional]
  lightingColor : string option; [@optional]
  limitingConeAngle : string option; [@optional]
  local : string option; [@optional]
  markerEnd : string option; [@optional]
  markerHeight : string option; [@optional]
  markerMid : string option; [@optional]
  markerStart : string option; [@optional]
  markerUnits : string option; [@optional]
  markerWidth : string option; [@optional]
  mask : string option; [@optional]
  maskContentUnits : string option; [@optional]
  maskUnits : string option; [@optional]
  mathematical : string option; [@optional]
  mode : string option; [@optional]
  numOctaves : string option; [@optional]
  offset : string option; [@optional]
  opacity : string option; [@optional]
  operator : string option; [@optional]
  order : string option; [@optional]
  orient : string option; [@optional]
  orientation : string option; [@optional]
  origin : string option; [@optional]
  overflow : string option; [@optional]
  overflowX : string option; [@optional]
  overflowY : string option; [@optional]
  overlinePosition : string option; [@optional]
  overlineThickness : string option; [@optional]
  paintOrder : string option; [@optional]
  panose1 : string option; [@optional]
  pathLength : string option; [@optional]
  patternContentUnits : string option; [@optional]
  patternTransform : string option; [@optional]
  patternUnits : string option; [@optional]
  pointerEvents : string option; [@optional]
  points : string option; [@optional]
  pointsAtX : string option; [@optional]
  pointsAtY : string option; [@optional]
  pointsAtZ : string option; [@optional]
  preserveAlpha : string option; [@optional]
  preserveAspectRatio : string option; [@optional]
  primitiveUnits : string option; [@optional]
  r : string option; [@optional]
  radius : string option; [@optional]
  refX : string option; [@optional]
  refY : string option; [@optional]
  renderingIntent : string option; [@optional]
  repeatCount : string option; [@optional]
  repeatDur : string option; [@optional]
  requiredExtensions : string option; [@optional]
  requiredFeatures : string option; [@optional]
  restart : string option; [@optional]
  result : string option; [@optional]
  rotate : string option; [@optional]
  rx : string option; [@optional]
  ry : string option; [@optional]
  scale : string option; [@optional]
  seed : string option; [@optional]
  shapeRendering : string option; [@optional]
  slope : string option; [@optional]
  spacing : string option; [@optional]
  specularConstant : string option; [@optional]
  specularExponent : string option; [@optional]
  speed : string option; [@optional]
  spreadMethod : string option; [@optional]
  startOffset : string option; [@optional]
  stdDeviation : string option; [@optional]
  stemh : string option; [@optional]
  stemv : string option; [@optional]
  stitchTiles : string option; [@optional]
  stopColor : string option; [@optional]
  stopOpacity : string option; [@optional]
  strikethroughPosition : string option; [@optional]
  strikethroughThickness : string option; [@optional]
  stroke : string option; [@optional]
  strokeDasharray : string option; [@optional]
  strokeDashoffset : string option; [@optional]
  strokeLinecap : string option; [@optional]
  strokeLinejoin : string option; [@optional]
  strokeMiterlimit : string option; [@optional]
  strokeOpacity : string option; [@optional]
  strokeWidth : string option; [@optional]
  surfaceScale : string option; [@optional]
  systemLanguage : string option; [@optional]
  tableValues : string option; [@optional]
  targetX : string option; [@optional]
  targetY : string option; [@optional]
  textAnchor : string option; [@optional]
  textDecoration : string option; [@optional]
  textLength : string option; [@optional]
  textRendering : string option; [@optional] [@as "to"]
  to_ : string option; [@optional]
  transform : string option; [@optional]
  u1 : string option; [@optional]
  u2 : string option; [@optional]
  underlinePosition : string option; [@optional]
  underlineThickness : string option; [@optional]
  unicode : string option; [@optional]
  unicodeBidi : string option; [@optional]
  unicodeRange : string option; [@optional]
  unitsPerEm : string option; [@optional]
  vAlphabetic : string option; [@optional]
  vHanging : string option; [@optional]
  vIdeographic : string option; [@optional]
  vMathematical : string option; [@optional]
  values : string option; [@optional]
  vectorEffect : string option; [@optional]
  version : string option; [@optional]
  vertAdvX : string option; [@optional]
  vertAdvY : string option; [@optional]
  vertOriginX : string option; [@optional]
  vertOriginY : string option; [@optional]
  viewBox : string option; [@optional]
  viewTarget : string option; [@optional]
  visibility : string option; [@optional]
  widths : string option; [@optional]
  wordSpacing : string option; [@optional]
  writingMode : string option; [@optional]
  x : string option; [@optional]
  x1 : string option; [@optional]
  x2 : string option; [@optional]
  xChannelSelector : string option; [@optional]
  xHeight : string option; [@optional]
  xlinkActuate : string option; [@optional]
  xlinkArcrole : string option; [@optional]
  xlinkHref : string option; [@optional]
  xlinkRole : string option; [@optional]
  xlinkShow : string option; [@optional]
  xlinkTitle : string option; [@optional]
  xlinkType : string option; [@optional]
  xmlns : string option; [@optional]
  xmlnsXlink : string option; [@optional]
  xmlBase : string option; [@optional]
  xmlLang : string option; [@optional]
  xmlSpace : string option; [@optional]
  y : string option; [@optional]
  y1 : string option; [@optional]
  y2 : string option; [@optional]
  yChannelSelector : string option; [@optional]
  z : string option; [@optional]
  zoomAndPan : string option; [@optional]
  about : string option; [@optional]
  datatype : string option; [@optional]
  inlist : string option; [@optional]
  prefix : string option; [@optional]
  property : string option; [@optional]
  resource : string option; [@optional]
  typeof : string option; [@optional]
  vocab : string option; [@optional]
  dangerouslySetInnerHTML : dangerouslySetInnerHTML option; [@optional]
  suppressContentEditableWarning : bool option; [@optional]
}
[@@deriving abstract]

(* let domProps ?(key : string option) ?(ref : domRef option)
     ?(ariaDetails : string option) ?(ariaDisabled : bool option)
     ?(ariaHidden : bool option) ?(ariaKeyshortcuts : string option)
     ?(ariaLabel : string option) ?(ariaRoledescription : string option)
     ?(ariaExpanded : bool option) ?(ariaLevel : int option)
     ?(ariaModal : bool option) ?(ariaMultiline : bool option)
     ?(ariaMultiselectable : bool option) ?(ariaPlaceholder : string option)
     ?(ariaReadonly : bool option) ?(ariaRequired : bool option)
     ?(ariaSelected : bool option) ?(ariaSort : string option)
     ?(ariaValuemax : float option) ?(ariaValuemin : float option)
     ?(ariaValuenow : float option) ?(ariaValuetext : string option)
     ?(ariaAtomic : bool option) ?(ariaBusy : bool option)
     ?(ariaChecked : string option) ?(ariaAutocomplete : string option)
     ?(ariaRelevant : string option) ?(ariaGrabbed : bool option)
     ?(ariaActivedescendant : string option) ?(ariaColcount : int option)
     ?(ariaColindex : int option) ?(ariaColspan : int option)
     ?(ariaControls : string option) ?(ariaDescribedby : string option)
     ?(ariaCurrent : string option) ?(ariaErrormessage : string option)
     ?(ariaFlowto : string option) ?(ariaLabelledby : string option)
     ?(ariaOwns : string option) ?(ariaPosinset : int option)
     ?(ariaRowcount : int option) ?(ariaRowindex : int option)
     ?(ariaRowspan : int option) ?(ariaSetsize : int option)
     ?(defaultChecked : bool option) ?(defaultValue : string option)
     ?(accessKey : string option) ?(className : string option)
     ?(contentEditable : bool option) ?(contextMenu : string option)
     ?(dir : string option) ?(draggable : bool option) ?(hidden : bool option)
     ?(id : string option) ?(lang : string option) ?(role : string option)
     ?(style : ReactDOMStyle.t option) ?(spellCheck : bool option)
     ?(tabIndex : int option) ?(title : string option) ?(itemID : string option)
     ?(itemProp : string option) ?(itemRef : string option)
     ?(itemScope : bool option) ?(itemType : string option)
     ?(accept : string option) ?(acceptCharset : string option)
     ?(action : string option) ?(allowFullScreen : bool option)
     ?(alt : string option) ?(async : bool option)
     ?(autoComplete : string option) ?(autoCapitalize : string option)
     ?(autoFocus : bool option) ?(autoPlay : bool option)
     ?(challenge : string option) ?(charSet : string option)
     ?(checked : bool option) ?(cite : string option)
     ?(crossOrigin : string option) ?(cols : int option) ?(colSpan : int option)
     ?(content : string option) ?(controls : bool option)
     ?(coords : string option) ?(data : string option)
     ?(dateTime : string option) ?(default : bool option) ?(defer : bool option)
     ?(disabled : bool option) ?(download : string option)
     ?(encType : string option) ?(form : string option)
     ?(formAction : string option) ?(formTarget : string option)
     ?(formMethod : string option) ?(headers : string option)
     ?(height : string option) ?(high : int option) ?(href : string option)
     ?(hrefLang : string option) ?(htmlFor : string option)
     ?(httpEquiv : string option) ?(icon : string option)
     ?(inputMode : string option) ?(integrity : string option)
     ?(keyType : string option) ?(kind : string option) ?(label : string option)
     ?(list : string option) ?(loop : bool option) ?(low : int option)
     ?(manifest : string option) ?(max : string option) ?(maxLength : int option)
     ?(media : string option) ?(mediaGroup : string option)
     ?(method_ : string option) ?(* as method *) (min : string option)
     ?(minLength : int option) ?(multiple : bool option) ?(muted : bool option)
     ?(name : string option) ?(nonce : string option) ?(noValidate : bool option)
     ?(open_ : bool option) ?(*
    as open *) (optimum : int option)
     ?(pattern : string option) ?(placeholder : string option)
     ?(playsInline : bool option) ?(poster : string option)
     ?(preload : string option) ?(radioGroup : string option)
     ?(readOnly : bool option) ?(rel : string option) ?(required : bool option)
     ?(reversed : bool option) ?(rows : int option) ?(rowSpan : int option)
     ?(sandbox : string option) ?(scope : string option) ?(scoped : bool option)
     ?(scrolling : string option) ?(selected : bool option)
     ?(shape : string option) ?(size : int option) ?(sizes : string option)
     ?(span : int option) ?(src : string option) ?(srcDoc : string option)
     ?(srcLang : string option) ?(srcSet : string option) ?(start : int option)
     ?(step : float option) ?(summary : string option) ?(target : string option)
     ?(type_ : string option) ?(* as type *) (useMap : string option)
     ?(value : string option) ?(width : string option) ?(wrap : string option)
     ?(onCopy : (ReactEvent.Clipboard.t -> unit) option)
     ?(onCut : (ReactEvent.Clipboard.t -> unit) option)
     ?(onPaste : (ReactEvent.Clipboard.t -> unit) option)
     ?(onCompositionEnd : (ReactEvent.Composition.t -> unit) option)
     ?(onCompositionStart : (ReactEvent.Composition.t -> unit) option)
     ?(onCompositionUpdate : (ReactEvent.Composition.t -> unit) option)
     ?(onKeyDown : (ReactEvent.Keyboard.t -> unit) option)
     ?(onKeyPress : (ReactEvent.Keyboard.t -> unit) option)
     ?(onKeyUp : (ReactEvent.Keyboard.t -> unit) option)
     ?(onFocus : (ReactEvent.Focus.t -> unit) option)
     ?(onBlur : (ReactEvent.Focus.t -> unit) option)
     ?(onChange : (ReactEvent.Form.t -> unit) option)
     ?(onInput : (ReactEvent.Form.t -> unit) option)
     ?(onSubmit : (ReactEvent.Form.t -> unit) option)
     ?(onInvalid : (ReactEvent.Form.t -> unit) option)
     ?(onClick : (ReactEvent.Mouse.t -> unit) option)
     ?(onContextMenu : (ReactEvent.Mouse.t -> unit) option)
     ?(onDoubleClick : (ReactEvent.Mouse.t -> unit) option)
     ?(onDrag : (ReactEvent.Drag.t -> unit) option)
     ?(onDragEnd : (ReactEvent.Drag.t -> unit) option)
     ?(onDragEnter : (ReactEvent.Drag.t -> unit) option)
     ?(onDragExit : (ReactEvent.Drag.t -> unit) option)
     ?(onDragLeave : (ReactEvent.Drag.t -> unit) option)
     ?(onDragOver : (ReactEvent.Drag.t -> unit) option)
     ?(onDragStart : (ReactEvent.Drag.t -> unit) option)
     ?(onDrop : (ReactEvent.Drag.t -> unit) option)
     ?(onMouseDown : (ReactEvent.Mouse.t -> unit) option)
     ?(onMouseEnter : (ReactEvent.Mouse.t -> unit) option)
     ?(onMouseLeave : (ReactEvent.Mouse.t -> unit) option)
     ?(onMouseMove : (ReactEvent.Mouse.t -> unit) option)
     ?(onMouseOut : (ReactEvent.Mouse.t -> unit) option)
     ?(onMouseOver : (ReactEvent.Mouse.t -> unit) option)
     ?(onMouseUp : (ReactEvent.Mouse.t -> unit) option)
     ?(onSelect : (ReactEvent.Selection.t -> unit) option)
     ?(onTouchCancel : (ReactEvent.Touch.t -> unit) option)
     ?(onTouchEnd : (ReactEvent.Touch.t -> unit) option)
     ?(onTouchMove : (ReactEvent.Touch.t -> unit) option)
     ?(onTouchStart : (ReactEvent.Touch.t -> unit) option)
     ?(onPointerOver : (ReactEvent.Pointer.t -> unit) option)
     ?(onPointerEnter : (ReactEvent.Pointer.t -> unit) option)
     ?(onPointerDown : (ReactEvent.Pointer.t -> unit) option)
     ?(onPointerMove : (ReactEvent.Pointer.t -> unit) option)
     ?(onPointerUp : (ReactEvent.Pointer.t -> unit) option)
     ?(onPointerCancel : (ReactEvent.Pointer.t -> unit) option)
     ?(onPointerOut : (ReactEvent.Pointer.t -> unit) option)
     ?(onPointerLeave : (ReactEvent.Pointer.t -> unit) option)
     ?(onGotPointerCapture : (ReactEvent.Pointer.t -> unit) option)
     ?(onLostPointerCapture : (ReactEvent.Pointer.t -> unit) option)
     ?(onScroll : (ReactEvent.UI.t -> unit) option)
     ?(onWheel : (ReactEvent.Wheel.t -> unit) option)
     ?(onAbort : (ReactEvent.Media.t -> unit) option)
     ?(onCanPlay : (ReactEvent.Media.t -> unit) option)
     ?(onCanPlayThrough : (ReactEvent.Media.t -> unit) option)
     ?(onDurationChange : (ReactEvent.Media.t -> unit) option)
     ?(onEmptied : (ReactEvent.Media.t -> unit) option)
     ?(onEncrypetd : (ReactEvent.Media.t -> unit) option)
     ?(onEnded : (ReactEvent.Media.t -> unit) option)
     ?(onError : (ReactEvent.Media.t -> unit) option)
     ?(onLoadedData : (ReactEvent.Media.t -> unit) option)
     ?(onLoadedMetadata : (ReactEvent.Media.t -> unit) option)
     ?(onLoadStart : (ReactEvent.Media.t -> unit) option)
     ?(onPause : (ReactEvent.Media.t -> unit) option)
     ?(onPlay : (ReactEvent.Media.t -> unit) option)
     ?(onPlaying : (ReactEvent.Media.t -> unit) option)
     ?(onProgress : (ReactEvent.Media.t -> unit) option)
     ?(onRateChange : (ReactEvent.Media.t -> unit) option)
     ?(onSeeked : (ReactEvent.Media.t -> unit) option)
     ?(onSeeking : (ReactEvent.Media.t -> unit) option)
     ?(onStalled : (ReactEvent.Media.t -> unit) option)
     ?(onSuspend : (ReactEvent.Media.t -> unit) option)
     ?(onTimeUpdate : (ReactEvent.Media.t -> unit) option)
     ?(onVolumeChange : (ReactEvent.Media.t -> unit) option)
     ?(onWaiting : (ReactEvent.Media.t -> unit) option)
     ?(onLoad : (ReactEvent.Image.t -> unit) option)
     ?(onAnimationStart : (ReactEvent.Animation.t -> unit) option)
     ?(onAnimationEnd : (ReactEvent.Animation.t -> unit) option)
     ?(onAnimationIteration : (ReactEvent.Animation.t -> unit) option)
     ?(onTransitionEnd : (ReactEvent.Transition.t -> unit) option)
     ?(accentHeight : string option) ?(accumulate : string option)
     ?(additive : string option) ?(alignmentBaseline : string option)
     ?(allowReorder : string option) ?(alphabetic : string option)
     ?(amplitude : string option) ?(arabicForm : string option)
     ?(ascent : string option) ?(attributeName : string option)
     ?(attributeType : string option) ?(autoReverse : string option)
     ?(azimuth : string option) ?(baseFrequency : string option)
     ?(baseProfile : string option) ?(baselineShift : string option)
     ?(bbox : string option) ?(begin_ : string option)
     ?(* as begin *) (bias : string option) ?(by : string option)
     ?(calcMode : string option) ?(capHeight : string option)
     ?(clip : string option) ?(clipPath : string option)
     ?(clipPathUnits : string option) ?(clipRule : string option)
     ?(colorInterpolation : string option)
     ?(colorInterpolationFilters : string option) ?(colorProfile : string option)
     ?(colorRendering : string option) ?(contentScriptType : string option)
     ?(contentStyleType : string option) ?(cursor : string option)
     ?(cx : string option) ?(cy : string option) ?(d : string option)
     ?(decelerate : string option) ?(descent : string option)
     ?(diffuseConstant : string option) ?(direction : string option)
     ?(display : string option) ?(divisor : string option)
     ?(dominantBaseline : string option) ?(dur : string option)
     ?(dx : string option) ?(dy : string option) ?(edgeMode : string option)
     ?(elevation : string option) ?(enableBackground : string option)
     ?(end_ : string option) ?(* as end *)
                             (exponent : string option)
     ?(externalResourcesRequired : string option) ?(fill : string option)
     ?(fillOpacity : string option) ?(fillRule : string option)
     ?(filter : string option) ?(filterRes : string option)
     ?(filterUnits : string option) ?(floodColor : string option)
     ?(floodOpacity : string option) ?(focusable : string option)
     ?(fontFamily : string option) ?(fontSize : string option)
     ?(fontSizeAdjust : string option) ?(fontStretch : string option)
     ?(fontStyle : string option) ?(fontVariant : string option)
     ?(fontWeight : string option) ?(fomat : string option)
     ?(from : string option) ?(fx : string option) ?(fy : string option)
     ?(g1 : string option) ?(g2 : string option) ?(glyphName : string option)
     ?(glyphOrientationHorizontal : string option)
     ?(glyphOrientationVertical : string option) ?(glyphRef : string option)
     ?(gradientTransform : string option) ?(gradientUnits : string option)
     ?(hanging : string option) ?(horizAdvX : string option)
     ?(horizOriginX : string option) ?(ideographic : string option)
     ?(imageRendering : string option) ?(in_ : string option)
     ?(* as in *) (in2 : string option) ?(intercept : string option)
     ?(k : string option) ?(k1 : string option) ?(k2 : string option)
     ?(k3 : string option) ?(k4 : string option) ?(kernelMatrix : string option)
     ?(kernelUnitLength : string option) ?(kerning : string option)
     ?(keyPoints : string option) ?(keySplines : string option)
     ?(keyTimes : string option) ?(lengthAdjust : string option)
     ?(letterSpacing : string option) ?(lightingColor : string option)
     ?(limitingConeAngle : string option) ?(local : string option)
     ?(markerEnd : string option) ?(markerHeight : string option)
     ?(markerMid : string option) ?(markerStart : string option)
     ?(markerUnits : string option) ?(markerWidth : string option)
     ?(mask : string option) ?(maskContentUnits : string option)
     ?(maskUnits : string option) ?(mathematical : string option)
     ?(mode : string option) ?(numOctaves : string option)
     ?(offset : string option) ?(opacity : string option)
     ?(operator : string option) ?(order : string option)
     ?(orient : string option) ?(orientation : string option)
     ?(origin : string option) ?(overflow : string option)
     ?(overflowX : string option) ?(overflowY : string option)
     ?(overlinePosition : string option) ?(overlineThickness : string option)
     ?(paintOrder : string option) ?(panose1 : string option)
     ?(pathLength : string option) ?(patternContentUnits : string option)
     ?(patternTransform : string option) ?(patternUnits : string option)
     ?(pointerEvents : string option) ?(points : string option)
     ?(pointsAtX : string option) ?(pointsAtY : string option)
     ?(pointsAtZ : string option) ?(preserveAlpha : string option)
     ?(preserveAspectRatio : string option) ?(primitiveUnits : string option)
     ?(r : string option) ?(radius : string option) ?(refX : string option)
     ?(refY : string option) ?(renderingIntent : string option)
     ?(repeatCount : string option) ?(repeatDur : string option)
     ?(requiredExtensions : string option) ?(requiredFeatures : string option)
     ?(restart : string option) ?(result : string option)
     ?(rotate : string option) ?(rx : string option) ?(ry : string option)
     ?(scale : string option) ?(seed : string option)
     ?(shapeRendering : string option) ?(slope : string option)
     ?(spacing : string option) ?(specularConstant : string option)
     ?(specularExponent : string option) ?(speed : string option)
     ?(spreadMethod : string option) ?(startOffset : string option)
     ?(stdDeviation : string option) ?(stemh : string option)
     ?(stemv : string option) ?(stitchTiles : string option)
     ?(stopColor : string option) ?(stopOpacity : string option)
     ?(strikethroughPosition : string option)
     ?(strikethroughThickness : string option) ?(stroke : string option)
     ?(strokeDasharray : string option) ?(strokeDashoffset : string option)
     ?(strokeLinecap : string option) ?(strokeLinejoin : string option)
     ?(strokeMiterlimit : string option) ?(strokeOpacity : string option)
     ?(strokeWidth : string option) ?(surfaceScale : string option)
     ?(systemLanguage : string option) ?(tableValues : string option)
     ?(targetX : string option) ?(targetY : string option)
     ?(textAnchor : string option) ?(textDecoration : string option)
     ?(textLength : string option) ?(textRendering : string option)
     ?(to_ : string option) ?(transform : string option) ?(u1 : string option)
     ?(u2 : string option) ?(underlinePosition : string option)
     ?(underlineThickness : string option) ?(unicode : string option)
     ?(unicodeBidi : string option) ?(unicodeRange : string option)
     ?(unitsPerEm : string option) ?(vAlphabetic : string option)
     ?(vHanging : string option) ?(vIdeographic : string option)
     ?(vMathematical : string option) ?(values : string option)
     ?(vectorEffect : string option) ?(version : string option)
     ?(vertAdvX : string option) ?(vertAdvY : string option)
     ?(vertOriginX : string option) ?(vertOriginY : string option)
     ?(viewBox : string option) ?(viewTarget : string option)
     ?(visibility : string option) ?(widths : string option)
     ?(wordSpacing : string option) ?(writingMode : string option)
     ?(x : string option) ?(x1 : string option) ?(x2 : string option)
     ?(xChannelSelector : string option) ?(xHeight : string option)
     ?(xlinkActuate : string option) ?(xlinkArcrole : string option)
     ?(xlinkHref : string option) ?(xlinkRole : string option)
     ?(xlinkShow : string option) ?(xlinkTitle : string option)
     ?(xlinkType : string option) ?(xmlns : string option)
     ?(xmlnsXlink : string option) ?(xmlBase : string option)
     ?(xmlLang : string option) ?(xmlSpace : string option) ?(y : string option)
     ?(y1 : string option) ?(y2 : string option)
     ?(yChannelSelector : string option) ?(z : string option)
     ?(zoomAndPan : string option) ?(about : string option)
     ?(datatype : string option) ?(inlist : string option)
     ?(prefix : string option) ?(property : string option)
     ?(resource : string option) ?(typeof : string option)
     ?(vocab : string option)
     ?(dangerouslySetInnerHTML : dangerouslySetInnerHTML option)
     ?(suppressContentEditableWarning : bool option)
     ?(ariaHaspopup : string option) ?(ariaInvalid : string option)
     ?(ariaLive : string option) ?(ariaOrientation : string option)
     ?(ariaPressed : string option) ?(ariaRowindextext : string option)
     ?(as_ : string option) () : domProps =
   {
     key;
     ref;
     ariaActivedescendant;
     ariaAtomic;
     ariaAutocomplete;
     ariaBusy;
     ariaChecked;
     ariaColcount;
     ariaColindex;
     ariaColspan;
     ariaControls;
     ariaCurrent;
     ariaDescribedby;
     ariaDetails;
     ariaDisabled;
     ariaErrormessage;
     ariaExpanded;
     ariaFlowto;
     ariaGrabbed;
     ariaHaspopup;
     ariaHidden;
     ariaInvalid;
     ariaKeyshortcuts;
     ariaLabel;
     ariaLabelledby;
     ariaLevel;
     ariaLive;
     ariaModal;
     ariaMultiline;
     ariaMultiselectable;
     ariaOrientation;
     ariaOwns;
     ariaPlaceholder;
     ariaPosinset;
     ariaPressed;
     ariaReadonly;
     ariaRelevant;
     ariaRequired;
     ariaRoledescription;
     ariaRowcount;
     ariaRowindex;
     ariaRowindextext;
     ariaRowspan;
     ariaSelected;
     ariaSetsize;
     ariaSort;
     ariaValuemax;
     ariaValuemin;
     ariaValuenow;
     ariaValuetext;
     defaultChecked;
     defaultValue;
     accessKey;
     className;
     contentEditable;
     contextMenu;
     dir;
     draggable;
     hidden;
     id;
     lang;
     role;
     style;
     spellCheck;
     tabIndex;
     title;
     itemID;
     itemProp;
     itemRef;
     itemScope;
     itemType;
     as_;
     accept;
     acceptCharset;
     action;
     allowFullScreen;
     alt;
     async;
     autoComplete;
     autoCapitalize;
     autoFocus;
     autoPlay;
     challenge;
     charSet;
     checked;
     cite;
     crossOrigin;
     cols;
     colSpan;
     content;
     controls;
     coords;
     data;
     dateTime;
     default;
     defer;
     disabled;
     download;
     encType;
     form;
     formAction;
     formTarget;
     formMethod;
     headers;
     height;
     high;
     href;
     hrefLang;
     htmlFor;
     httpEquiv;
     icon;
     inputMode;
     integrity;
     keyType;
     kind;
     label;
     list;
     loop;
     low;
     manifest;
     max;
     maxLength;
     media;
     mediaGroup;
     method_;
     min;
     minLength;
     multiple;
     muted;
     name;
     nonce;
     noValidate;
     open_;
     optimum;
     pattern;
     placeholder;
     playsInline;
     poster;
     preload;
     radioGroup;
     readOnly;
     rel;
     required;
     reversed;
     rows;
     rowSpan;
     sandbox;
     scope;
     scoped;
     scrolling;
     selected;
     shape;
     size;
     sizes;
     span;
     src;
     srcDoc;
     srcLang;
     srcSet;
     start;
     step;
     summary;
     target;
     type_;
     useMap;
     value;
     width;
     wrap;
     onCopy;
     onCut;
     onPaste;
     onCompositionEnd;
     onCompositionStart;
     onCompositionUpdate;
     onKeyDown;
     onKeyPress;
     onKeyUp;
     onFocus;
     onBlur;
     onChange;
     onInput;
     onSubmit;
     onInvalid;
     onClick;
     onContextMenu;
     onDoubleClick;
     onDrag;
     onDragEnd;
     onDragEnter;
     onDragExit;
     onDragLeave;
     onDragOver;
     onDragStart;
     onDrop;
     onMouseDown;
     onMouseEnter;
     onMouseLeave;
     onMouseMove;
     onMouseOut;
     onMouseOver;
     onMouseUp;
     onSelect;
     onTouchCancel;
     onTouchEnd;
     onTouchMove;
     onTouchStart;
     onPointerOver;
     onPointerEnter;
     onPointerDown;
     onPointerMove;
     onPointerUp;
     onPointerCancel;
     onPointerOut;
     onPointerLeave;
     onGotPointerCapture;
     onLostPointerCapture;
     onScroll;
     onWheel;
     onAbort;
     onCanPlay;
     onCanPlayThrough;
     onDurationChange;
     onEmptied;
     onEncrypetd;
     onEnded;
     onError;
     onLoadedData;
     onLoadedMetadata;
     onLoadStart;
     onPause;
     onPlay;
     onPlaying;
     onProgress;
     onRateChange;
     onSeeked;
     onSeeking;
     onStalled;
     onSuspend;
     onTimeUpdate;
     onVolumeChange;
     onWaiting;
     onLoad;
     onAnimationStart;
     onAnimationEnd;
     onAnimationIteration;
     onTransitionEnd;
     accentHeight;
     accumulate;
     additive;
     alignmentBaseline;
     allowReorder;
     alphabetic;
     amplitude;
     arabicForm;
     ascent;
     attributeName;
     attributeType;
     autoReverse;
     azimuth;
     baseFrequency;
     baseProfile;
     baselineShift;
     bbox;
     begin_;
     bias;
     by;
     calcMode;
     capHeight;
     clip;
     clipPath;
     clipPathUnits;
     clipRule;
     colorInterpolation;
     colorInterpolationFilters;
     colorProfile;
     colorRendering;
     contentScriptType;
     contentStyleType;
     cursor;
     cx;
     cy;
     d;
     decelerate;
     descent;
     diffuseConstant;
     direction;
     display;
     divisor;
     dominantBaseline;
     dur;
     dx;
     dy;
     edgeMode;
     elevation;
     enableBackground;
     end_;
     exponent;
     externalResourcesRequired;
     fill;
     fillOpacity;
     fillRule;
     filter;
     filterRes;
     filterUnits;
     floodColor;
     floodOpacity;
     focusable;
     fontFamily;
     fontSize;
     fontSizeAdjust;
     fontStretch;
     fontStyle;
     fontVariant;
     fontWeight;
     fomat;
     from;
     fx;
     fy;
     g1;
     g2;
     glyphName;
     glyphOrientationHorizontal;
     glyphOrientationVertical;
     glyphRef;
     gradientTransform;
     gradientUnits;
     hanging;
     horizAdvX;
     horizOriginX;
     ideographic;
     imageRendering;
     in_;
     in2;
     intercept;
     k;
     k1;
     k2;
     k3;
     k4;
     kernelMatrix;
     kernelUnitLength;
     kerning;
     keyPoints;
     keySplines;
     keyTimes;
     lengthAdjust;
     letterSpacing;
     lightingColor;
     limitingConeAngle;
     local;
     markerEnd;
     markerHeight;
     markerMid;
     markerStart;
     markerUnits;
     markerWidth;
     mask;
     maskContentUnits;
     maskUnits;
     mathematical;
     mode;
     numOctaves;
     offset;
     opacity;
     operator;
     order;
     orient;
     orientation;
     origin;
     overflow;
     overflowX;
     overflowY;
     overlinePosition;
     overlineThickness;
     paintOrder;
     panose1;
     pathLength;
     patternContentUnits;
     patternTransform;
     patternUnits;
     pointerEvents;
     points;
     pointsAtX;
     pointsAtY;
     pointsAtZ;
     preserveAlpha;
     preserveAspectRatio;
     primitiveUnits;
     r;
     radius;
     refX;
     refY;
     renderingIntent;
     repeatCount;
     repeatDur;
     requiredExtensions;
     requiredFeatures;
     restart;
     result;
     rotate;
     rx;
     ry;
     scale;
     seed;
     shapeRendering;
     slope;
     spacing;
     specularConstant;
     specularExponent;
     speed;
     spreadMethod;
     startOffset;
     stdDeviation;
     stemh;
     stemv;
     stitchTiles;
     stopColor;
     stopOpacity;
     strikethroughPosition;
     strikethroughThickness;
     stroke;
     strokeDasharray;
     strokeDashoffset;
     strokeLinecap;
     strokeLinejoin;
     strokeMiterlimit;
     strokeOpacity;
     strokeWidth;
     surfaceScale;
     systemLanguage;
     tableValues;
     targetX;
     targetY;
     textAnchor;
     textDecoration;
     textLength;
     textRendering;
     to_;
     transform;
     u1;
     u2;
     underlinePosition;
     underlineThickness;
     unicode;
     unicodeBidi;
     unicodeRange;
     unitsPerEm;
     vAlphabetic;
     vHanging;
     vIdeographic;
     vMathematical;
     values;
     vectorEffect;
     version;
     vertAdvX;
     vertAdvY;
     vertOriginX;
     vertOriginY;
     viewBox;
     viewTarget;
     visibility;
     widths;
     wordSpacing;
     writingMode;
     x;
     x1;
     x2;
     xChannelSelector;
     xHeight;
     xlinkActuate;
     xlinkArcrole;
     xlinkHref;
     xlinkRole;
     xlinkShow;
     xlinkTitle;
     xlinkType;
     xmlns;
     xmlnsXlink;
     xmlBase;
     xmlLang;
     xmlSpace;
     y;
     y1;
     y2;
     yChannelSelector;
     z;
     zoomAndPan;
     about;
     datatype;
     inlist;
     prefix;
     property;
     resource;
     typeof;
     vocab;
     dangerouslySetInnerHTML;
     suppressContentEditableWarning;
   }
*)
