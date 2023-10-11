open React

let get_key = function
  | JSX.Bool (k, _) -> k
  | String (k, _) -> k
  | Ref _ -> "ref"
  | DangerouslyInnerHtml _ -> "dangerouslySetInnerHTML"
  | Style _ -> "style"
  (* Events don't matter on SSR, but the key should be corrected to lowercase, since in domProps, Event only contains jsxName *)
  | Event (name, _) -> String.lowercase_ascii name

let is_react_custom_attribute attr =
  match get_key attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning"
  | "suppressHydrationWarning" ->
      true
  | _ -> false

let attribute_is_event attr = match attr with JSX.Event _ -> true | _ -> false

let attribute_to_string attr =
  match attr with
  (* ignores "ref" prop *)
  | JSX.Ref _ -> ""
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
  | String (k, v) -> Printf.sprintf "%s=\"%s\"" k (Html.encode v)

(* We render _onclick events as string, to support an onClick but as string
   defined as `_onclick="$(this)"` on JSX *)
let is_onclick_event_hack attr =
  match attr with
  | JSX.Event (name, _) when String.equal name "_onclick" -> true
  | _ -> false

let valid_attribute_to_string attr =
  if is_react_custom_attribute attr then None
  else if is_onclick_event_hack attr then Some (attribute_to_string attr)
  else if attribute_is_event attr then None
  else Some (attribute_to_string attr)

let attributes_to_string attrs =
  let valid_attributes =
    attrs |> Array.to_list |> List.filter_map valid_attribute_to_string
  in
  match valid_attributes with
  | [] -> ""
  | rest -> " " ^ (rest |> String.concat " " |> String.trim)

let react_root_attr_name = "data-reactroot"
let data_react_root_attr = Printf.sprintf " %s=\"\"" react_root_attr_name

type mode = String | Markup

let render_to_string ~mode element =
  (* is_root starts at true (when renderToString) and only goes to false
     when renders an lower-case element or closed element *)
  let is_mode_to_string = mode = String in
  let is_root = ref is_mode_to_string in
  (* previous_was_text_node is the flag to enable rendering comments
     <!-- --> between text nodes *)
  let previous_was_text_node = ref false in
  let rec render_element element =
    let root_attribute =
      match is_root.contents with true -> data_react_root_attr | false -> ""
    in
    match element with
    | Empty -> ""
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List list ->
        list |> Array.map render_element |> Array.to_list |> String.concat ""
    | Upper_case_component f -> render_element (f ())
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        is_root.contents <- false;
        Printf.sprintf "<%s%s%s />" tag root_attribute
          (attributes_to_string attributes)
    | Lower_case_element { tag; attributes; children } ->
        is_root.contents <- false;
        Printf.sprintf "<%s%s%s>%s</%s>" tag root_attribute
          (attributes_to_string attributes)
          (children |> List.map render_element |> String.concat "")
          tag
    | Text text -> (
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        match mode with
        | String when is_previous_text_node ->
            Printf.sprintf "<!-- -->%s" (Html.encode text)
        | _ -> Html.encode text)
    | InnerHtml text -> text
    | Suspense { children; fallback } -> (
        match render_element children with
        | output -> Printf.sprintf "<!--$-->%s<!--/$-->" output
        | exception _e ->
            Printf.sprintf "<!--$!-->%s<!--/$-->" (render_element fallback))
  in
  render_element element

let renderToString element =
  (* TODO: try catch to avoid React.use usages *)
  render_to_string ~mode:String element

let renderToStaticMarkup element =
  (* TODO: try catch to avoid React.use usages *)
  render_to_string ~mode:Markup element

module Stream = struct
  let create () =
    let stream, push_to_stream = Lwt_stream.create () in
    let push v = push_to_stream @@ Some v in
    let close () = push_to_stream @@ None in
    (stream, push, close)
end

type context_state = {
  stream : string Lwt_stream.t;
  push : string -> unit;
  close : unit -> unit;
  mutable boundary_id : int;
  mutable suspense_id : int;
  mutable waiting : int;
}
[@@warning "-69"]
(* stream isn't being used *)

(* https://github.com/facebook/react/blob/493f72b0a7111b601c16b8ad8bc2649d82c184a0/packages/react-dom-bindings/src/server/fizz-instruction-set/ReactDOMFizzInstructionSetShared.js#L46 *)
let complete_boundary_script =
  {|function $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if("/$"===d)if(0===e)break;else e--;else"$"!==d&&"$?"!==d&&"$!"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data="$";a._reactRetry&&a._reactRetry()}}|}

let inline_complete_boundary_script =
  Printf.sprintf {|<script>%s</script>|} complete_boundary_script

let render_inline_rc_replacement replacements =
  let rc_payload =
    replacements
    |> List.map (fun (b, s) -> Printf.sprintf "$RC('B:%i','S:%i')" b s)
    |> String.concat ";"
  in
  Printf.sprintf {|<script>%s</script>|} rc_payload

let render_to_stream ~context_state element =
  let rec render_element element =
    match element with
    | Empty -> ""
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List arr ->
        arr |> Array.to_list |> List.map render_element |> String.concat ""
    | Upper_case_component component -> render_element (component ())
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        Printf.sprintf "<%s%s />" tag (attributes_to_string attributes)
    | Lower_case_element { tag; attributes; children } ->
        Printf.sprintf "<%s%s>%s</%s>" tag
          (attributes_to_string attributes)
          (children |> List.map render_element |> String.concat "")
          tag
    | Text text -> Html.encode text
    | InnerHtml text -> text
    | Suspense { children; fallback } -> (
        match render_element children with
        | output -> output
        | exception React.Suspend (Any_promise promise) ->
            context_state.waiting <- context_state.waiting + 1;
            (* We store to current_*_id to bypass the increment *)
            let current_boundary_id = context_state.boundary_id in
            let current_suspense_id = context_state.suspense_id in
            context_state.boundary_id <- context_state.boundary_id + 1;
            (* Wait for promise to resolve *)
            Lwt.async (fun () ->
                Lwt.map
                  (fun _ ->
                    (* Enqueue the component with resolved data *)
                    context_state.push
                      (render_resolved_element ~id:current_suspense_id children);
                    (* Enqueue the inline script that replaces fallback by resolved *)
                    context_state.push inline_complete_boundary_script;
                    context_state.push
                      (render_inline_rc_replacement
                         [ (current_boundary_id, current_suspense_id) ]);
                    context_state.waiting <- context_state.waiting - 1;
                    context_state.suspense_id <- context_state.suspense_id + 1;
                    if context_state.waiting = 0 then context_state.close ())
                  promise);
            (* Return the rendered fallback to SSR syncronous *)
            render_fallback ~boundary_id:current_boundary_id fallback
        | exception _exn ->
            (* TODO: log exn *)
            render_fallback ~boundary_id:context_state.boundary_id fallback)
  and render_resolved_element ~id element =
    Printf.sprintf "<div hidden id='S:%i'>%s</div>" id (render_element element)
  and render_fallback ~boundary_id element =
    Printf.sprintf "<!--$?--><template id='B:%i'></template>%s<!--/$-->"
      boundary_id (render_element element)
  in
  render_element element

let renderToLwtStream element =
  let stream, push, close = Stream.create () in
  let context_state =
    { stream; push; close; waiting = 0; boundary_id = 0; suspense_id = 0 }
  in
  let shell = render_to_stream ~context_state element in
  push shell;
  if context_state.waiting = 0 then close ();
  (* TODO: Needs to flush the remaining loading fallbacks as HTML, and will attempt to render the rest on the client. *)
  let abort () = (* Lwt_stream.closed stream |> Lwt.ignore_result *) () in
  (stream, abort)

let querySelector _str = None

let render _element _node =
  Runtime.fail_impossible_action_in_ssr "ReactDOM.render"

let hydrate _element _node =
  Runtime.fail_impossible_action_in_ssr "ReactDOM.hydrate"

let createPortal _reactElement _domElement = _reactElement

module Style = ReactDOMStyle

let createDOMElementVariadic (tag : string) ~(props : JSX.prop array)
    (childrens : React.element array) =
  React.createElement tag props (childrens |> Array.to_list)

let add kind value (map : JSX.prop list) =
  match value with Some i -> map |> List.cons (kind i) | None -> map

type dangerouslySetInnerHTML = { __html : string } [@@boxed]

[@@@ocamlformat "disable"]
(* domProps isn't used by the generated code from the ppx, and it's purpose is to
   allow usages from user's code via createElementVariadic and custom usages outside JSX *)
let domProps
  ?key
  ?ref
  ?ariaDetails
  ?ariaDisabled
  ?ariaHidden
  ?ariaKeyshortcuts
  ?ariaLabel
  ?ariaRoledescription
  ?ariaExpanded
  ?ariaLevel
  ?ariaModal
  ?ariaMultiline
  ?ariaMultiselectable
  ?ariaPlaceholder
  ?ariaReadonly
  ?ariaRequired
  ?ariaSelected
  ?ariaSort
  ?ariaValuemax
  ?ariaValuemin
  ?ariaValuenow
  ?ariaValuetext
  ?ariaAtomic
  ?ariaBusy
  ?ariaRelevant
  ?ariaGrabbed
  ?ariaActivedescendant
  ?ariaColcount
  ?ariaColindex
  ?ariaColspan
  ?ariaControls
  ?ariaDescribedby
  ?ariaErrormessage
  ?ariaFlowto
  ?ariaLabelledby
  ?ariaOwns
  ?ariaPosinset
  ?ariaRowcount
  ?ariaRowindex
  ?ariaRowspan
  ?ariaSetsize
  ?defaultChecked
  ?defaultValue
  ?accessKey
  ?className
  ?contentEditable
  ?contextMenu
  ?dir
  ?draggable
  ?hidden
  ?id
  ?lang
  ?role
  ?style
  ?spellCheck
  ?tabIndex
  ?title
  ?itemID
  ?itemProp
  ?itemRef
  ?itemScope
  ?itemType
  ?accept
  ?acceptCharset
  ?action
  ?allowFullScreen
  ?alt
  ?async
  ?autoComplete
  ?autoCapitalize
  ?autoFocus
  ?autoPlay
  ?challenge
  ?charSet
  ?checked
  ?cite
  ?crossOrigin
  ?cols
  ?colSpan
  ?content
  ?controls
  ?coords
  ?data
  ?dateTime
  ?default
  ?defer
  ?disabled
  ?download
  ?encType
  ?form
  ?formAction
  ?formTarget
  ?formMethod
  ?headers
  ?height
  ?high
  ?href
  ?hrefLang
  ?htmlFor
  ?httpEquiv
  ?icon
  ?inputMode
  ?integrity
  ?keyType
  ?kind
  ?label
  ?list
  ?loop
  ?low
  ?manifest
  ?max
  ?maxLength
  ?media
  ?mediaGroup
  ?method_
  ?min
  ?minLength
  ?multiple
  ?muted
  ?name
  ?nonce
  ?noValidate
  ?open_
  ?optimum
  ?pattern
  ?placeholder
  ?playsInline
  ?poster
  ?preload
  ?radioGroup
  ?readOnly
  ?rel
  ?required
  ?reversed
  ?rows
  ?rowSpan
  ?sandbox
  ?scope
  ?scoped
  ?scrolling
  ?selected
  ?shape
  ?size
  ?sizes
  ?span
  ?src
  ?srcDoc
  ?srcLang
  ?srcSet
  ?start
  ?step
  ?summary
  ?target
  ?type_
  ?useMap
  ?value
  ?width
  ?wrap
  ?onCopy
  ?onCut
  ?onPaste
  ?onCompositionEnd
  ?onCompositionStart
  ?onCompositionUpdate
  ?onKeyDown
  ?onKeyPress
  ?onKeyUp
  ?onFocus
  ?onBlur
  ?onChange
  ?onInput
  ?onSubmit
  ?onInvalid
  ?onClick
  ?onContextMenu
  ?onDoubleClick
  ?onDrag
  ?onDragEnd
  ?onDragEnter
  ?onDragExit
  ?onDragLeave
  ?onDragOver
  ?onDragStart
  ?onDrop
  ?onMouseDown
  ?onMouseEnter
  ?onMouseLeave
  ?onMouseMove
  ?onMouseOut
  ?onMouseOver
  ?onMouseUp
  ?onSelect
  ?onTouchCancel
  ?onTouchEnd
  ?onTouchMove
  ?onTouchStart
  ?onPointerOver
  ?onPointerEnter
  ?onPointerDown
  ?onPointerMove
  ?onPointerUp
  ?onPointerCancel
  ?onPointerOut
  ?onPointerLeave
  ?onGotPointerCapture
  ?onLostPointerCapture
  ?onScroll
  ?onWheel
  ?onAbort
  ?onCanPlay
  ?onCanPlayThrough
  ?onDurationChange
  ?onEmptied
  ?onEncrypetd
  ?onEnded
  ?onError
  ?onLoadedData
  ?onLoadedMetadata

  ?onLoadStart
  ?onPause
  ?onPlay
  ?onPlaying
  ?onProgress
  ?onRateChange
  ?onSeeked

  ?onSeeking
  ?onStalled
  ?onSuspend
  ?onTimeUpdate
  ?onVolumeChange
  ?onWaiting

  ?onAnimationStart
  ?onAnimationEnd
  ?onAnimationIteration
  ?onTransitionEnd

  ?accentHeight
  ?accumulate
  ?additive
  ?alignmentBaseline
  ?allowReorder

  ?alphabetic
  ?amplitude
  ?arabicForm
  ?ascent
  ?attributeName
  ?attributeType
  ?autoReverse
  ?azimuth
  ?baseFrequency
  ?baseProfile
  ?baselineShift
  ?bbox
  ?begin_
  ?bias
  ?by
  ?calcMode
  ?capHeight
  ?clip
  ?clipPath
  ?clipPathUnits
  ?clipRule
  ?colorInterpolation
  ?colorInterpolationFilters
  ?colorProfile
  ?colorRendering
  ?contentScriptType
  ?contentStyleType
  ?cursor
  ?cx
  ?cy
  ?d
  ?decelerate
  ?descent
  ?diffuseConstant
  ?direction
  ?display
  ?divisor
  ?dominantBaseline
  ?dur
  ?dx
  ?dy
  ?edgeMode
  ?elevation
  ?enableBackground
  ?end_
  ?exponent
  ?externalResourcesRequired
  ?fill
  ?fillOpacity
  ?fillRule
  ?filter
  ?filterRes
  ?filterUnits
  ?floodColor
  ?floodOpacity
  ?focusable
  ?fontFamily
  ?fontSize
  ?fontSizeAdjust
  ?fontStretch
  ?fontStyle
  ?fontVariant
  ?fontWeight
  ?fomat
  ?from
  ?fx
  ?fy
  ?g1
  ?g2
  ?glyphName
  ?glyphOrientationHorizontal
  ?glyphOrientationVertical
  ?glyphRef
  ?gradientTransform
  ?gradientUnits
  ?hanging
  ?horizAdvX
  ?horizOriginX
  ?ideographic
  ?imageRendering
  ?in_
  ?in2
  ?intercept
  ?k
  ?k1
  ?k2
  ?k3
  ?k4
  ?kernelMatrix
  ?kernelUnitLength
  ?kerning
  ?keyPoints
  ?keySplines
  ?keyTimes
  ?lengthAdjust
  ?letterSpacing
  ?lightingColor
  ?limitingConeAngle
  ?local
  ?markerEnd
  ?markerHeight
  ?markerMid
  ?markerStart
  ?markerUnits
  ?markerWidth
  ?mask
  ?maskContentUnits
  ?maskUnits
  ?mathematical
  ?mode
  ?numOctaves
  ?offset
  ?opacity
  ?operator
  ?order
  ?orient
  ?orientation
  ?origin
  ?overflow
  ?overflowX
  ?overflowY
  ?overlinePosition
  ?overlineThickness
  ?paintOrder
  ?panose1
  ?pathLength
  ?patternContentUnits
  ?patternTransform
  ?patternUnits
  ?pointerEvents
  ?points
  ?pointsAtX
  ?pointsAtY
  ?pointsAtZ
  ?preserveAlpha
  ?preserveAspectRatio
  ?primitiveUnits
  ?r
  ?radius
  ?refX
  ?refY
  ?renderingIntent
  ?repeatCount
  ?repeatDur
  ?requiredExtensions
  ?requiredFeatures
  ?restart
  ?result
  ?rotate
  ?rx
  ?ry
  ?scale
  ?seed
  ?shapeRendering
  ?slope
  ?spacing
  ?specularConstant
  ?specularExponent
  ?speed
  ?spreadMethod
  ?startOffset
  ?stdDeviation
  ?stemh
  ?stemv
  ?stitchTiles
  ?stopColor
  ?stopOpacity
  ?strikethroughPosition
  ?strikethroughThickness
  ?stroke
  ?strokeDasharray
  ?strokeDashoffset
  ?strokeLinecap
  ?strokeLinejoin
  ?strokeMiterlimit
  ?strokeOpacity
  ?strokeWidth
  ?surfaceScale
  ?systemLanguage
  ?tableValues
  ?targetX
  ?targetY
  ?textAnchor
  ?textDecoration
  ?textLength
  ?textRendering
  ?to_
  ?transform
  ?u1
  ?u2
  ?underlinePosition
  ?underlineThickness
  ?unicode
  ?unicodeBidi
  ?unicodeRange
  ?unitsPerEm
  ?vAlphabetic
  ?vHanging
  ?vIdeographic
  ?vMathematical
  ?values
  ?vectorEffect
  ?version
  ?vertAdvX
  ?vertAdvY
  ?vertOriginX
  ?vertOriginY
  ?viewBox
  ?viewTarget
  ?visibility
  ?widths
  ?wordSpacing
  ?writingMode
  ?x
  ?x1
  ?x2
  ?xChannelSelector
  ?xHeight
  ?xlinkActuate
  ?xlinkArcrole
  ?xlinkHref
  ?xlinkRole
  ?xlinkShow
  ?xlinkTitle
  ?xlinkType
  ?xmlns
  ?xmlnsXlink
  ?xmlBase
  ?xmlLang
  ?xmlSpace
  ?y
  ?y1
  ?y2
  ?yChannelSelector
  ?z
  ?zoomAndPan
  ?about
  ?datatype
  ?inlist
  ?prefix
  ?property
  ?resource
  ?typeof
  ?vocab
  ?dangerouslySetInnerHTML
  ?suppressContentEditableWarning
  ?suppressHydrationWarning
  () =
  []
  |> add (JSX.string "key") key
  |> add JSX.ref ref
  |> add (JSX.string "aria-details") ariaDetails
  |> add (JSX.bool "aria-disabled") ariaDisabled
  |> add (JSX.bool "aria-hidden") ariaHidden
  |> add (JSX.string "aria-keyshortcuts") ariaKeyshortcuts
  |> add (JSX.string "aria-label") ariaLabel
  |> add (JSX.string "aria-roledescription") ariaRoledescription
  |> add (JSX.bool "aria-expanded") ariaExpanded
  |> add (JSX.int "aria-level") ariaLevel
  |> add (JSX.bool "aria-modal") ariaModal
  |> add (JSX.bool "aria-multiline") ariaMultiline
  |> add (JSX.bool "aria-multiselectable") ariaMultiselectable
  |> add (JSX.string "aria-placeholder") ariaPlaceholder
  |> add (JSX.bool "aria-readonly") ariaReadonly
  |> add (JSX.bool "aria-required") ariaRequired
  |> add (JSX.bool "aria-selected") ariaSelected
  |> add (JSX.string "aria-sort") ariaSort
  |> add (JSX.float "aria-valuemax") ariaValuemax
  |> add (JSX.float "aria-valuemin") ariaValuemin
  |> add (JSX.float "aria-valuenow") ariaValuenow
  |> add (JSX.string "aria-valuetext") ariaValuetext
  |> add (JSX.bool "aria-atomic") ariaAtomic
  |> add (JSX.bool "aria-busy") ariaBusy
  |> add (JSX.string "aria-relevant") ariaRelevant
  |> add (JSX.bool "aria-grabbed") ariaGrabbed
  |> add (JSX.string "aria-activedescendant") ariaActivedescendant
  |> add (JSX.int "aria-colcount") ariaColcount
  |> add (JSX.int "aria-colindex") ariaColindex
  |> add (JSX.int "aria-colspan") ariaColspan
  |> add (JSX.string "aria-controls") ariaControls
  |> add (JSX.string "aria-describedby") ariaDescribedby
  |> add (JSX.string "aria-errormessage") ariaErrormessage
  |> add (JSX.string "aria-flowto") ariaFlowto
  |> add (JSX.string "aria-labelledby") ariaLabelledby
  |> add (JSX.string "aria-owns") ariaOwns
  |> add (JSX.int "aria-posinset") ariaPosinset
  |> add (JSX.int "aria-rowcount") ariaRowcount
  |> add (JSX.int "aria-rowindex") ariaRowindex
  |> add (JSX.int "aria-rowspan") ariaRowspan
  |> add (JSX.int "aria-setsize") ariaSetsize
  |> add (JSX.bool "checked") defaultChecked
  |> add (JSX.string "value") defaultValue
  |> add (JSX.string "accessKey") accessKey
  |> add (JSX.string "class") className
  |> add (JSX.bool "contentEditable") contentEditable
  |> add (JSX.string "contextMenu") contextMenu
  |> add (JSX.string "dir") dir
  |> add (JSX.bool "draggable") draggable
  |> add (JSX.bool "hidden") hidden
  |> add (JSX.string "id") id
  |> add (JSX.string "lang") lang
  |> add (JSX.string "role") role
  |> add (fun v -> JSX.style (ReactDOMStyle.to_string v)) style
  |> add (JSX.bool "spellCheck") spellCheck
  |> add (JSX.int "tabIndex") tabIndex
  |> add (JSX.string "title") title
  |> add (JSX.string "itemID") itemID
  |> add (JSX.string "itemProp") itemProp
  |> add (JSX.string "itemRef") itemRef
  |> add (JSX.bool "itemScope") itemScope
  |> add (JSX.string "itemType") itemType
  |> add (JSX.string "accept") accept
  |> add (JSX.string "acceptCharset") acceptCharset
  |> add (JSX.string "action") action
  |> add (JSX.bool "allowFullScreen") allowFullScreen
  |> add (JSX.string "alt") alt
  |> add (JSX.bool "async") async
  |> add (JSX.string "autoComplete") autoComplete
  |> add (JSX.string "autoCapitalize") autoCapitalize
  |> add (JSX.bool "autoFocus") autoFocus
  |> add (JSX.bool "autoPlay") autoPlay
  |> add (JSX.string "challenge") challenge
  |> add (JSX.string "charSet") charSet
  |> add (JSX.bool "checked") checked
  |> add (JSX.string "cite") cite
  |> add (JSX.string "crossOrigin") crossOrigin
  |> add (JSX.int "cols") cols
  |> add (JSX.int "colSpan") colSpan
  |> add (JSX.string "content") content
  |> add (JSX.bool "controls") controls
  |> add (JSX.string "coords") coords
  |> add (JSX.string "data") data
  |> add (JSX.string "dateTime") dateTime
  |> add (JSX.bool "default") default
  |> add (JSX.bool "defer") defer
  |> add (JSX.bool "disabled") disabled
  |> add (JSX.string "download") download
  |> add (JSX.string "encType") encType
  |> add (JSX.string "form") form
  |> add (JSX.string "formAction") formAction
  |> add (JSX.string "formTarget") formTarget
  |> add (JSX.string "formMethod") formMethod
  |> add (JSX.string "headers") headers
  |> add (JSX.string "height") height
  |> add (JSX.int "high") high
  |> add (JSX.string "href") href
  |> add (JSX.string "hrefLang") hrefLang
  |> add (JSX.string "htmlFor") htmlFor
  |> add (JSX.string "httpEquiv") httpEquiv
  |> add (JSX.string "icon") icon
  |> add (JSX.string "inputMode") inputMode
  |> add (JSX.string "integrity") integrity
  |> add (JSX.string "keyType") keyType
  |> add (JSX.string "kind") kind
  |> add (JSX.string "label") label
  |> add (JSX.string "list") list
  |> add (JSX.bool "loop") loop
  |> add (JSX.int "low") low
  |> add (JSX.string "manifest") manifest
  |> add (JSX.string "max") max
  |> add (JSX.int "maxLength") maxLength
  |> add (JSX.string "media") media
  |> add (JSX.string "mediaGroup") mediaGroup
  |> add (JSX.string "method") method_
  |> add (JSX.string "min") min
  |> add (JSX.int "minLength") minLength
  |> add (JSX.bool "multiple") multiple
  |> add (JSX.bool "muted") muted
  |> add (JSX.string "name") name
  |> add (JSX.string "nonce") nonce
  |> add (JSX.bool "noValidate") noValidate
  |> add (JSX.bool "open") open_
  |> add (JSX.int "optimum") optimum
  |> add (JSX.string "pattern") pattern
  |> add (JSX.string "placeholder") placeholder
  |> add (JSX.bool "playsInline") playsInline
  |> add (JSX.string "poster") poster
  |> add (JSX.string "preload") preload
  |> add (JSX.string "radioGroup") radioGroup
  |> add (JSX.bool "readOnly") readOnly
  |> add (JSX.string "rel") rel
  |> add (JSX.bool "required") required
  |> add (JSX.bool "reversed") reversed
  |> add (JSX.int "rows") rows
  |> add (JSX.int "rowSpan") rowSpan
  |> add (JSX.string "sandbox") sandbox
  |> add (JSX.string "scope") scope
  |> add (JSX.bool "scoped") scoped
  |> add (JSX.string "scrolling") scrolling
  |> add (JSX.bool "selected") selected
  |> add (JSX.string "shape") shape
  |> add (JSX.int "size") size
  |> add (JSX.string "sizes") sizes
  |> add (JSX.int "span") span
  |> add (JSX.string "src") src
  |> add (JSX.string "srcDoc") srcDoc
  |> add (JSX.string "srcLang") srcLang
  |> add (JSX.string "srcSet") srcSet
  |> add (JSX.int "start") start
  |> add (JSX.float "step") step
  |> add (JSX.string "summary") summary
  |> add (JSX.string "target") target
  |> add (JSX.string "type") type_
  |> add (JSX.string "useMap") useMap
  |> add (JSX.string "value") value
  |> add (JSX.string "width") width
  |> add (JSX.string "wrap") wrap
  |> add (JSX.Event.clipboard "onCopy") onCopy
  |> add (JSX.Event.clipboard "onCut") onCut
  |> add (JSX.Event.clipboard "onPaste") onPaste
  |> add (JSX.Event.composition "onCompositionEnd") onCompositionEnd
  |> add (JSX.Event.composition "onCompositionStart") onCompositionStart
  |> add (JSX.Event.composition "onCompositionUpdate") onCompositionUpdate
  |> add (JSX.Event.keyboard "onKeyDown") onKeyDown
  |> add (JSX.Event.keyboard "onKeyPress") onKeyPress
  |> add (JSX.Event.keyboard "onKeyUp") onKeyUp
  |> add (JSX.Event.focus "onFocus") onFocus
  |> add (JSX.Event.focus "onBlur") onBlur
  |> add (JSX.Event.form "onChange") onChange
  |> add (JSX.Event.form "onInput") onInput
  |> add (JSX.Event.form "onSubmit") onSubmit
  |> add (JSX.Event.form "onInvalid") onInvalid
  |> add (JSX.Event.mouse "onClick") onClick
  |> add (JSX.Event.mouse "onContextMenu") onContextMenu
  |> add (JSX.Event.mouse "onDoubleClick") onDoubleClick
  |> add (JSX.Event.mouse "onDrag") onDrag
  |> add (JSX.Event.mouse "onDragEnd") onDragEnd
  |> add (JSX.Event.mouse "onDragEnter") onDragEnter
  |> add (JSX.Event.mouse "onDragExit") onDragExit
  |> add (JSX.Event.mouse "onDragLeave") onDragLeave
  |> add (JSX.Event.mouse "onDragOver") onDragOver
  |> add (JSX.Event.mouse "onDragStart") onDragStart
  |> add (JSX.Event.mouse "onDrop") onDrop
  |> add (JSX.Event.mouse "onMouseDown") onMouseDown
  |> add (JSX.Event.mouse "onMouseEnter") onMouseEnter
  |> add (JSX.Event.mouse "onMouseLeave") onMouseLeave
  |> add (JSX.Event.mouse "onMouseMove") onMouseMove
  |> add (JSX.Event.mouse "onMouseOut") onMouseOut
  |> add (JSX.Event.mouse "onMouseOver") onMouseOver
  |> add (JSX.Event.mouse "onMouseUp") onMouseUp
  |> add (JSX.Event.selection "onSelect") onSelect
  |> add (JSX.Event.touch "onTouchCancel") onTouchCancel
  |> add (JSX.Event.touch "onTouchEnd") onTouchEnd
  |> add (JSX.Event.touch "onTouchMove") onTouchMove
  |> add (JSX.Event.touch "onTouchStart") onTouchStart
  |> add (JSX.Event.pointer "onPointerOver") onPointerOver
  |> add (JSX.Event.pointer "onPointerEnter") onPointerEnter
  |> add (JSX.Event.pointer "onPointerDown") onPointerDown
  |> add (JSX.Event.pointer "onPointerMove") onPointerMove
  |> add (JSX.Event.pointer "onPointerUp") onPointerUp
  |> add (JSX.Event.pointer "onPointerCancel") onPointerCancel
  |> add (JSX.Event.pointer "onPointerOut") onPointerOut
  |> add (JSX.Event.pointer "onPointerLeave") onPointerLeave
  |> add (JSX.Event.pointer "onGotPointerCapture") onGotPointerCapture
  |> add (JSX.Event.pointer "onLostPointerCapture") onLostPointerCapture
  |> add (JSX.Event.ui "onScroll") onScroll
  |> add (JSX.Event.wheel "onWheel") onWheel
  |> add (JSX.Event.media "onAbort") onAbort
  |> add (JSX.Event.media "onCanPlay") onCanPlay
  |> add (JSX.Event.media "onCanPlayThrough") onCanPlayThrough
  |> add (JSX.Event.media "onDurationChange") onDurationChange
  |> add (JSX.Event.media "onEmptied") onEmptied
  |> add (JSX.Event.media "onEncrypetd") onEncrypetd
  |> add (JSX.Event.media "onEnded") onEnded
  |> add (JSX.Event.media "onError") onError
  |> add (JSX.Event.media "onLoadedData") onLoadedData
  |> add (JSX.Event.media "onLoadedMetadata") onLoadedMetadata
  |> add (JSX.Event.media "onLoadStart") onLoadStart
  |> add (JSX.Event.media "onPause") onPause
  |> add (JSX.Event.media "onPlay") onPlay
  |> add (JSX.Event.media "onPlaying") onPlaying
  |> add (JSX.Event.media "onProgress") onProgress
  |> add (JSX.Event.media "onRateChange") onRateChange
  |> add (JSX.Event.media "onSeeked") onSeeked
  |> add (JSX.Event.media "onSeeking") onSeeking
  |> add (JSX.Event.media "onStalled") onStalled
  |> add (JSX.Event.media "onSuspend") onSuspend
  |> add (JSX.Event.media "onTimeUpdate") onTimeUpdate
  |> add (JSX.Event.media "onVolumeChange") onVolumeChange
  |> add (JSX.Event.media "onWaiting") onWaiting
  |> add (JSX.Event.animation "onAnimationStart") onAnimationStart
  |> add (JSX.Event.animation "onAnimationEnd") onAnimationEnd
  |> add (JSX.Event.animation "onAnimationIteration") onAnimationIteration
  |> add (JSX.Event.transition "onTransitionEnd") onTransitionEnd
  |> add (JSX.string "accentHeight") accentHeight
  |> add (JSX.string "accumulate") accumulate
  |> add (JSX.string "additive") additive
  |> add (JSX.string "alignmentBaseline") alignmentBaseline
  |> add (JSX.string "allowReorder") allowReorder
  |> add (JSX.string "alphabetic") alphabetic
  |> add (JSX.string "amplitude") amplitude
  |> add (JSX.string "arabicForm") arabicForm
  |> add (JSX.string "ascent") ascent
  |> add (JSX.string "attributeName") attributeName
  |> add (JSX.string "attributeType") attributeType
  |> add (JSX.string "autoReverse") autoReverse
  |> add (JSX.string "azimuth") azimuth
  |> add (JSX.string "baseFrequency") baseFrequency
  |> add (JSX.string "baseProfile") baseProfile
  |> add (JSX.string "baselineShift") baselineShift
  |> add (JSX.string "bbox") bbox
  |> add (JSX.string "begin") begin_
  |> add (JSX.string "bias") bias
  |> add (JSX.string "by") by
  |> add (JSX.string "calcMode") calcMode
  |> add (JSX.string "capHeight") capHeight
  |> add (JSX.string "clip") clip
  |> add (JSX.string "clipPath") clipPath
  |> add (JSX.string "clipPathUnits") clipPathUnits
  |> add (JSX.string "clipRule") clipRule
  |> add (JSX.string "colorInterpolation") colorInterpolation
  |> add (JSX.string "colorInterpolationFilters") colorInterpolationFilters
  |> add (JSX.string "colorProfile") colorProfile
  |> add (JSX.string "colorRendering") colorRendering
  |> add (JSX.string "contentScriptType") contentScriptType
  |> add (JSX.string "contentStyleType") contentStyleType
  |> add (JSX.string "cursor") cursor
  |> add (JSX.string "cx") cx
  |> add (JSX.string "cy") cy
  |> add (JSX.string "d") d
  |> add (JSX.string "decelerate") decelerate
  |> add (JSX.string "descent") descent
  |> add (JSX.string "diffuseConstant") diffuseConstant
  |> add (JSX.string "direction") direction
  |> add (JSX.string "display") display
  |> add (JSX.string "divisor") divisor
  |> add (JSX.string "dominantBaseline") dominantBaseline
  |> add (JSX.string "dur") dur
  |> add (JSX.string "dx") dx
  |> add (JSX.string "dy") dy
  |> add (JSX.string "edgeMode") edgeMode
  |> add (JSX.string "elevation") elevation
  |> add (JSX.string "enableBackground") enableBackground
  |> add (JSX.string "end") end_
  |> add (JSX.string "exponent") exponent
  |> add (JSX.string "externalResourcesRequired") externalResourcesRequired
  |> add (JSX.string "fill") fill
  |> add (JSX.string "fillOpacity") fillOpacity
  |> add (JSX.string "fillRule") fillRule
  |> add (JSX.string "filter") filter
  |> add (JSX.string "filterRes") filterRes
  |> add (JSX.string "filterUnits") filterUnits
  |> add (JSX.string "floodColor") floodColor
  |> add (JSX.string "floodOpacity") floodOpacity
  |> add (JSX.string "focusable") focusable
  |> add (JSX.string "fontFamily") fontFamily
  |> add (JSX.string "fontSize") fontSize
  |> add (JSX.string "fontSizeAdjust") fontSizeAdjust
  |> add (JSX.string "fontStretch") fontStretch
  |> add (JSX.string "fontStyle") fontStyle
  |> add (JSX.string "fontVariant") fontVariant
  |> add (JSX.string "fontWeight") fontWeight
  |> add (JSX.string "fomat") fomat
  |> add (JSX.string "from") from
  |> add (JSX.string "fx") fx
  |> add (JSX.string "fy") fy
  |> add (JSX.string "g1") g1
  |> add (JSX.string "g2") g2
  |> add (JSX.string "glyphName") glyphName
  |> add (JSX.string "glyphOrientationHorizontal") glyphOrientationHorizontal
  |> add (JSX.string "glyphOrientationVertical") glyphOrientationVertical
  |> add (JSX.string "glyphRef") glyphRef
  |> add (JSX.string "gradientTransform") gradientTransform
  |> add (JSX.string "gradientUnits") gradientUnits
  |> add (JSX.string "hanging") hanging
  |> add (JSX.string "horizAdvX") horizAdvX
  |> add (JSX.string "horizOriginX") horizOriginX
  |> add (JSX.string "ideographic") ideographic
  |> add (JSX.string "imageRendering") imageRendering
  |> add (JSX.string "in") in_
  |> add (JSX.string "in2") in2
  |> add (JSX.string "intercept") intercept
  |> add (JSX.string "k") k
  |> add (JSX.string "k1") k1
  |> add (JSX.string "k2") k2
  |> add (JSX.string "k3") k3
  |> add (JSX.string "k4") k4
  |> add (JSX.string "kernelMatrix") kernelMatrix
  |> add (JSX.string "kernelUnitLength") kernelUnitLength
  |> add (JSX.string "kerning") kerning
  |> add (JSX.string "keyPoints") keyPoints
  |> add (JSX.string "keySplines") keySplines
  |> add (JSX.string "keyTimes") keyTimes
  |> add (JSX.string "lengthAdjust") lengthAdjust
  |> add (JSX.string "letterSpacing") letterSpacing
  |> add (JSX.string "lightingColor") lightingColor
  |> add (JSX.string "limitingConeAngle") limitingConeAngle
  |> add (JSX.string "local") local
  |> add (JSX.string "markerEnd") markerEnd
  |> add (JSX.string "markerHeight") markerHeight
  |> add (JSX.string "markerMid") markerMid
  |> add (JSX.string "markerStart") markerStart
  |> add (JSX.string "markerUnits") markerUnits
  |> add (JSX.string "markerWidth") markerWidth
  |> add (JSX.string "mask") mask
  |> add (JSX.string "maskContentUnits") maskContentUnits
  |> add (JSX.string "maskUnits") maskUnits
  |> add (JSX.string "mathematical") mathematical
  |> add (JSX.string "mode") mode
  |> add (JSX.string "numOctaves") numOctaves
  |> add (JSX.string "offset") offset
  |> add (JSX.string "opacity") opacity
  |> add (JSX.string "operator") operator
  |> add (JSX.string "order") order
  |> add (JSX.string "orient") orient
  |> add (JSX.string "orientation") orientation
  |> add (JSX.string "origin") origin
  |> add (JSX.string "overflow") overflow
  |> add (JSX.string "overflowX") overflowX
  |> add (JSX.string "overflowY") overflowY
  |> add (JSX.string "overlinePosition") overlinePosition
  |> add (JSX.string "overlineThickness") overlineThickness
  |> add (JSX.string "paintOrder") paintOrder
  |> add (JSX.string "panose1") panose1
  |> add (JSX.string "pathLength") pathLength
  |> add (JSX.string "patternContentUnits") patternContentUnits
  |> add (JSX.string "patternTransform") patternTransform
  |> add (JSX.string "patternUnits") patternUnits
  |> add (JSX.string "pointerEvents") pointerEvents
  |> add (JSX.string "points") points
  |> add (JSX.string "pointsAtX") pointsAtX
  |> add (JSX.string "pointsAtY") pointsAtY
  |> add (JSX.string "pointsAtZ") pointsAtZ
  |> add (JSX.string "preserveAlpha") preserveAlpha
  |> add (JSX.string "preserveAspectRatio") preserveAspectRatio
  |> add (JSX.string "primitiveUnits") primitiveUnits
  |> add (JSX.string "r") r
  |> add (JSX.string "radius") radius
  |> add (JSX.string "refX") refX
  |> add (JSX.string "refY") refY
  |> add (JSX.string "renderingIntent") renderingIntent
  |> add (JSX.string "repeatCount") repeatCount
  |> add (JSX.string "repeatDur") repeatDur
  |> add (JSX.string "requiredExtensions") requiredExtensions
  |> add (JSX.string "requiredFeatures") requiredFeatures
  |> add (JSX.string "restart") restart
  |> add (JSX.string "result") result
  |> add (JSX.string "rotate") rotate
  |> add (JSX.string "rx") rx
  |> add (JSX.string "ry") ry
  |> add (JSX.string "scale") scale
  |> add (JSX.string "seed") seed
  |> add (JSX.string "shapeRendering") shapeRendering
  |> add (JSX.string "slope") slope
  |> add (JSX.string "spacing") spacing
  |> add (JSX.string "specularConstant") specularConstant
  |> add (JSX.string "specularExponent") specularExponent
  |> add (JSX.string "speed") speed
  |> add (JSX.string "spreadMethod") spreadMethod
  |> add (JSX.string "startOffset") startOffset
  |> add (JSX.string "stdDeviation") stdDeviation
  |> add (JSX.string "stemh") stemh
  |> add (JSX.string "stemv") stemv
  |> add (JSX.string "stitchTiles") stitchTiles
  |> add (JSX.string "stopColor") stopColor
  |> add (JSX.string "stopOpacity") stopOpacity
  |> add (JSX.string "strikethroughPosition") strikethroughPosition
  |> add (JSX.string "strikethroughThickness") strikethroughThickness
  |> add (JSX.string "stroke") stroke
  |> add (JSX.string "strokeDasharray") strokeDasharray
  |> add (JSX.string "strokeDashoffset") strokeDashoffset
  |> add (JSX.string "strokeLinecap") strokeLinecap
  |> add (JSX.string "strokeLinejoin") strokeLinejoin
  |> add (JSX.string "strokeMiterlimit") strokeMiterlimit
  |> add (JSX.string "strokeOpacity") strokeOpacity
  |> add (JSX.string "strokeWidth") strokeWidth
  |> add (JSX.string "surfaceScale") surfaceScale
  |> add (JSX.string "systemLanguage") systemLanguage
  |> add (JSX.string "tableValues") tableValues
  |> add (JSX.string "targetX") targetX
  |> add (JSX.string "targetY") targetY
  |> add (JSX.string "textAnchor") textAnchor
  |> add (JSX.string "textDecoration") textDecoration
  |> add (JSX.string "textLength") textLength
  |> add (JSX.string "textRendering") textRendering
  |> add (JSX.string "to") to_
  |> add (JSX.string "transform") transform
  |> add (JSX.string "u1") u1
  |> add (JSX.string "u2") u2
  |> add (JSX.string "underlinePosition") underlinePosition
  |> add (JSX.string "underlineThickness") underlineThickness
  |> add (JSX.string "unicode") unicode
  |> add (JSX.string "unicodeBidi") unicodeBidi
  |> add (JSX.string "unicodeRange") unicodeRange
  |> add (JSX.string "unitsPerEm") unitsPerEm
  |> add (JSX.string "vAlphabetic") vAlphabetic
  |> add (JSX.string "vHanging") vHanging
  |> add (JSX.string "vIdeographic") vIdeographic
  |> add (JSX.string "vMathematical") vMathematical
  |> add (JSX.string "values") values
  |> add (JSX.string "vectorEffect") vectorEffect
  |> add (JSX.string "version") version
  |> add (JSX.string "vertAdvX") vertAdvX
  |> add (JSX.string "vertAdvY") vertAdvY
  |> add (JSX.string "vertOriginX") vertOriginX
  |> add (JSX.string "vertOriginY") vertOriginY
  |> add (JSX.string "viewBox") viewBox
  |> add (JSX.string "viewTarget") viewTarget
  |> add (JSX.string "visibility") visibility
  |> add (JSX.string "widths") widths
  |> add (JSX.string "wordSpacing") wordSpacing
  |> add (JSX.string "writingMode") writingMode
  |> add (JSX.string "x") x
  |> add (JSX.string "x1") x1
  |> add (JSX.string "x2") x2
  |> add (JSX.string "xChannelSelector") xChannelSelector
  |> add (JSX.string "xHeight") xHeight
  |> add (JSX.string "xlinkActuate") xlinkActuate
  |> add (JSX.string "xlinkArcrole") xlinkArcrole
  |> add (JSX.string "xlinkHref") xlinkHref
  |> add (JSX.string "xlinkRole") xlinkRole
  |> add (JSX.string "xlinkShow") xlinkShow
  |> add (JSX.string "xlinkTitle") xlinkTitle
  |> add (JSX.string "xlinkType") xlinkType
  |> add (JSX.string "xmlns") xmlns
  |> add (JSX.string "xmlnsXlink") xmlnsXlink
  |> add (JSX.string "xmlBase") xmlBase
  |> add (JSX.string "xmlLang") xmlLang
  |> add (JSX.string "xmlSpace") xmlSpace
  |> add (JSX.string "y") y
  |> add (JSX.string "y1") y1
  |> add (JSX.string "y2") y2
  |> add (JSX.string "yChannelSelector") yChannelSelector
  |> add (JSX.string "z") z
  |> add (JSX.string "zoomAndPan") zoomAndPan
  |> add (JSX.string "about") about
  |> add (JSX.string "datatype") datatype
  |> add (JSX.string "inlist") inlist
  |> add (JSX.string "prefix") prefix
  |> add (JSX.string "property") property
  |> add (JSX.string "resource") resource
  |> add (JSX.string "typeof") typeof
  |> add (JSX.string "vocab") vocab
  |> add (fun v -> JSX.dangerouslyInnerHtml v.__html) dangerouslySetInnerHTML
  |> add (JSX.bool "suppressContentEditableWarning") suppressContentEditableWarning
  |> add (JSX.bool "suppressHydrationWarning") suppressHydrationWarning
  |> Array.of_list

module Ref = React.Ref
