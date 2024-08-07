let is_react_custom_attribute attr =
  match attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning"
  | "suppressHydrationWarning" ->
      true
  | _ -> false

let attribute_to_html attr =
  match attr with
  (* ignores "ref" prop *)
  | React.JSX.Ref _ -> Html.omitted "ref"
  | Bool (name, _) when is_react_custom_attribute name -> Html.omitted name
  (* false attributes don't get rendered *)
  | Bool (name, false) -> Html.omitted name
  (* true attributes render solely the attribute name *)
  | Bool (name, true) -> Html.present name
  | Style styles -> Html.attribute "style" styles
  | String (name, _value) when is_react_custom_attribute name ->
      Html.omitted name
  | String (name, value) -> Html.attribute name value
  (* Events don't get rendered on SSR *)
  | Event _ -> Html.omitted "Event"
  (* Since we extracted the attribute as children (Element.InnerHtml) in createElement,
     we are very sure there's nothing to render here *)
  | DangerouslyInnerHtml _ -> Html.omitted "dangerouslySetInnerHTML"

let attributes_to_html attrs = attrs |> List.map attribute_to_html

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
    match element with
    | React.Empty -> Html.null
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List list -> list |> Array.to_list |> List.map render_element |> Html.list
    | Upper_case_component component -> render_element (component ())
    | Async_component _component ->
        failwith
          "Asyncronous components can't be rendered to static markup, since \
           rendering is syncronous. Please use `renderToLwtStream` instead."
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        is_root.contents <- false;
        Html.node tag (attributes_to_html attributes) []
    | Lower_case_element { tag; attributes; children } ->
        is_root.contents <- false;
        Html.node tag
          (attributes_to_html attributes)
          (List.map render_element children)
    | Text text -> (
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        match mode with
        | String when is_previous_text_node ->
            Html.list [ Html.raw "<!-- -->"; Html.string text ]
        | _ -> Html.string text)
    | InnerHtml text -> Html.raw text
    | Suspense { children; fallback } -> (
        match render_element children with
        | output ->
            Html.list [ Html.raw "<!--$-->"; output; Html.raw "<!--/$-->" ]
        | exception _e ->
            Html.list
              [
                Html.raw "<!--$!-->";
                render_element fallback;
                Html.raw "<!--/$-->";
              ])
  in
  render_element element

let renderToString element =
  (* TODO: try catch to avoid React.use usages *)
  let html = render_to_string ~mode:String element in
  Html.render html

let renderToStaticMarkup element =
  (* TODO: try catch to avoid React.use usages *)
  let html = render_to_string ~mode:Markup element in
  Html.render html

module Stream = struct
  let create () =
    let stream, push_to_stream = Lwt_stream.create () in
    let push v = push_to_stream @@ Some v in
    let close () = push_to_stream @@ None in
    (stream, push, close)
end

type context_state = {
  stream : string Lwt_stream.t;
  push : Html.element -> unit;
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
  Html.node "script" [] [ Html.raw complete_boundary_script ]

let render_inline_rc_replacement replacements =
  let rc_payload =
    replacements
    |> List.map (fun (b, s) ->
           Html.raw (Printf.sprintf "$RC('B:%i','S:%i')" b s))
    |> Html.list ~separator:";"
  in
  Html.node "script" [] [ rc_payload ]

let render_to_stream ~context_state element =
  let rec render_element element =
    match element with
    | React.Empty -> Lwt.return Html.null
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List arr ->
        let%lwt children_elements =
          arr |> Array.to_list |> Lwt_list.map_p render_element
        in
        Lwt.return (Html.list children_elements)
    | Upper_case_component component -> render_element (component ())
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        Lwt.return (Html.node tag (attributes_to_html attributes) [])
    | Lower_case_element { tag; attributes; children } ->
        let%lwt inner = children |> Lwt_list.map_p render_element in
        Lwt.return (Html.node tag (attributes_to_html attributes) inner)
    | Text text -> Lwt.return (Html.string text)
    | InnerHtml text -> Lwt.return (Html.raw text)
    | Async_component component ->
        let%lwt element = component () in
        render_element element
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
                Lwt.bind promise (fun _ ->
                    (* Enqueue the component with resolved data *)
                    let%lwt resolved =
                      render_resolved_element ~id:current_suspense_id children
                    in
                    context_state.push resolved;
                    (* Enqueue the inline script that replaces fallback by resolved *)
                    context_state.push inline_complete_boundary_script;
                    context_state.push
                      (render_inline_rc_replacement
                         [ (current_boundary_id, current_suspense_id) ]);
                    context_state.waiting <- context_state.waiting - 1;
                    context_state.suspense_id <- context_state.suspense_id + 1;
                    if context_state.waiting = 0 then context_state.close ();
                    Lwt.return_unit));
            (* Return the rendered fallback to SSR syncronous *)
            render_fallback ~boundary_id:current_boundary_id fallback
        | exception _exn ->
            (* TODO: log exn *)
            render_fallback ~boundary_id:context_state.boundary_id fallback)
  and render_resolved_element ~id element =
    render_element element
    |> Lwt.map (fun element ->
           Html.node "div"
             [
               Html.present "hidden";
               Html.attribute "id" (Printf.sprintf "S:%i" id);
             ]
             [ element ])
  and render_fallback ~boundary_id element =
    render_element element
    |> Lwt.map (fun element ->
           Html.list
             [
               Html.raw "<!--$?-->";
               Html.node "template"
                 [ Html.attribute "id" (Printf.sprintf "B:%i" boundary_id) ]
                 [];
               element;
               Html.raw "<!--/$-->";
             ])
  in
  render_element element

let renderToLwtStream element =
  let stream, push, close = Stream.create () in
  let push_html html = push (Html.render html) in
  let context_state =
    {
      stream;
      push = push_html;
      close;
      waiting = 0;
      boundary_id = 0;
      suspense_id = 0;
    }
  in
  let%lwt html = render_to_stream ~context_state element in
  push_html html;
  if context_state.waiting = 0 then close ();
  let abort () =
    (* TODO: Needs to flush the remaining loading fallbacks as HTML, and React.js will try to render the rest on the client. *)
    (* Lwt_stream.closed stream |> Lwt.ignore_result *)
    failwith "abort() isn't supported yet"
  in
  Lwt.return (stream, abort)

let querySelector _str =
  Runtime.fail_impossible_action_in_ssr "ReactDOM.querySelector"

let render _element _node =
  Runtime.fail_impossible_action_in_ssr "ReactDOM.render"

let hydrate _element _node =
  Runtime.fail_impossible_action_in_ssr "ReactDOM.hydrate"

let createPortal _reactElement _domElement = _reactElement

module Style = ReactDOMStyle

let createDOMElementVariadic (tag : string) ~props
    (childrens : React.element array) =
  React.createElement tag props (Array.to_list childrens)

let add kind value map =
  match value with Some i -> map |> List.cons (kind i) | None -> map

type dangerouslySetInnerHTML = < __html : string >

(* `Booleanish_string` are JSX attributes represented as boolean values but rendered as strings on HTML https://github.com/facebook/react/blob/a17467e7e2cd8947c595d1834889b5d184459f12/packages/react-dom-bindings/src/server/ReactFizzConfigDOM.js#L1165-L1176 *)
let booleanish_string name v = React.JSX.string name (string_of_bool v)

[@@@ocamlformat "disable"]
(* domProps isn't used by the generated code from the ppx, and it's purpose is to
   allow usages from user's code via createElementVariadic and custom usages outside JSX. It needs to be in sync with domProps *)
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
  |> add (React.JSX.string "key") key
  |> add React.JSX.ref ref
  |> add (React.JSX.string "aria-details") ariaDetails
  |> add (booleanish_string "aria-disabled") ariaDisabled
  |> add (booleanish_string "aria-hidden") ariaHidden
  |> add (React.JSX.string "aria-keyshortcuts") ariaKeyshortcuts
  |> add (React.JSX.string "aria-label") ariaLabel
  |> add (React.JSX.string "aria-roledescription") ariaRoledescription
  |> add (booleanish_string "aria-expanded") ariaExpanded
  |> add (React.JSX.int "aria-level") ariaLevel
  |> add (booleanish_string "aria-modal") ariaModal
  |> add (booleanish_string "aria-multiline") ariaMultiline
  |> add (booleanish_string "aria-multiselectable") ariaMultiselectable
  |> add (React.JSX.string "aria-placeholder") ariaPlaceholder
  |> add (booleanish_string "aria-readonly") ariaReadonly
  |> add (booleanish_string "aria-required") ariaRequired
  |> add (booleanish_string "aria-selected") ariaSelected
  |> add (React.JSX.string "aria-sort") ariaSort
  |> add (React.JSX.float "aria-valuemax") ariaValuemax
  |> add (React.JSX.float "aria-valuemin") ariaValuemin
  |> add (React.JSX.float "aria-valuenow") ariaValuenow
  |> add (React.JSX.string "aria-valuetext") ariaValuetext
  |> add (booleanish_string "aria-atomic") ariaAtomic
  |> add (booleanish_string "aria-busy") ariaBusy
  |> add (React.JSX.string "aria-relevant") ariaRelevant
  |> add (React.JSX.bool "aria-grabbed") ariaGrabbed
  |> add (React.JSX.string "aria-activedescendant") ariaActivedescendant
  |> add (React.JSX.int "aria-colcount") ariaColcount
  |> add (React.JSX.int "aria-colindex") ariaColindex
  |> add (React.JSX.int "aria-colspan") ariaColspan
  |> add (React.JSX.string "aria-controls") ariaControls
  |> add (React.JSX.string "aria-describedby") ariaDescribedby
  |> add (React.JSX.string "aria-errormessage") ariaErrormessage
  |> add (React.JSX.string "aria-flowto") ariaFlowto
  |> add (React.JSX.string "aria-labelledby") ariaLabelledby
  |> add (React.JSX.string "aria-owns") ariaOwns
  |> add (React.JSX.int "aria-posinset") ariaPosinset
  |> add (React.JSX.int "aria-rowcount") ariaRowcount
  |> add (React.JSX.int "aria-rowindex") ariaRowindex
  |> add (React.JSX.int "aria-rowspan") ariaRowspan
  |> add (React.JSX.int "aria-setsize") ariaSetsize
  |> add (React.JSX.bool "checked") defaultChecked
  |> add (React.JSX.string "value") defaultValue
  |> add (React.JSX.string "accesskey") accessKey
  |> add (React.JSX.string "class") className
  |> add (booleanish_string "contenteditable") contentEditable
  |> add (React.JSX.string "contextmenu") contextMenu
  |> add (React.JSX.string "dir") dir
  |> add (booleanish_string "draggable") draggable
  |> add (React.JSX.bool "hidden") hidden
  |> add (React.JSX.string "id") id
  |> add (React.JSX.string "lang") lang
  |> add (React.JSX.string "role") role
  |> add (fun v -> React.JSX.style (ReactDOMStyle.to_string v)) style
  |> add (booleanish_string "spellcheck") spellCheck
  |> add (React.JSX.int "tabindex") tabIndex
  |> add (React.JSX.string "title") title
  |> add (React.JSX.string "itemid") itemID
  |> add (React.JSX.string "itemorop") itemProp
  |> add (React.JSX.string "itemref") itemRef
  |> add (React.JSX.bool "itemccope") itemScope
  |> add (React.JSX.string "itemtype") itemType
  |> add (React.JSX.string "accept") accept
  |> add (React.JSX.string "accept-charset") acceptCharset
  |> add (React.JSX.string "action") action
  |> add (React.JSX.bool "allowfullscreen") allowFullScreen
  |> add (React.JSX.string "alt") alt
  |> add (React.JSX.bool "async") async
  |> add (React.JSX.string "autocomplete") autoComplete
  |> add (React.JSX.string "autocapitalize") autoCapitalize
  |> add (React.JSX.bool "autofocus") autoFocus
  |> add (React.JSX.bool "autoplay") autoPlay
  |> add (React.JSX.string "challenge") challenge
  |> add (React.JSX.string "charSet") charSet
  |> add (React.JSX.bool "checked") checked
  |> add (React.JSX.string "cite") cite
  |> add (React.JSX.string "crossorigin") crossOrigin
  |> add (React.JSX.int "cols") cols
  |> add (React.JSX.int "colspan") colSpan
  |> add (React.JSX.string "content") content
  |> add (React.JSX.bool "controls") controls
  |> add (React.JSX.string "coords") coords
  |> add (React.JSX.string "data") data
  |> add (React.JSX.string "datetime") dateTime
  |> add (React.JSX.bool "default") default
  |> add (React.JSX.bool "defer") defer
  |> add (React.JSX.bool "disabled") disabled
  |> add (React.JSX.string "download") download
  |> add (React.JSX.string "enctype") encType
  |> add (React.JSX.string "form") form
  |> add (React.JSX.string "formction") formAction
  |> add (React.JSX.string "formtarget") formTarget
  |> add (React.JSX.string "formmethod") formMethod
  |> add (React.JSX.string "headers") headers
  |> add (React.JSX.string "height") height
  |> add (React.JSX.int "high") high
  |> add (React.JSX.string "href") href
  |> add (React.JSX.string "hreflang") hrefLang
  |> add (React.JSX.string "for") htmlFor
  |> add (React.JSX.string "http-eequiv") httpEquiv
  |> add (React.JSX.string "icon") icon
  |> add (React.JSX.string "inputmode") inputMode
  |> add (React.JSX.string "integrity") integrity
  |> add (React.JSX.string "keytype") keyType
  |> add (React.JSX.string "kind") kind
  |> add (React.JSX.string "label") label
  |> add (React.JSX.string "list") list
  |> add (React.JSX.bool "loop") loop
  |> add (React.JSX.int "low") low
  |> add (React.JSX.string "manifest") manifest
  |> add (React.JSX.string "max") max
  |> add (React.JSX.int "maxlength") maxLength
  |> add (React.JSX.string "media") media
  |> add (React.JSX.string "mediagroup") mediaGroup
  |> add (React.JSX.string "method") method_
  |> add (React.JSX.string "min") min
  |> add (React.JSX.int "minlength") minLength
  |> add (React.JSX.bool "multiple") multiple
  |> add (React.JSX.bool "muted") muted
  |> add (React.JSX.string "name") name
  |> add (React.JSX.string "nonce") nonce
  |> add (React.JSX.bool "noValidate") noValidate
  |> add (React.JSX.bool "open") open_
  |> add (React.JSX.int "optimum") optimum
  |> add (React.JSX.string "pattern") pattern
  |> add (React.JSX.string "placeholder") placeholder
  |> add (React.JSX.bool "playsInline") playsInline
  |> add (React.JSX.string "poster") poster
  |> add (React.JSX.string "preload") preload
  |> add (React.JSX.string "radioGroup") radioGroup (* Unsure if it exists? *)
  |> add (React.JSX.bool "readonly") readOnly
  |> add (React.JSX.string "rel") rel
  |> add (React.JSX.bool "required") required
  |> add (React.JSX.bool "reversed") reversed
  |> add (React.JSX.int "rows") rows
  |> add (React.JSX.int "rowspan") rowSpan
  |> add (React.JSX.string "sandbox") sandbox
  |> add (React.JSX.string "scope") scope
  |> add (React.JSX.bool "scoped") scoped
  |> add (React.JSX.string "scrolling") scrolling
  |> add (React.JSX.bool "selected") selected
  |> add (React.JSX.string "shape") shape
  |> add (React.JSX.int "size") size
  |> add (React.JSX.string "sizes") sizes
  |> add (React.JSX.int "span") span
  |> add (React.JSX.string "src") src
  |> add (React.JSX.string "srcdoc") srcDoc
  |> add (React.JSX.string "srclang") srcLang
  |> add (React.JSX.string "srcset") srcSet
  |> add (React.JSX.int "start") start
  |> add (React.JSX.float "step") step
  |> add (React.JSX.string "summary") summary
  |> add (React.JSX.string "target") target
  |> add (React.JSX.string "type") type_
  |> add (React.JSX.string "useMap") useMap
  |> add (React.JSX.string "value") value
  |> add (React.JSX.string "width") width
  |> add (React.JSX.string "wrap") wrap
  |> add (React.JSX.Event.clipboard "onCopy") onCopy
  |> add (React.JSX.Event.clipboard "onCut") onCut
  |> add (React.JSX.Event.clipboard "onPaste") onPaste
  |> add (React.JSX.Event.composition "onCompositionEnd") onCompositionEnd
  |> add (React.JSX.Event.composition "onCompositionStart") onCompositionStart
  |> add (React.JSX.Event.composition "onCompositionUpdate") onCompositionUpdate
  |> add (React.JSX.Event.keyboard "onKeyDown") onKeyDown
  |> add (React.JSX.Event.keyboard "onKeyPress") onKeyPress
  |> add (React.JSX.Event.keyboard "onKeyUp") onKeyUp
  |> add (React.JSX.Event.focus "onFocus") onFocus
  |> add (React.JSX.Event.focus "onBlur") onBlur
  |> add (React.JSX.Event.form "onChange") onChange
  |> add (React.JSX.Event.form "onInput") onInput
  |> add (React.JSX.Event.form "onSubmit") onSubmit
  |> add (React.JSX.Event.form "onInvalid") onInvalid
  |> add (React.JSX.Event.mouse "onClick") onClick
  |> add (React.JSX.Event.mouse "onContextMenu") onContextMenu
  |> add (React.JSX.Event.mouse "onDoubleClick") onDoubleClick
  |> add (React.JSX.Event.mouse "onDrag") onDrag
  |> add (React.JSX.Event.mouse "onDragEnd") onDragEnd
  |> add (React.JSX.Event.mouse "onDragEnter") onDragEnter
  |> add (React.JSX.Event.mouse "onDragExit") onDragExit
  |> add (React.JSX.Event.mouse "onDragLeave") onDragLeave
  |> add (React.JSX.Event.mouse "onDragOver") onDragOver
  |> add (React.JSX.Event.mouse "onDragStart") onDragStart
  |> add (React.JSX.Event.mouse "onDrop") onDrop
  |> add (React.JSX.Event.mouse "onMouseDown") onMouseDown
  |> add (React.JSX.Event.mouse "onMouseEnter") onMouseEnter
  |> add (React.JSX.Event.mouse "onMouseLeave") onMouseLeave
  |> add (React.JSX.Event.mouse "onMouseMove") onMouseMove
  |> add (React.JSX.Event.mouse "onMouseOut") onMouseOut
  |> add (React.JSX.Event.mouse "onMouseOver") onMouseOver
  |> add (React.JSX.Event.mouse "onMouseUp") onMouseUp
  |> add (React.JSX.Event.selection "onSelect") onSelect
  |> add (React.JSX.Event.touch "onTouchCancel") onTouchCancel
  |> add (React.JSX.Event.touch "onTouchEnd") onTouchEnd
  |> add (React.JSX.Event.touch "onTouchMove") onTouchMove
  |> add (React.JSX.Event.touch "onTouchStart") onTouchStart
  |> add (React.JSX.Event.pointer "onPointerOver") onPointerOver
  |> add (React.JSX.Event.pointer "onPointerEnter") onPointerEnter
  |> add (React.JSX.Event.pointer "onPointerDown") onPointerDown
  |> add (React.JSX.Event.pointer "onPointerMove") onPointerMove
  |> add (React.JSX.Event.pointer "onPointerUp") onPointerUp
  |> add (React.JSX.Event.pointer "onPointerCancel") onPointerCancel
  |> add (React.JSX.Event.pointer "onPointerOut") onPointerOut
  |> add (React.JSX.Event.pointer "onPointerLeave") onPointerLeave
  |> add (React.JSX.Event.pointer "onGotPointerCapture") onGotPointerCapture
  |> add (React.JSX.Event.pointer "onLostPointerCapture") onLostPointerCapture
  |> add (React.JSX.Event.ui "onScroll") onScroll
  |> add (React.JSX.Event.wheel "onWheel") onWheel
  |> add (React.JSX.Event.media "onAbort") onAbort
  |> add (React.JSX.Event.media "onCanPlay") onCanPlay
  |> add (React.JSX.Event.media "onCanPlayThrough") onCanPlayThrough
  |> add (React.JSX.Event.media "onDurationChange") onDurationChange
  |> add (React.JSX.Event.media "onEmptied") onEmptied
  |> add (React.JSX.Event.media "onEncrypetd") onEncrypetd
  |> add (React.JSX.Event.media "onEnded") onEnded
  |> add (React.JSX.Event.media "onError") onError
  |> add (React.JSX.Event.media "onLoadedData") onLoadedData
  |> add (React.JSX.Event.media "onLoadedMetadata") onLoadedMetadata
  |> add (React.JSX.Event.media "onLoadStart") onLoadStart
  |> add (React.JSX.Event.media "onPause") onPause
  |> add (React.JSX.Event.media "onPlay") onPlay
  |> add (React.JSX.Event.media "onPlaying") onPlaying
  |> add (React.JSX.Event.media "onProgress") onProgress
  |> add (React.JSX.Event.media "onRateChange") onRateChange
  |> add (React.JSX.Event.media "onSeeked") onSeeked
  |> add (React.JSX.Event.media "onSeeking") onSeeking
  |> add (React.JSX.Event.media "onStalled") onStalled
  |> add (React.JSX.Event.media "onSuspend") onSuspend
  |> add (React.JSX.Event.media "onTimeUpdate") onTimeUpdate
  |> add (React.JSX.Event.media "onVolumeChange") onVolumeChange
  |> add (React.JSX.Event.media "onWaiting") onWaiting
  |> add (React.JSX.Event.animation "onAnimationStart") onAnimationStart
  |> add (React.JSX.Event.animation "onAnimationEnd") onAnimationEnd
  |> add (React.JSX.Event.animation "onAnimationIteration") onAnimationIteration
  |> add (React.JSX.Event.transition "onTransitionEnd") onTransitionEnd
  |> add (React.JSX.string "accent-height") accentHeight
  |> add (React.JSX.string "accumulate") accumulate
  |> add (React.JSX.string "additive") additive
  |> add (React.JSX.string "alignment-baseline") alignmentBaseline
  |> add (React.JSX.string "allowReorder") allowReorder (* Does it exist? *)
  |> add (React.JSX.string "alphabetic") alphabetic
  |> add (React.JSX.string "amplitude") amplitude
  |> add (React.JSX.string "arabic-form") arabicForm
  |> add (React.JSX.string "ascent") ascent
  |> add (React.JSX.string "attributeName") attributeName
  |> add (React.JSX.string "attributeType") attributeType
  |> add (React.JSX.string "autoReverse") autoReverse (* Does it exist? *)
  |> add (React.JSX.string "azimuth") azimuth
  |> add (React.JSX.string "baseFrequency") baseFrequency
  |> add (React.JSX.string "baseProfile") baseProfile
  |> add (React.JSX.string "baselineShift") baselineShift
  |> add (React.JSX.string "bbox") bbox
  |> add (React.JSX.string "begin") begin_
  |> add (React.JSX.string "bias") bias
  |> add (React.JSX.string "by") by
  |> add (React.JSX.string "calcMode") calcMode
  |> add (React.JSX.string "capHeight") capHeight
  |> add (React.JSX.string "clip") clip
  |> add (React.JSX.string "clipPath") clipPath
  |> add (React.JSX.string "clipPathUnits") clipPathUnits
  |> add (React.JSX.string "clipRule") clipRule
  |> add (React.JSX.string "colorInterpolation") colorInterpolation
  |> add (React.JSX.string "colorInterpolationFilters") colorInterpolationFilters
  |> add (React.JSX.string "colorProfile") colorProfile
  |> add (React.JSX.string "colorRendering") colorRendering
  |> add (React.JSX.string "contentScriptType") contentScriptType
  |> add (React.JSX.string "contentStyleType") contentStyleType
  |> add (React.JSX.string "cursor") cursor
  |> add (React.JSX.string "cx") cx
  |> add (React.JSX.string "cy") cy
  |> add (React.JSX.string "d") d
  |> add (React.JSX.string "decelerate") decelerate
  |> add (React.JSX.string "descent") descent
  |> add (React.JSX.string "diffuseConstant") diffuseConstant
  |> add (React.JSX.string "direction") direction
  |> add (React.JSX.string "display") display
  |> add (React.JSX.string "divisor") divisor
  |> add (React.JSX.string "dominantBaseline") dominantBaseline
  |> add (React.JSX.string "dur") dur
  |> add (React.JSX.string "dx") dx
  |> add (React.JSX.string "dy") dy
  |> add (React.JSX.string "edgeMode") edgeMode
  |> add (React.JSX.string "elevation") elevation
  |> add (React.JSX.string "enableBackground") enableBackground
  |> add (React.JSX.string "end") end_
  |> add (React.JSX.string "exponent") exponent
  |> add (React.JSX.string "externalResourcesRequired") externalResourcesRequired
  |> add (React.JSX.string "fill") fill
  |> add (React.JSX.string "fillOpacity") fillOpacity
  |> add (React.JSX.string "fillRule") fillRule
  |> add (React.JSX.string "filter") filter
  |> add (React.JSX.string "filterRes") filterRes
  |> add (React.JSX.string "filterUnits") filterUnits
  |> add (React.JSX.string "flood-color") floodColor
  |> add (React.JSX.string "flood-opacity") floodOpacity
  |> add (React.JSX.string "focusable") focusable
  |> add (React.JSX.string "font-family") fontFamily
  |> add (React.JSX.string "font-size") fontSize
  |> add (React.JSX.string "font-size-adjust") fontSizeAdjust
  |> add (React.JSX.string "font-stretch") fontStretch
  |> add (React.JSX.string "font-style") fontStyle
  |> add (React.JSX.string "font-variant") fontVariant
  |> add (React.JSX.string "font-weight") fontWeight
  |> add (React.JSX.string "fomat") fomat
  |> add (React.JSX.string "from") from
  |> add (React.JSX.string "fx") fx
  |> add (React.JSX.string "fy") fy
  |> add (React.JSX.string "g1") g1
  |> add (React.JSX.string "g2") g2
  |> add (React.JSX.string "glyph-name") glyphName
  |> add (React.JSX.string "glyph-orientation-horizontal") glyphOrientationHorizontal
  |> add (React.JSX.string "glyph-orientation-vertical") glyphOrientationVertical
  |> add (React.JSX.string "glyphRef") glyphRef
  |> add (React.JSX.string "gradientTransform") gradientTransform
  |> add (React.JSX.string "gradientUnits") gradientUnits
  |> add (React.JSX.string "hanging") hanging
  |> add (React.JSX.string "horiz-adv-x") horizAdvX
  |> add (React.JSX.string "horiz-origin-x") horizOriginX
  (* |> add (React.JSX.string "horiz-origin-y") horizOriginY *) (* Should be added *)
  |> add (React.JSX.string "ideographic") ideographic
  |> add (React.JSX.string "image-rendering") imageRendering
  |> add (React.JSX.string "in") in_
  |> add (React.JSX.string "in2") in2
  |> add (React.JSX.string "intercept") intercept
  |> add (React.JSX.string "k") k
  |> add (React.JSX.string "k1") k1
  |> add (React.JSX.string "k2") k2
  |> add (React.JSX.string "k3") k3
  |> add (React.JSX.string "k4") k4
  |> add (React.JSX.string "kernelMatrix") kernelMatrix
  |> add (React.JSX.string "kernelUnitLength") kernelUnitLength
  |> add (React.JSX.string "kerning") kerning
  |> add (React.JSX.string "keyPoints") keyPoints
  |> add (React.JSX.string "keySplines") keySplines
  |> add (React.JSX.string "keyTimes") keyTimes
  |> add (React.JSX.string "lengthAdjust") lengthAdjust
  |> add (React.JSX.string "letterSpacing") letterSpacing
  |> add (React.JSX.string "lightingColor") lightingColor
  |> add (React.JSX.string "limitingConeAngle") limitingConeAngle
  |> add (React.JSX.string "local") local
  |> add (React.JSX.string "marker-end") markerEnd
  |> add (React.JSX.string "marker-height") markerHeight
  |> add (React.JSX.string "marker-mid") markerMid
  |> add (React.JSX.string "marker-start") markerStart
  |> add (React.JSX.string "marker-units") markerUnits
  |> add (React.JSX.string "markerWidth") markerWidth
  |> add (React.JSX.string "mask") mask
  |> add (React.JSX.string "maskContentUnits") maskContentUnits
  |> add (React.JSX.string "maskUnits") maskUnits
  |> add (React.JSX.string "mathematical") mathematical
  |> add (React.JSX.string "mode") mode
  |> add (React.JSX.string "numOctaves") numOctaves
  |> add (React.JSX.string "offset") offset
  |> add (React.JSX.string "opacity") opacity
  |> add (React.JSX.string "operator") operator
  |> add (React.JSX.string "order") order
  |> add (React.JSX.string "orient") orient
  |> add (React.JSX.string "orientation") orientation
  |> add (React.JSX.string "origin") origin
  |> add (React.JSX.string "overflow") overflow
  |> add (React.JSX.string "overflowX") overflowX
  |> add (React.JSX.string "overflowY") overflowY
  |> add (React.JSX.string "overline-position") overlinePosition
  |> add (React.JSX.string "overline-thickness") overlineThickness
  |> add (React.JSX.string "paint-order") paintOrder
  |> add (React.JSX.string "panose1") panose1
  |> add (React.JSX.string "pathLength") pathLength
  |> add (React.JSX.string "patternContentUnits") patternContentUnits
  |> add (React.JSX.string "patternTransform") patternTransform
  |> add (React.JSX.string "patternUnits") patternUnits
  |> add (React.JSX.string "pointerEvents") pointerEvents
  |> add (React.JSX.string "points") points
  |> add (React.JSX.string "pointsAtX") pointsAtX
  |> add (React.JSX.string "pointsAtY") pointsAtY
  |> add (React.JSX.string "pointsAtZ") pointsAtZ
  |> add (React.JSX.string "preserveAlpha") preserveAlpha
  |> add (React.JSX.string "preserveAspectRatio") preserveAspectRatio
  |> add (React.JSX.string "primitiveUnits") primitiveUnits
  |> add (React.JSX.string "r") r
  |> add (React.JSX.string "radius") radius
  |> add (React.JSX.string "refX") refX
  |> add (React.JSX.string "refY") refY
  |> add (React.JSX.string "renderingIntent") renderingIntent (* Does it exist? *)
  |> add (React.JSX.string "repeatCount") repeatCount
  |> add (React.JSX.string "repeatDur") repeatDur
  |> add (React.JSX.string "requiredExtensions") requiredExtensions (* Does it exists? *)
  |> add (React.JSX.string "requiredFeatures") requiredFeatures
  |> add (React.JSX.string "restart") restart
  |> add (React.JSX.string "result") result
  |> add (React.JSX.string "rotate") rotate
  |> add (React.JSX.string "rx") rx
  |> add (React.JSX.string "ry") ry
  |> add (React.JSX.string "scale") scale
  |> add (React.JSX.string "seed") seed
  |> add (React.JSX.string "shape-rendering") shapeRendering
  |> add (React.JSX.string "slope") slope
  |> add (React.JSX.string "spacing") spacing
  |> add (React.JSX.string "specularConstant") specularConstant
  |> add (React.JSX.string "specularExponent") specularExponent
  |> add (React.JSX.string "speed") speed
  |> add (React.JSX.string "spreadMethod") spreadMethod
  |> add (React.JSX.string "startOffset") startOffset
  |> add (React.JSX.string "stdDeviation") stdDeviation
  |> add (React.JSX.string "stemh") stemh
  |> add (React.JSX.string "stemv") stemv
  |> add (React.JSX.string "stitchTiles") stitchTiles
  |> add (React.JSX.string "stopColor") stopColor
  |> add (React.JSX.string "stopOpacity") stopOpacity
  |> add (React.JSX.string "strikethrough-position") strikethroughPosition
  |> add (React.JSX.string "strikethrough-thickness") strikethroughThickness
  |> add (React.JSX.string "stroke") stroke
  |> add (React.JSX.string "stroke-dasharray") strokeDasharray
  |> add (React.JSX.string "stroke-dashoffset") strokeDashoffset
  |> add (React.JSX.string "stroke-linecap") strokeLinecap
  |> add (React.JSX.string "stroke-linejoin") strokeLinejoin
  |> add (React.JSX.string "stroke-miterlimit") strokeMiterlimit
  |> add (React.JSX.string "stroke-opacity") strokeOpacity
  |> add (React.JSX.string "stroke-width") strokeWidth
  |> add (React.JSX.string "surfaceScale") surfaceScale
  |> add (React.JSX.string "systemLanguage") systemLanguage
  |> add (React.JSX.string "tableValues") tableValues
  |> add (React.JSX.string "targetX") targetX
  |> add (React.JSX.string "targetY") targetY
  |> add (React.JSX.string "text-anchor") textAnchor
  |> add (React.JSX.string "text-decoration") textDecoration
  |> add (React.JSX.string "textLength") textLength
  |> add (React.JSX.string "text-rendering") textRendering
  |> add (React.JSX.string "to") to_
  |> add (React.JSX.string "transform") transform
  |> add (React.JSX.string "u1") u1
  |> add (React.JSX.string "u2") u2
  |> add (React.JSX.string "underline-position") underlinePosition
  |> add (React.JSX.string "underline-thickness") underlineThickness
  |> add (React.JSX.string "unicode") unicode
  |> add (React.JSX.string "unicode-bidi") unicodeBidi
  |> add (React.JSX.string "unicode-range") unicodeRange
  |> add (React.JSX.string "units-per-em") unitsPerEm
  |> add (React.JSX.string "v-alphabetic") vAlphabetic
  |> add (React.JSX.string "v-hanging") vHanging
  |> add (React.JSX.string "v-ideographic") vIdeographic
  |> add (React.JSX.string "vMathematical") vMathematical (* Does it exists? *)
  |> add (React.JSX.string "values") values
  |> add (React.JSX.string "vector-effect") vectorEffect
  |> add (React.JSX.string "version") version
  |> add (React.JSX.string "vert-adv-x") vertAdvX
  |> add (React.JSX.string "vert-adv-y") vertAdvY
  |> add (React.JSX.string "vert-origin-x") vertOriginX
  |> add (React.JSX.string "vert-origin-y") vertOriginY
  |> add (React.JSX.string "viewBox") viewBox
  |> add (React.JSX.string "viewTarget") viewTarget
  |> add (React.JSX.string "visibility") visibility
  |> add (React.JSX.string "widths") widths
  |> add (React.JSX.string "word-spacing") wordSpacing
  |> add (React.JSX.string "writing-mode") writingMode
  |> add (React.JSX.string "x") x
  |> add (React.JSX.string "x1") x1
  |> add (React.JSX.string "x2") x2
  |> add (React.JSX.string "xChannelSelector") xChannelSelector
  |> add (React.JSX.string "x-height") xHeight
  |> add (React.JSX.string "xlink:arcrole") xlinkActuate
  |> add (React.JSX.string "xlinkArcrole") xlinkArcrole
  |> add (React.JSX.string "xlink:href") xlinkHref
  |> add (React.JSX.string "xlink:role") xlinkRole
  |> add (React.JSX.string "xlink:show") xlinkShow
  |> add (React.JSX.string "xlink:title") xlinkTitle
  |> add (React.JSX.string "xlink:type") xlinkType
  |> add (React.JSX.string "xmlns") xmlns
  |> add (React.JSX.string "xmlnsXlink") xmlnsXlink
  |> add (React.JSX.string "xml:base") xmlBase
  |> add (React.JSX.string "xml:lang") xmlLang
  |> add (React.JSX.string "xml:space") xmlSpace
  |> add (React.JSX.string "y") y
  |> add (React.JSX.string "y1") y1
  |> add (React.JSX.string "y2") y2
  |> add (React.JSX.string "yChannelSelector") yChannelSelector
  |> add (React.JSX.string "z") z
  |> add (React.JSX.string "zoomAndPan") zoomAndPan
  |> add (React.JSX.string "about") about
  |> add (React.JSX.string "datatype") datatype
  |> add (React.JSX.string "inlist") inlist
  |> add (React.JSX.string "prefix") prefix
  |> add (React.JSX.string "property") property
  |> add (React.JSX.string "resource") resource
  |> add (React.JSX.string "typeof") typeof
  |> add (React.JSX.string "vocab") vocab
  |> add (React.JSX.dangerouslyInnerHtml) dangerouslySetInnerHTML
  |> add (React.JSX.bool "suppressContentEditableWarning") suppressContentEditableWarning
  |> add (React.JSX.bool "suppressHydrationWarning") suppressHydrationWarning

module Ref = React.Ref

type domRef = Ref.t
