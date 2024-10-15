let is_react_custom_attribute attr =
  match attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning"
  | "suppressHydrationWarning" ->
      true
  | _ -> false

let attribute_to_html attr =
  match attr with
  (* ignores "ref" prop *)
  | React.JSX.Ref _ -> Html.omitted ()
  | Bool ((name, _), _) when is_react_custom_attribute name -> Html.omitted ()
  (* false attributes don't get rendered *)
  | Bool (_name, false) -> Html.omitted ()
  (* true attributes render solely the attribute name *)
  | Bool ((name, _), true) -> Html.present name
  | Style styles -> Html.attribute "style" styles
  | String ((name, _), _value) when is_react_custom_attribute name ->
      Html.omitted ()
  | String ((name, _), value) -> Html.attribute name value
  (* Events don't get rendered on SSR *)
  | Event _ -> Html.omitted ()
  (* Since we extracted the attribute as children (Element.InnerHtml) in createElement,
     we are very sure there's nothing to render here *)
  | DangerouslyInnerHtml _ -> Html.omitted ()

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
let getPropByName name =
  match DomProps.findByName name with
  | Ok prop -> (name, DomProps.getJSXName prop)
  | Error _ -> failwith "Invalid prop"

let string name v = React.JSX.string (getPropByName name) v
let int name v = React.JSX.int (getPropByName name) v
let bool name v = React.JSX.bool (getPropByName name) v

let booleanish_string name v =
  React.JSX.string (getPropByName name) (string_of_bool v)

let float name v = React.JSX.float (getPropByName name) v

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
  |> add (string "key") key
  |> add React.JSX.ref ref
  |> add (string "aria-details") ariaDetails
  |> add (booleanish_string "aria-disabled") ariaDisabled
  |> add (booleanish_string "aria-hidden") ariaHidden
  |> add (string "aria-keyshortcuts") ariaKeyshortcuts
  |> add (string "aria-label") ariaLabel
  |> add (string "aria-roledescription") ariaRoledescription
  |> add (booleanish_string "aria-expanded") ariaExpanded
  |> add (int "aria-level") ariaLevel
  |> add (booleanish_string "aria-modal") ariaModal
  |> add (booleanish_string "aria-multiline") ariaMultiline
  |> add (booleanish_string "aria-multiselectable") ariaMultiselectable
  |> add (string "aria-placeholder") ariaPlaceholder
  |> add (booleanish_string "aria-readonly") ariaReadonly
  |> add (booleanish_string "aria-required") ariaRequired
  |> add (booleanish_string "aria-selected") ariaSelected
  |> add (string "aria-sort") ariaSort
  |> add (float "aria-valuemax") ariaValuemax
  |> add (float "aria-valuemin") ariaValuemin
  |> add (float "aria-valuenow") ariaValuenow
  |> add (string "aria-valuetext") ariaValuetext
  |> add (booleanish_string "aria-atomic") ariaAtomic
  |> add (booleanish_string "aria-busy") ariaBusy
  |> add (string "aria-relevant") ariaRelevant
  |> add (bool "aria-grabbed") ariaGrabbed
  |> add (string "aria-activedescendant") ariaActivedescendant
  |> add (int "aria-colcount") ariaColcount
  |> add (int "aria-colindex") ariaColindex
  |> add (int "aria-colspan") ariaColspan
  |> add (string "aria-controls") ariaControls
  |> add (string "aria-describedby") ariaDescribedby
  |> add (string "aria-errormessage") ariaErrormessage
  |> add (string "aria-flowto") ariaFlowto
  |> add (string "aria-labelledby") ariaLabelledby
  |> add (string "aria-owns") ariaOwns
  |> add (int "aria-posinset") ariaPosinset
  |> add (int "aria-rowcount") ariaRowcount
  |> add (int "aria-rowindex") ariaRowindex
  |> add (int "aria-rowspan") ariaRowspan
  |> add (int "aria-setsize") ariaSetsize
  |> add (bool "checked") defaultChecked
  |> add (string "value") defaultValue
  |> add (string "accesskey") accessKey
  |> add (string "class") className
  |> add (booleanish_string "contenteditable") contentEditable
  |> add (string "contextmenu") contextMenu
  |> add (string "dir") dir
  |> add (booleanish_string "draggable") draggable
  |> add (bool "hidden") hidden
  |> add (string "id") id
  |> add (string "lang") lang
  |> add (string "role") role
  |> add (fun v -> React.JSX.style (ReactDOMStyle.to_string v)) style
  |> add (booleanish_string "spellcheck") spellCheck
  |> add (int "tabindex") tabIndex
  |> add (string "title") title
  |> add (string "itemid") itemID
  |> add (string "itemorop") itemProp
  |> add (string "itemref") itemRef
  |> add (bool "itemccope") itemScope
  |> add (string "itemtype") itemType
  |> add (string "accept") accept
  |> add (string "accept-charset") acceptCharset
  |> add (string "action") action
  |> add (bool "allowfullscreen") allowFullScreen
  |> add (string "alt") alt
  |> add (bool "async") async
  |> add (string "autocomplete") autoComplete
  |> add (string "autocapitalize") autoCapitalize
  |> add (bool "autofocus") autoFocus
  |> add (bool "autoplay") autoPlay
  |> add (string "challenge") challenge
  |> add (string "charSet") charSet
  |> add (bool "checked") checked
  |> add (string "cite") cite
  |> add (string "crossorigin") crossOrigin
  |> add (int "cols") cols
  |> add (int "colspan") colSpan
  |> add (string "content") content
  |> add (bool "controls") controls
  |> add (string "coords") coords
  |> add (string "data") data
  |> add (string "datetime") dateTime
  |> add (bool "default") default
  |> add (bool "defer") defer
  |> add (bool "disabled") disabled
  |> add (string "download") download
  |> add (string "enctype") encType
  |> add (string "form") form
  |> add (string "formction") formAction
  |> add (string "formtarget") formTarget
  |> add (string "formmethod") formMethod
  |> add (string "headers") headers
  |> add (string "height") height
  |> add (int "high") high
  |> add (string "href") href
  |> add (string "hreflang") hrefLang
  |> add (string "for") htmlFor
  |> add (string "http-eequiv") httpEquiv
  |> add (string "icon") icon
  |> add (string "inputmode") inputMode
  |> add (string "integrity") integrity
  |> add (string "keytype") keyType
  |> add (string "kind") kind
  |> add (string "label") label
  |> add (string "list") list
  |> add (bool "loop") loop
  |> add (int "low") low
  |> add (string "manifest") manifest
  |> add (string "max") max
  |> add (int "maxlength") maxLength
  |> add (string "media") media
  |> add (string "mediagroup") mediaGroup
  |> add (string "method") method_
  |> add (string "min") min
  |> add (int "minlength") minLength
  |> add (bool "multiple") multiple
  |> add (bool "muted") muted
  |> add (string "name") name
  |> add (string "nonce") nonce
  |> add (bool "noValidate") noValidate
  |> add (bool "open") open_
  |> add (int "optimum") optimum
  |> add (string "pattern") pattern
  |> add (string "placeholder") placeholder
  |> add (bool "playsInline") playsInline
  |> add (string "poster") poster
  |> add (string "preload") preload
  |> add (string "radioGroup") radioGroup (* Unsure if it exists? *)
  |> add (bool "readonly") readOnly
  |> add (string "rel") rel
  |> add (bool "required") required
  |> add (bool "reversed") reversed
  |> add (int "rows") rows
  |> add (int "rowspan") rowSpan
  |> add (string "sandbox") sandbox
  |> add (string "scope") scope
  |> add (bool "scoped") scoped
  |> add (string "scrolling") scrolling
  |> add (bool "selected") selected
  |> add (string "shape") shape
  |> add (int "size") size
  |> add (string "sizes") sizes
  |> add (int "span") span
  |> add (string "src") src
  |> add (string "srcdoc") srcDoc
  |> add (string "srclang") srcLang
  |> add (string "srcset") srcSet
  |> add (int "start") start
  |> add (float "step") step
  |> add (string "summary") summary
  |> add (string "target") target
  |> add (string "type") type_
  |> add (string "useMap") useMap
  |> add (string "value") value
  |> add (string "width") width
  |> add (string "wrap") wrap
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
  |> add (string "accent-height") accentHeight
  |> add (string "accumulate") accumulate
  |> add (string "additive") additive
  |> add (string "alignment-baseline") alignmentBaseline
  |> add (string "allowReorder") allowReorder (* Does it exist? *)
  |> add (string "alphabetic") alphabetic
  |> add (string "amplitude") amplitude
  |> add (string "arabic-form") arabicForm
  |> add (string "ascent") ascent
  |> add (string "attributeName") attributeName
  |> add (string "attributeType") attributeType
  |> add (string "autoReverse") autoReverse (* Does it exist? *)
  |> add (string "azimuth") azimuth
  |> add (string "baseFrequency") baseFrequency
  |> add (string "baseProfile") baseProfile
  |> add (string "baselineShift") baselineShift
  |> add (string "bbox") bbox
  |> add (string "begin") begin_
  |> add (string "bias") bias
  |> add (string "by") by
  |> add (string "calcMode") calcMode
  |> add (string "capHeight") capHeight
  |> add (string "clip") clip
  |> add (string "clipPath") clipPath
  |> add (string "clipPathUnits") clipPathUnits
  |> add (string "clipRule") clipRule
  |> add (string "colorInterpolation") colorInterpolation
  |> add (string "colorInterpolationFilters") colorInterpolationFilters
  |> add (string "colorProfile") colorProfile
  |> add (string "colorRendering") colorRendering
  |> add (string "contentScriptType") contentScriptType
  |> add (string "contentStyleType") contentStyleType
  |> add (string "cursor") cursor
  |> add (string "cx") cx
  |> add (string "cy") cy
  |> add (string "d") d
  |> add (string "decelerate") decelerate
  |> add (string "descent") descent
  |> add (string "diffuseConstant") diffuseConstant
  |> add (string "direction") direction
  |> add (string "display") display
  |> add (string "divisor") divisor
  |> add (string "dominantBaseline") dominantBaseline
  |> add (string "dur") dur
  |> add (string "dx") dx
  |> add (string "dy") dy
  |> add (string "edgeMode") edgeMode
  |> add (string "elevation") elevation
  |> add (string "enableBackground") enableBackground
  |> add (string "end") end_
  |> add (string "exponent") exponent
  |> add (string "externalResourcesRequired") externalResourcesRequired
  |> add (string "fill") fill
  |> add (string "fillOpacity") fillOpacity
  |> add (string "fillRule") fillRule
  |> add (string "filter") filter
  |> add (string "filterRes") filterRes
  |> add (string "filterUnits") filterUnits
  |> add (string "flood-color") floodColor
  |> add (string "flood-opacity") floodOpacity
  |> add (string "focusable") focusable
  |> add (string "font-family") fontFamily
  |> add (string "font-size") fontSize
  |> add (string "font-size-adjust") fontSizeAdjust
  |> add (string "font-stretch") fontStretch
  |> add (string "font-style") fontStyle
  |> add (string "font-variant") fontVariant
  |> add (string "font-weight") fontWeight
  |> add (string "fomat") fomat
  |> add (string "from") from
  |> add (string "fx") fx
  |> add (string "fy") fy
  |> add (string "g1") g1
  |> add (string "g2") g2
  |> add (string "glyph-name") glyphName
  |> add (string "glyph-orientation-horizontal") glyphOrientationHorizontal
  |> add (string "glyph-orientation-vertical") glyphOrientationVertical
  |> add (string "glyphRef") glyphRef
  |> add (string "gradientTransform") gradientTransform
  |> add (string "gradientUnits") gradientUnits
  |> add (string "hanging") hanging
  |> add (string "horiz-adv-x") horizAdvX
  |> add (string "horiz-origin-x") horizOriginX
  (* |> add (string "horiz-origin-y") horizOriginY *) (* Should be added *)
  |> add (string "ideographic") ideographic
  |> add (string "image-rendering") imageRendering
  |> add (string "in") in_
  |> add (string "in2") in2
  |> add (string "intercept") intercept
  |> add (string "k") k
  |> add (string "k1") k1
  |> add (string "k2") k2
  |> add (string "k3") k3
  |> add (string "k4") k4
  |> add (string "kernelMatrix") kernelMatrix
  |> add (string "kernelUnitLength") kernelUnitLength
  |> add (string "kerning") kerning
  |> add (string "keyPoints") keyPoints
  |> add (string "keySplines") keySplines
  |> add (string "keyTimes") keyTimes
  |> add (string "lengthAdjust") lengthAdjust
  |> add (string "letterSpacing") letterSpacing
  |> add (string "lightingColor") lightingColor
  |> add (string "limitingConeAngle") limitingConeAngle
  |> add (string "local") local
  |> add (string "marker-end") markerEnd
  |> add (string "marker-height") markerHeight
  |> add (string "marker-mid") markerMid
  |> add (string "marker-start") markerStart
  |> add (string "marker-units") markerUnits
  |> add (string "markerWidth") markerWidth
  |> add (string "mask") mask
  |> add (string "maskContentUnits") maskContentUnits
  |> add (string "maskUnits") maskUnits
  |> add (string "mathematical") mathematical
  |> add (string "mode") mode
  |> add (string "numOctaves") numOctaves
  |> add (string "offset") offset
  |> add (string "opacity") opacity
  |> add (string "operator") operator
  |> add (string "order") order
  |> add (string "orient") orient
  |> add (string "orientation") orientation
  |> add (string "origin") origin
  |> add (string "overflow") overflow
  |> add (string "overflowX") overflowX
  |> add (string "overflowY") overflowY
  |> add (string "overline-position") overlinePosition
  |> add (string "overline-thickness") overlineThickness
  |> add (string "paint-order") paintOrder
  |> add (string "panose1") panose1
  |> add (string "pathLength") pathLength
  |> add (string "patternContentUnits") patternContentUnits
  |> add (string "patternTransform") patternTransform
  |> add (string "patternUnits") patternUnits
  |> add (string "pointerEvents") pointerEvents
  |> add (string "points") points
  |> add (string "pointsAtX") pointsAtX
  |> add (string "pointsAtY") pointsAtY
  |> add (string "pointsAtZ") pointsAtZ
  |> add (string "preserveAlpha") preserveAlpha
  |> add (string "preserveAspectRatio") preserveAspectRatio
  |> add (string "primitiveUnits") primitiveUnits
  |> add (string "r") r
  |> add (string "radius") radius
  |> add (string "refX") refX
  |> add (string "refY") refY
  |> add (string "renderingIntent") renderingIntent (* Does it exist? *)
  |> add (string "repeatCount") repeatCount
  |> add (string "repeatDur") repeatDur
  |> add (string "requiredExtensions") requiredExtensions (* Does it exists? *)
  |> add (string "requiredFeatures") requiredFeatures
  |> add (string "restart") restart
  |> add (string "result") result
  |> add (string "rotate") rotate
  |> add (string "rx") rx
  |> add (string "ry") ry
  |> add (string "scale") scale
  |> add (string "seed") seed
  |> add (string "shape-rendering") shapeRendering
  |> add (string "slope") slope
  |> add (string "spacing") spacing
  |> add (string "specularConstant") specularConstant
  |> add (string "specularExponent") specularExponent
  |> add (string "speed") speed
  |> add (string "spreadMethod") spreadMethod
  |> add (string "startOffset") startOffset
  |> add (string "stdDeviation") stdDeviation
  |> add (string "stemh") stemh
  |> add (string "stemv") stemv
  |> add (string "stitchTiles") stitchTiles
  |> add (string "stopColor") stopColor
  |> add (string "stopOpacity") stopOpacity
  |> add (string "strikethrough-position") strikethroughPosition
  |> add (string "strikethrough-thickness") strikethroughThickness
  |> add (string "stroke") stroke
  |> add (string "stroke-dasharray") strokeDasharray
  |> add (string "stroke-dashoffset") strokeDashoffset
  |> add (string "stroke-linecap") strokeLinecap
  |> add (string "stroke-linejoin") strokeLinejoin
  |> add (string "stroke-miterlimit") strokeMiterlimit
  |> add (string "stroke-opacity") strokeOpacity
  |> add (string "stroke-width") strokeWidth
  |> add (string "surfaceScale") surfaceScale
  |> add (string "systemLanguage") systemLanguage
  |> add (string "tableValues") tableValues
  |> add (string "targetX") targetX
  |> add (string "targetY") targetY
  |> add (string "text-anchor") textAnchor
  |> add (string "text-decoration") textDecoration
  |> add (string "textLength") textLength
  |> add (string "text-rendering") textRendering
  |> add (string "to") to_
  |> add (string "transform") transform
  |> add (string "u1") u1
  |> add (string "u2") u2
  |> add (string "underline-position") underlinePosition
  |> add (string "underline-thickness") underlineThickness
  |> add (string "unicode") unicode
  |> add (string "unicode-bidi") unicodeBidi
  |> add (string "unicode-range") unicodeRange
  |> add (string "units-per-em") unitsPerEm
  |> add (string "v-alphabetic") vAlphabetic
  |> add (string "v-hanging") vHanging
  |> add (string "v-ideographic") vIdeographic
  |> add (string "vMathematical") vMathematical (* Does it exists? *)
  |> add (string "values") values
  |> add (string "vector-effect") vectorEffect
  |> add (string "version") version
  |> add (string "vert-adv-x") vertAdvX
  |> add (string "vert-adv-y") vertAdvY
  |> add (string "vert-origin-x") vertOriginX
  |> add (string "vert-origin-y") vertOriginY
  |> add (string "viewBox") viewBox
  |> add (string "viewTarget") viewTarget
  |> add (string "visibility") visibility
  |> add (string "widths") widths
  |> add (string "word-spacing") wordSpacing
  |> add (string "writing-mode") writingMode
  |> add (string "x") x
  |> add (string "x1") x1
  |> add (string "x2") x2
  |> add (string "xChannelSelector") xChannelSelector
  |> add (string "x-height") xHeight
  |> add (string "xlink:arcrole") xlinkActuate
  |> add (string "xlinkArcrole") xlinkArcrole
  |> add (string "xlink:href") xlinkHref
  |> add (string "xlink:role") xlinkRole
  |> add (string "xlink:show") xlinkShow
  |> add (string "xlink:title") xlinkTitle
  |> add (string "xlink:type") xlinkType
  |> add (string "xmlns") xmlns
  |> add (string "xmlnsXlink") xmlnsXlink
  |> add (string "xml:base") xmlBase
  |> add (string "xml:lang") xmlLang
  |> add (string "xml:space") xmlSpace
  |> add (string "y") y
  |> add (string "y1") y1
  |> add (string "y2") y2
  |> add (string "yChannelSelector") yChannelSelector
  |> add (string "z") z
  |> add (string "zoomAndPan") zoomAndPan
  |> add (string "about") about
  |> add (string "datatype") datatype
  |> add (string "inlist") inlist
  |> add (string "prefix") prefix
  |> add (string "property") property
  |> add (string "resource") resource
  |> add (string "typeof") typeof
  |> add (string "vocab") vocab
  |> add (React.JSX.dangerouslyInnerHtml) dangerouslySetInnerHTML
  |> add (bool "suppressContentEditableWarning") suppressContentEditableWarning
  |> add (bool "suppressHydrationWarning") suppressHydrationWarning

module Ref = React.Ref

type domRef = Ref.t
