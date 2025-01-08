module Style = ReactDOMStyle
module Ref = React.Ref

type domRef = Ref.t

let is_react_custom_attribute attr =
  match attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning" | "suppressHydrationWarning" -> true
  | _ -> false

(* TODO: Maybe this should not be under ReactDOM? *)
let attribute_to_html attr =
  match attr with
  (* ignores "ref" prop *)
  | React.JSX.Ref _ -> Html.omitted ()
  | Bool (name, _, _) when is_react_custom_attribute name -> Html.omitted ()
  (* false attributes don't get rendered *)
  | Bool (_name, _, false) -> Html.omitted ()
  (* true attributes render solely the attribute name *)
  | Bool (name, _, true) -> Html.present name
  | Style styles -> Html.attribute "style" styles
  | String (name, _, _value) when is_react_custom_attribute name -> Html.omitted ()
  | String (name, _, value) -> Html.attribute name value
  (* Events don't get rendered on SSR *)
  | Event _ -> Html.omitted ()
  (* Since we extracted the attribute as children (Element.InnerHtml) in createElement,
     we are sure there's nothing to render here *)
  | DangerouslyInnerHtml _ -> Html.omitted ()

let attributes_to_html attrs = attrs |> List.map attribute_to_html

type mode = String | Markup

let render_to_string ~mode element =
  (* is_root starts at true (when renderToString) and only goes to false
     when renders an lower-case element or closed element *)
  let is_mode_to_string = mode = String in
  let is_root = ref is_mode_to_string in

  let rec render_element element =
    match (element : React.element) with
    | Empty -> Html.null
    | Client_component _ -> Html.null
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List list -> list |> Array.to_list |> List.map render_element |> Html.list
    | Upper_case_component component -> render_element (component ())
    | Async_component _component ->
        raise
          (Invalid_argument
             "Async components can't be rendered to static markup, since rendering is synchronous. Please use \
              `renderToStream` instead.")
    | Lower_case_element { key = _; tag; attributes; children } ->
        is_root.contents <- false;
        render_lower_case tag attributes children
    | Text text -> Html.string text
    | InnerHtml text -> Html.raw text
    | Suspense { key = _; children; fallback } -> (
        match render_element children with
        | output -> Html.list [ Html.raw "<!--$-->"; output; Html.raw "<!--/$-->" ]
        | exception _e -> Html.list [ Html.raw "<!--$!-->"; render_element fallback; Html.raw "<!--/$-->" ])
  and render_lower_case tag attributes children =
    let dangerouslySetInnerHTML =
      List.find_opt (function React.JSX.DangerouslyInnerHtml _ -> true | _ -> false) attributes
    in
    let children =
      (* If there's a dangerouslySetInnerHTML prop, we render it as a children *)
      match (dangerouslySetInnerHTML, children) with
      | None, children -> children
      | Some (React.JSX.DangerouslyInnerHtml innerHtml), [] ->
          (* This adds as children the innerHTML, and we treat it differently
             from Element.Text to avoid encoding to HTML their content *)
          (* TODO: Remove InnerHtml and use Html.raw directly *)
          [ InnerHtml innerHtml ]
      | Some _, _children ->
          raise (Invalid_argument "can't have both `children` and `dangerouslySetInnerHTML` prop at the same time")
    in
    match Html.is_self_closing_tag tag with
    (* By the ppx, we know that a self closing tag can't have children *)
    | true -> Html.node tag (attributes_to_html attributes) []
    | false -> Html.node tag (attributes_to_html attributes) (List.map render_element children)
  in
  render_element element

(* let dangerouslySetInnerHTML =
     List.find_opt
       (function JSX.DangerouslyInnerHtml _ -> true | _ -> false)
       attributes
   in
   let children =
     match (dangerouslySetInnerHTML, children) with
     | None, children -> children
     | Some (JSX.DangerouslyInnerHtml innerHtml), [] ->
         (* This adds as children the innerHTML, and we treat it differently
            from Element.Text to avoid encoding to HTML their content *)
         [ InnerHtml innerHtml ]
     | Some _, _children ->
         raise
           (Invalid_children
              "can't have both `children` and `dangerouslySetInnerHTML` prop at \
               the same time")
   in *)

let renderToString element =
  (* TODO: try catch to avoid React.use usages *)
  let html = render_to_string ~mode:String element in
  Html.to_string html

let renderToStaticMarkup element =
  (* TODO: try catch to avoid React.use usages *)
  let html = render_to_string ~mode:Markup element in
  Html.to_string ~add_separator_between_text_nodes:false html

type context_state = {
  push : Html.element -> unit;
  close : unit -> unit;
  mutable closed : bool;
  mutable boundary_id : int;
  mutable suspense_id : int;
  mutable waiting : int;
}

(* https://github.com/facebook/react/blob/493f72b0a7111b601c16b8ad8bc2649d82c184a0/packages/react-dom-bindings/src/server/fizz-instruction-set/ReactDOMFizzInstructionSetShared.js#L46 *)
let complete_boundary_script =
  {|function $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if("/$"===d)if(0===e)break;else e--;else"$"!==d&&"$?"!==d&&"$!"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data="$";a._reactRetry&&a._reactRetry()}}|}

let replacement b s = Printf.sprintf "$RC('B:%i','S:%i')" b s

let inline_complete_boundary_script boundary_id suspense_id =
  (* TODO: it's always correct to asume that the first suspense_id is 0? Maybe we can have 2 suspense parallely and it's not the case anymore? *)
  if boundary_id = 0 && suspense_id = 0 then
    Html.raw (Printf.sprintf "<script>%s%s</script>" complete_boundary_script (replacement boundary_id suspense_id))
  else Html.raw (Printf.sprintf "<script>%s</script>" (replacement boundary_id suspense_id))

(* let render_inline_rc_replacement replacements =
   let rc_payload =
     replacements
     |> List.map (fun (b, s) ->
            Html.raw (Printf.sprintf "$RC('B:%i','S:%i')" b s))
     |> Html.list ~separator:";"
   in
   Html.node "script" [] [ rc_payload ] *)

let render_suspense_resolved_element ~id element =
  Html.node "div" [ Html.present "hidden"; Html.attribute "id" (Printf.sprintf "S:%i" id) ] [ element ]

let render_suspense_fallback ~boundary_id element =
  Html.list
    [
      Html.raw "<!--$?-->";
      Html.node "template" [ Html.attribute "id" (Printf.sprintf "B:%i" boundary_id) ] [];
      element;
      Html.raw "<!--/$-->";
    ]

let render_suspense_fallback_error ~exn element =
  let backtrace = Printexc.get_backtrace () in
  let data_msg = Printf.sprintf "%s\n%s" (Printexc.to_string exn) backtrace in
  Html.list
    [
      Html.raw "<!--$!-->";
      Html.node "template" [ Html.attribute "data-msg" data_msg ] [];
      element;
      Html.raw "<!--/$-->";
    ]

let render_to_stream ~context_state element =
  (* let exception Suspend_async of React.elemet Lwt.t in *)
  let rec render_element element =
    match (element : React.element) with
    | Empty -> Lwt.return Html.null
    (* TODO: Check if this breaks in the client. Maybe should throw an error/exn? *)
    | Client_component _ -> Lwt.return Html.null
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List arr ->
        let%lwt children_elements = arr |> Array.to_list |> Lwt_list.map_p render_element in
        Lwt.return (Html.list children_elements)
    | Upper_case_component component ->
        let rec wait_for_suspense_to_resolve () =
          match component () with
          | exception React.Suspend (Any_promise promise) ->
              let%lwt _ = promise in
              wait_for_suspense_to_resolve ()
          | exception exn -> raise exn
          | output -> render_element output
        in
        wait_for_suspense_to_resolve ()
    | Lower_case_element { tag; attributes; _ } when Html.is_self_closing_tag tag ->
        Lwt.return (Html.node tag (attributes_to_html attributes) [])
    | Lower_case_element { key = _; tag; attributes; children } ->
        let%lwt inner = Lwt_list.map_p render_element children in
        let html_attributes = attributes_to_html attributes in
        Lwt.return (Html.node tag html_attributes inner)
    | Text text -> Lwt.return (Html.string text)
    | InnerHtml text -> Lwt.return (Html.raw text)
    | Async_component component ->
        let%lwt async_element = component () in
        render_element async_element
    | Suspense { key = _; children; fallback } -> (
        (* assume fallback doesn't contain promises, neither errors *)
        let%lwt fallback_element = render_element fallback in
        try%lwt
          let current_boundary_id = context_state.boundary_id in
          let current_suspense_id = context_state.suspense_id in
          context_state.boundary_id <- context_state.boundary_id + 1;
          context_state.suspense_id <- context_state.suspense_id + 1;
          let children_promise = render_element children in

          match Lwt.state children_promise with
          (* In case of a resolved promise, we don't render fallback and render children straight away *)
          | Lwt.Return element -> Lwt.return element
          | Lwt.Fail exn ->
              context_state.waiting <- context_state.waiting - 1;
              raise exn
          | Lwt.Sleep ->
              context_state.waiting <- context_state.waiting + 1;

              (* Start the async work but don't wait for it *)
              Lwt.async (fun () ->
                  let%lwt resolved = children_promise in
                  context_state.waiting <- context_state.waiting - 1;

                  (* Only push updates if the stream is still open *)
                  if not context_state.closed then (
                    context_state.push (render_suspense_resolved_element ~id:current_suspense_id resolved);
                    context_state.push (inline_complete_boundary_script current_boundary_id current_suspense_id))
                  else ();

                  if context_state.waiting = 0 then (
                    context_state.closed <- true;
                    context_state.close ());
                  Lwt.return ());

              Lwt.return (render_suspense_fallback ~boundary_id:current_boundary_id fallback_element)
        with exn -> Lwt.return (render_suspense_fallback_error ~exn fallback_element))
  in

  render_element element

let renderToStream ?pipe element =
  let stream, push_to_stream, close = Push_stream.make () in
  let push html = push_to_stream (Html.to_string html) in
  let context_state = { push; close; closed = false; waiting = 0; boundary_id = 0; suspense_id = 0 } in
  let%lwt html = render_to_stream ~context_state element in
  push html;
  let%lwt () = match pipe with None -> Lwt.return () | Some pipe -> Lwt_stream.iter_s pipe stream in
  if context_state.waiting = 0 then close ();
  let abort () =
    (* TODO: Needs to flush the remaining loading fallbacks as HTML, and React.js will try to render the rest on the client. *)
    Lwt_stream.closed stream |> Lwt.ignore_result
  in
  Lwt.return (stream, abort)

let querySelector _str = Runtime.fail_impossible_action_in_ssr "ReactDOM.querySelector"
let render _element _node = Runtime.fail_impossible_action_in_ssr "ReactDOM.render"
let hydrate _element _node = Runtime.fail_impossible_action_in_ssr "ReactDOM.hydrate"

(* TODO: Should this fail_impossible_action_in_ssr? *)
let createPortal _reactElement _domElement = _reactElement

let createDOMElementVariadic (tag : string) ~props (childrens : React.element array) =
  React.createElement tag props (Array.to_list childrens)

let add kind value map = match value with Some i -> map |> List.cons (kind i) | None -> map

type dangerouslySetInnerHTML = < __html : string >

(* `Booleanish_string` are JSX attributes represented as boolean values but rendered as strings on HTML https://github.com/facebook/react/blob/a17467e7e2cd8947c595d1834889b5d184459f12/packages/react-dom-bindings/src/server/ReactFizzConfigDOM.js#L1165-L1176 *)
let booleanish_string name jsxName v = React.JSX.string name jsxName (string_of_bool v)

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
  |> add (React.JSX.string "key" "key") key
  |> add React.JSX.ref ref
  |> add (React.JSX.string "aria-details" "aria-details") ariaDetails
  |> add (booleanish_string "aria-disabled" "aria-disabled") ariaDisabled
  |> add (booleanish_string "aria-hidden" "aria-hidden") ariaHidden
  |> add (React.JSX.string "aria-keyshortcuts" "aria-keyshortcuts") ariaKeyshortcuts
  |> add (React.JSX.string "aria-label" "aria-label") ariaLabel
  |> add (React.JSX.string "aria-roledescription" "aria-roledescription") ariaRoledescription
  |> add (booleanish_string "aria-expanded" "aria-expanded") ariaExpanded
  |> add (React.JSX.int "aria-level" "aria-level") ariaLevel
  |> add (booleanish_string "aria-modal" "aria-modal") ariaModal
  |> add (booleanish_string "aria-multiline" "aria-multiline") ariaMultiline
  |> add (booleanish_string "aria-multiselectable" "aria-multiselectable") ariaMultiselectable
  |> add (React.JSX.string "aria-placeholder" "aria-placeholder") ariaPlaceholder
  |> add (booleanish_string "aria-readonly" "aria-readonly") ariaReadonly
  |> add (booleanish_string "aria-required" "aria-required") ariaRequired
  |> add (booleanish_string "aria-selected" "aria-selected") ariaSelected
  |> add (React.JSX.string "aria-sort" "aria-sort") ariaSort
  |> add (React.JSX.float "aria-valuemax" "aria-valuemax") ariaValuemax
  |> add (React.JSX.float "aria-valuemin" "aria-valuemin") ariaValuemin
  |> add (React.JSX.float "aria-valuenow" "aria-valuenow") ariaValuenow
  |> add (React.JSX.string "aria-valuetext" "aria-valuetext") ariaValuetext
  |> add (booleanish_string "aria-atomic" "aria-atomic") ariaAtomic
  |> add (booleanish_string "aria-busy" "aria-busy") ariaBusy
  |> add (React.JSX.string "aria-relevant" "aria-relevant") ariaRelevant
  |> add (React.JSX.bool "aria-grabbed" "aria-grabbed") ariaGrabbed
  |> add (React.JSX.string "aria-activedescendant" "aria-activedescendant") ariaActivedescendant
  |> add (React.JSX.int "aria-colcount" "aria-colcount") ariaColcount
  |> add (React.JSX.int "aria-colindex" "aria-colindex") ariaColindex
  |> add (React.JSX.int "aria-colspan" "aria-colspan") ariaColspan
  |> add (React.JSX.string "aria-controls" "aria-controls") ariaControls
  |> add (React.JSX.string "aria-describedby" "aria-describedby") ariaDescribedby
  |> add (React.JSX.string "aria-errormessage" "aria-errormessage") ariaErrormessage
  |> add (React.JSX.string "aria-flowto" "aria-flowto") ariaFlowto
  |> add (React.JSX.string "aria-labelledby" "aria-labelledby") ariaLabelledby
  |> add (React.JSX.string "aria-owns" "aria-owns") ariaOwns
  |> add (React.JSX.int "aria-posinset" "aria-posinset") ariaPosinset
  |> add (React.JSX.int "aria-rowcount" "aria-rowcount") ariaRowcount
  |> add (React.JSX.int "aria-rowindex" "aria-rowindex") ariaRowindex
  |> add (React.JSX.int "aria-rowspan" "aria-rowspan") ariaRowspan
  |> add (React.JSX.int "aria-setsize" "aria-setsize") ariaSetsize
  |> add (React.JSX.bool "checked" "defaultChecked") defaultChecked
  |> add (React.JSX.string "value" "defaultValue") defaultValue
  |> add (React.JSX.string "accesskey" "accessKey") accessKey
  |> add (React.JSX.string "class" "className") className
  |> add (booleanish_string "contenteditable" "contentEditable") contentEditable
  |> add (React.JSX.string "contextmenu" "contextMenu") contextMenu
  |> add (React.JSX.string "dir" "dir") dir
  |> add (booleanish_string "draggable" "draggable") draggable
  |> add (React.JSX.bool "hidden" "hidden") hidden
  |> add (React.JSX.string "id" "id") id
  |> add (React.JSX.string "lang" "lang") lang
  |> add (React.JSX.string "role" "role") role
  |> add (fun v -> React.JSX.style (ReactDOMStyle.to_string v)) style
  |> add (booleanish_string "spellcheck" "spellCheck") spellCheck
  |> add (React.JSX.int "tabindex" "tabIndex") tabIndex
  |> add (React.JSX.string "title" "title") title
  |> add (React.JSX.string "itemid" "itemID") itemID
  |> add (React.JSX.string "itemorop" "itemProp") itemProp
  |> add (React.JSX.string "itemref" "itemRef") itemRef
  |> add (React.JSX.bool "itemccope" "itemScope") itemScope
  |> add (React.JSX.string "itemtype" "itemType") itemType
  |> add (React.JSX.string "accept" "accept") accept
  |> add (React.JSX.string "accept-charset" "acceptCharset") acceptCharset
  |> add (React.JSX.string "action" "action") action
  |> add (React.JSX.bool "allowfullscreen" "allowFullScreen") allowFullScreen
  |> add (React.JSX.string "alt" "alt") alt
  |> add (React.JSX.bool "async" "async") async
  |> add (React.JSX.string "autocomplete" "autoComplete") autoComplete
  |> add (React.JSX.string "autocapitalize" "autoCapitalize") autoCapitalize
  |> add (React.JSX.bool "autofocus" "autoFocus") autoFocus
  |> add (React.JSX.bool "autoplay" "autoPlay") autoPlay
  |> add (React.JSX.string "challenge" "challenge") challenge
  |> add (React.JSX.string "charSet" "charSet") charSet
  |> add (React.JSX.bool "checked" "checked") checked
  |> add (React.JSX.string "cite" "cite") cite
  |> add (React.JSX.string "crossorigin" "crossOrigin") crossOrigin
  |> add (React.JSX.int "cols" "cols") cols
  |> add (React.JSX.int "colspan" "colSpan") colSpan
  |> add (React.JSX.string "content" "content") content
  |> add (React.JSX.bool "controls" "controls") controls
  |> add (React.JSX.string "coords" "coords") coords
  |> add (React.JSX.string "data" "data") data
  |> add (React.JSX.string "datetime" "dateTime") dateTime
  |> add (React.JSX.bool "default" "default") default
  |> add (React.JSX.bool "defer" "defer") defer
  |> add (React.JSX.bool "disabled" "disabled") disabled
  |> add (React.JSX.string "download" "download") download
  |> add (React.JSX.string "enctype" "encType") encType
  |> add (React.JSX.string "form" "form") form
  |> add (React.JSX.string "formction" "formAction") formAction
  |> add (React.JSX.string "formtarget" "formTarget") formTarget
  |> add (React.JSX.string "formmethod" "formMethod") formMethod
  |> add (React.JSX.string "headers" "headers") headers
  |> add (React.JSX.string "height" "height") height
  |> add (React.JSX.int "high" "high") high
  |> add (React.JSX.string "href" "href") href
  |> add (React.JSX.string "hreflang" "hrefLang") hrefLang
  |> add (React.JSX.string "for" "htmlFor") htmlFor
  |> add (React.JSX.string "http-equiv" "httpEquiv") httpEquiv
  |> add (React.JSX.string "icon" "icon") icon
  |> add (React.JSX.string "inputmode" "inputMode") inputMode
  |> add (React.JSX.string "integrity" "integrity") integrity
  |> add (React.JSX.string "keytype" "keyType") keyType
  |> add (React.JSX.string "kind" "kind") kind
  |> add (React.JSX.string "label" "label") label
  |> add (React.JSX.string "list" "list") list
  |> add (React.JSX.bool "loop" "loop") loop
  |> add (React.JSX.int "low" "low") low
  |> add (React.JSX.string "manifest" "manifest") manifest
  |> add (React.JSX.string "max" "max") max
  |> add (React.JSX.int "maxlength" "maxLength") maxLength
  |> add (React.JSX.string "media" "media") media
  |> add (React.JSX.string "mediagroup" "mediaGroup") mediaGroup
  |> add (React.JSX.string "method" "method") method_
  |> add (React.JSX.string "min" "min") min
  |> add (React.JSX.int "minlength" "minLength") minLength
  |> add (React.JSX.bool "multiple" "multiple") multiple
  |> add (React.JSX.bool "muted" "muted") muted
  |> add (React.JSX.string "name" "name") name
  |> add (React.JSX.string "nonce" "nonce") nonce
  |> add (React.JSX.bool "noValidate" "noValidate") noValidate
  |> add (React.JSX.bool "open" "open") open_
  |> add (React.JSX.int "optimum" "optimum") optimum
  |> add (React.JSX.string "pattern" "pattern") pattern
  |> add (React.JSX.string "placeholder" "placeholder") placeholder
  |> add (React.JSX.bool "playsInline" "playsInline") playsInline
  |> add (React.JSX.string "poster" "poster") poster
  |> add (React.JSX.string "preload" "preload") preload
  |> add (React.JSX.string "radioGroup" "radioGroup") radioGroup (* Unsure if it exists? *)
  |> add (React.JSX.bool "readonly" "readOnly") readOnly
  |> add (React.JSX.string "rel" "rel") rel
  |> add (React.JSX.bool "required" "required") required
  |> add (React.JSX.bool "reversed" "reversed") reversed
  |> add (React.JSX.int "rows" "rows") rows
  |> add (React.JSX.int "rowspan" "rowSpan") rowSpan
  |> add (React.JSX.string "sandbox" "sandbox") sandbox
  |> add (React.JSX.string "scope" "scope") scope
  |> add (React.JSX.bool "scoped" "scoped") scoped
  |> add (React.JSX.string "scrolling" "scrolling") scrolling
  |> add (React.JSX.bool "selected" "selected") selected
  |> add (React.JSX.string "shape" "shape") shape
  |> add (React.JSX.int "size" "size") size
  |> add (React.JSX.string "sizes" "sizes") sizes
  |> add (React.JSX.int "span" "span") span
  |> add (React.JSX.string "src" "src") src
  |> add (React.JSX.string "srcdoc" "srcDoc") srcDoc
  |> add (React.JSX.string "srclang" "srcLang") srcLang
  |> add (React.JSX.string "srcset" "srcSet") srcSet
  |> add (React.JSX.int "start" "start") start
  |> add (React.JSX.float "step" "step") step
  |> add (React.JSX.string "summary" "summary") summary
  |> add (React.JSX.string "target" "target") target
  |> add (React.JSX.string "type" "type") type_
  |> add (React.JSX.string "useMap" "useMap") useMap
  |> add (React.JSX.string "value" "value") value
  |> add (React.JSX.string "width" "width") width
  |> add (React.JSX.string "wrap" "wrap") wrap
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
  |> add (React.JSX.string "accent-height" "accentHeight") accentHeight
  |> add (React.JSX.string "accumulate" "accumulate") accumulate
  |> add (React.JSX.string "additive" "additive") additive
  |> add (React.JSX.string "alignment-baseline" "alignmentBaseline") alignmentBaseline
  |> add (React.JSX.string "allowReorder" "allowReorder") allowReorder (* Does it exist? *)
  |> add (React.JSX.string "alphabetic" "alphabetic") alphabetic
  |> add (React.JSX.string "amplitude" "amplitude") amplitude
  |> add (React.JSX.string "arabic-form" "arabicForm") arabicForm
  |> add (React.JSX.string "ascent" "ascent") ascent
  |> add (React.JSX.string "attributeName" "attributeName") attributeName
  |> add (React.JSX.string "attributeType" "attributeType") attributeType
  |> add (React.JSX.string "autoReverse" "autoReverse") autoReverse (* Does it exist? *)
  |> add (React.JSX.string "azimuth" "azimuth") azimuth
  |> add (React.JSX.string "baseFrequency" "baseFrequency") baseFrequency
  |> add (React.JSX.string "baseProfile" "baseProfile") baseProfile
  |> add (React.JSX.string "baselineShift" "baselineShift") baselineShift
  |> add (React.JSX.string "bbox" "bbox") bbox
  |> add (React.JSX.string "begin" "begin") begin_
  |> add (React.JSX.string "bias" "bias") bias
  |> add (React.JSX.string "by" "by") by
  |> add (React.JSX.string "calcMode" "calcMode") calcMode
  |> add (React.JSX.string "capHeight" "capHeight") capHeight
  |> add (React.JSX.string "clip" "clip") clip
  |> add (React.JSX.string "clipPath" "clipPath") clipPath
  |> add (React.JSX.string "clipPathUnits" "clipPathUnits") clipPathUnits
  |> add (React.JSX.string "clipRule" "clipRule") clipRule
  |> add (React.JSX.string "colorInterpolation" "colorInterpolation") colorInterpolation
  |> add (React.JSX.string "colorInterpolationFilters" "colorInterpolationFilters") colorInterpolationFilters
  |> add (React.JSX.string "colorProfile" "colorProfile") colorProfile
  |> add (React.JSX.string "colorRendering" "colorRendering") colorRendering
  |> add (React.JSX.string "contentScriptType" "contentScriptType") contentScriptType
  |> add (React.JSX.string "contentStyleType" "contentStyleType") contentStyleType
  |> add (React.JSX.string "cursor" "cursor") cursor
  |> add (React.JSX.string "cx" "cx") cx
  |> add (React.JSX.string "cy" "cy") cy
  |> add (React.JSX.string "d" "d") d
  |> add (React.JSX.string "decelerate" "decelerate") decelerate
  |> add (React.JSX.string "descent" "descent") descent
  |> add (React.JSX.string "diffuseConstant" "diffuseConstant") diffuseConstant
  |> add (React.JSX.string "direction" "direction") direction
  |> add (React.JSX.string "display" "display") display
  |> add (React.JSX.string "divisor" "divisor") divisor
  |> add (React.JSX.string "dominantBaseline" "dominantBaseline") dominantBaseline
  |> add (React.JSX.string "dur" "dur") dur
  |> add (React.JSX.string "dx" "dx") dx
  |> add (React.JSX.string "dy" "dy") dy
  |> add (React.JSX.string "edgeMode" "edgeMode") edgeMode
  |> add (React.JSX.string "elevation" "elevation") elevation
  |> add (React.JSX.string "enableBackground" "enableBackground") enableBackground
  |> add (React.JSX.string "end" "end") end_
  |> add (React.JSX.string "exponent" "exponent") exponent
  |> add (React.JSX.string "externalResourcesRequired" "externalResourcesRequired") externalResourcesRequired
  |> add (React.JSX.string "fill" "fill") fill
  |> add (React.JSX.string "fillOpacity" "fillOpacity") fillOpacity
  |> add (React.JSX.string "fillRule" "fillRule") fillRule
  |> add (React.JSX.string "filter" "filter") filter
  |> add (React.JSX.string "filterRes" "filterRes") filterRes
  |> add (React.JSX.string "filterUnits" "filterUnits") filterUnits
  |> add (React.JSX.string "flood-color" "floodColor") floodColor
  |> add (React.JSX.string "flood-opacity" "floodOpacity") floodOpacity
  |> add (React.JSX.string "focusable" "focusable") focusable
  |> add (React.JSX.string "font-family" "fontFamily") fontFamily
  |> add (React.JSX.string "font-size" "fontSize") fontSize
  |> add (React.JSX.string "font-size-adjust" "fontSizeAdjust") fontSizeAdjust
  |> add (React.JSX.string "font-stretch" "fontStretch") fontStretch
  |> add (React.JSX.string "font-style" "fontStyle") fontStyle
  |> add (React.JSX.string "font-variant" "fontVariant") fontVariant
  |> add (React.JSX.string "font-weight" "fontWeight") fontWeight
  |> add (React.JSX.string "fomat" "fomat") fomat
  |> add (React.JSX.string "from" "from") from
  |> add (React.JSX.string "fx" "fx") fx
  |> add (React.JSX.string "fy" "fy") fy
  |> add (React.JSX.string "g1" "g1") g1
  |> add (React.JSX.string "g2" "g2") g2
  |> add (React.JSX.string "glyph-name" "glyphName") glyphName
  |> add (React.JSX.string "glyph-orientation-horizontal" "glyphOrientationHorizontal") glyphOrientationHorizontal
  |> add (React.JSX.string "glyph-orientation-vertical" "glyphOrientationVertical") glyphOrientationVertical
  |> add (React.JSX.string "glyphRef" "glyphRef") glyphRef
  |> add (React.JSX.string "gradientTransform" "gradientTransform") gradientTransform
  |> add (React.JSX.string "gradientUnits" "gradientUnits") gradientUnits
  |> add (React.JSX.string "hanging" "hanging") hanging
  |> add (React.JSX.string "horiz-adv-x" "horizAdvX") horizAdvX
  |> add (React.JSX.string "horiz-origin-x" "horizOriginX") horizOriginX
  (* |> add (React.JSX.string "horiz-origin-y" "horizOriginY") horizOriginY *) (* Should be added *)
  |> add (React.JSX.string "ideographic" "ideographic") ideographic
  |> add (React.JSX.string "image-rendering" "imageRendering") imageRendering
  |> add (React.JSX.string "in" "in") in_
  |> add (React.JSX.string "in2" "in2") in2
  |> add (React.JSX.string "intercept" "intercept") intercept
  |> add (React.JSX.string "k" "k") k
  |> add (React.JSX.string "k1" "k1") k1
  |> add (React.JSX.string "k2" "k2") k2
  |> add (React.JSX.string "k3" "k3") k3
  |> add (React.JSX.string "k4" "k4") k4
  |> add (React.JSX.string "kernelMatrix" "kernelMatrix") kernelMatrix
  |> add (React.JSX.string "kernelUnitLength" "kernelUnitLength") kernelUnitLength
  |> add (React.JSX.string "kerning" "kerning") kerning
  |> add (React.JSX.string "keyPoints" "keyPoints") keyPoints
  |> add (React.JSX.string "keySplines" "keySplines") keySplines
  |> add (React.JSX.string "keyTimes" "keyTimes") keyTimes
  |> add (React.JSX.string "lengthAdjust" "lengthAdjust") lengthAdjust
  |> add (React.JSX.string "letterSpacing" "letterSpacing") letterSpacing
  |> add (React.JSX.string "lightingColor" "lightingColor") lightingColor
  |> add (React.JSX.string "limitingConeAngle" "limitingConeAngle") limitingConeAngle
  |> add (React.JSX.string "local" "local") local
  |> add (React.JSX.string "marker-end" "markerEnd") markerEnd
  |> add (React.JSX.string "marker-height" "markerHeight") markerHeight
  |> add (React.JSX.string "marker-mid" "markerMid") markerMid
  |> add (React.JSX.string "marker-start" "markerStart") markerStart
  |> add (React.JSX.string "marker-units" "markerUnits") markerUnits
  |> add (React.JSX.string "markerWidth" "markerWidth") markerWidth
  |> add (React.JSX.string "mask" "mask") mask
  |> add (React.JSX.string "maskContentUnits" "maskContentUnits") maskContentUnits
  |> add (React.JSX.string "maskUnits" "maskUnits") maskUnits
  |> add (React.JSX.string "mathematical" "mathematical") mathematical
  |> add (React.JSX.string "mode" "mode") mode
  |> add (React.JSX.string "numOctaves" "numOctaves") numOctaves
  |> add (React.JSX.string "offset" "offset") offset
  |> add (React.JSX.string "opacity" "opacity") opacity
  |> add (React.JSX.string "operator" "operator") operator
  |> add (React.JSX.string "order" "order") order
  |> add (React.JSX.string "orient" "orient") orient
  |> add (React.JSX.string "orientation" "orientation") orientation
  |> add (React.JSX.string "origin" "origin") origin
  |> add (React.JSX.string "overflow" "overflow") overflow
  |> add (React.JSX.string "overflowX" "overflowX") overflowX
  |> add (React.JSX.string "overflowY" "overflowY") overflowY
  |> add (React.JSX.string "overline-position" "overlinePosition") overlinePosition
  |> add (React.JSX.string "overline-thickness" "overlineThickness") overlineThickness
  |> add (React.JSX.string "paint-order" "paintOrder") paintOrder
  |> add (React.JSX.string "panose1" "panose1") panose1
  |> add (React.JSX.string "pathLength" "pathLength") pathLength
  |> add (React.JSX.string "patternContentUnits" "patternContentUnits") patternContentUnits
  |> add (React.JSX.string "patternTransform" "patternTransform") patternTransform
  |> add (React.JSX.string "patternUnits" "patternUnits") patternUnits
  |> add (React.JSX.string "pointerEvents" "pointerEvents") pointerEvents
  |> add (React.JSX.string "points" "points") points
  |> add (React.JSX.string "pointsAtX" "pointsAtX") pointsAtX
  |> add (React.JSX.string "pointsAtY" "pointsAtY") pointsAtY
  |> add (React.JSX.string "pointsAtZ" "pointsAtZ") pointsAtZ
  |> add (React.JSX.string "preserveAlpha" "preserveAlpha") preserveAlpha
  |> add (React.JSX.string "preserveAspectRatio" "preserveAspectRatio") preserveAspectRatio
  |> add (React.JSX.string "primitiveUnits" "primitiveUnits") primitiveUnits
  |> add (React.JSX.string "r" "r") r
  |> add (React.JSX.string "radius" "radius") radius
  |> add (React.JSX.string "refX" "refX") refX
  |> add (React.JSX.string "refY" "refY") refY
  |> add (React.JSX.string "renderingIntent" "renderingIntent") renderingIntent (* Does it exist? *)
  |> add (React.JSX.string "repeatCount" "repeatCount") repeatCount
  |> add (React.JSX.string "repeatDur" "repeatDur") repeatDur
  |> add (React.JSX.string "requiredExtensions" "requiredExtensions") requiredExtensions (* Does it exists? *)
  |> add (React.JSX.string "requiredFeatures" "requiredFeatures") requiredFeatures
  |> add (React.JSX.string "restart" "restart") restart
  |> add (React.JSX.string "result" "result") result
  |> add (React.JSX.string "rotate" "rotate") rotate
  |> add (React.JSX.string "rx" "rx") rx
  |> add (React.JSX.string "ry" "ry") ry
  |> add (React.JSX.string "scale" "scale") scale
  |> add (React.JSX.string "seed" "seed") seed
  |> add (React.JSX.string "shape-rendering" "shapeRendering") shapeRendering
  |> add (React.JSX.string "slope" "slope") slope
  |> add (React.JSX.string "spacing" "spacing") spacing
  |> add (React.JSX.string "specularConstant" "specularConstant") specularConstant
  |> add (React.JSX.string "specularExponent" "specularExponent") specularExponent
  |> add (React.JSX.string "speed" "speed") speed
  |> add (React.JSX.string "spreadMethod" "spreadMethod") spreadMethod
  |> add (React.JSX.string "startOffset" "startOffset") startOffset
  |> add (React.JSX.string "stdDeviation" "stdDeviation") stdDeviation
  |> add (React.JSX.string "stemh" "stemh") stemh
  |> add (React.JSX.string "stemv" "stemv") stemv
  |> add (React.JSX.string "stitchTiles" "stitchTiles") stitchTiles
  |> add (React.JSX.string "stopColor" "stopColor") stopColor
  |> add (React.JSX.string "stopOpacity" "stopOpacity") stopOpacity
  |> add (React.JSX.string "strikethrough-position" "strikethroughPosition") strikethroughPosition
  |> add (React.JSX.string "strikethrough-thickness" "strikethroughThickness") strikethroughThickness
  |> add (React.JSX.string "stroke" "stroke") stroke
  |> add (React.JSX.string "stroke-dasharray" "strokeDasharray") strokeDasharray
  |> add (React.JSX.string "stroke-dashoffset" "strokeDashoffset") strokeDashoffset
  |> add (React.JSX.string "stroke-linecap" "strokeLinecap") strokeLinecap
  |> add (React.JSX.string "stroke-linejoin" "strokeLinejoin") strokeLinejoin
  |> add (React.JSX.string "stroke-miterlimit" "strokeMiterlimit") strokeMiterlimit
  |> add (React.JSX.string "stroke-opacity" "strokeOpacity") strokeOpacity
  |> add (React.JSX.string "stroke-width" "strokeWidth") strokeWidth
  |> add (React.JSX.string "surfaceScale" "surfaceScale") surfaceScale
  |> add (React.JSX.string "systemLanguage" "systemLanguage") systemLanguage
  |> add (React.JSX.string "tableValues" "tableValues") tableValues
  |> add (React.JSX.string "targetX" "targetX") targetX
  |> add (React.JSX.string "targetY" "targetY") targetY
  |> add (React.JSX.string "text-anchor" "textAnchor") textAnchor
  |> add (React.JSX.string "text-decoration" "textDecoration") textDecoration
  |> add (React.JSX.string "textLength" "textLength") textLength
  |> add (React.JSX.string "text-rendering" "textRendering") textRendering
  |> add (React.JSX.string "to" "to") to_
  |> add (React.JSX.string "transform" "transform") transform
  |> add (React.JSX.string "u1" "u1") u1
  |> add (React.JSX.string "u2" "u2") u2
  |> add (React.JSX.string "underline-position" "underlinePosition") underlinePosition
  |> add (React.JSX.string "underline-thickness" "underlineThickness") underlineThickness
  |> add (React.JSX.string "unicode" "unicode") unicode
  |> add (React.JSX.string "unicode-bidi" "unicodeBidi") unicodeBidi
  |> add (React.JSX.string "unicode-range" "unicodeRange") unicodeRange
  |> add (React.JSX.string "units-per-em" "unitsPerEm") unitsPerEm
  |> add (React.JSX.string "v-alphabetic" "vAlphabetic") vAlphabetic
  |> add (React.JSX.string "v-hanging" "vHanging") vHanging
  |> add (React.JSX.string "v-ideographic" "vIdeographic") vIdeographic
  |> add (React.JSX.string "vMathematical" "vMathematical") vMathematical (* Does it exists? *)
  |> add (React.JSX.string "values" "values") values
  |> add (React.JSX.string "vector-effect" "vectorEffect") vectorEffect
  |> add (React.JSX.string "version" "version") version
  |> add (React.JSX.string "vert-adv-x" "vertAdvX") vertAdvX
  |> add (React.JSX.string "vert-adv-y" "vertAdvY") vertAdvY
  |> add (React.JSX.string "vert-origin-x" "vertOriginX") vertOriginX
  |> add (React.JSX.string "vert-origin-y" "vertOriginY") vertOriginY
  |> add (React.JSX.string "viewBox" "viewBox") viewBox
  |> add (React.JSX.string "viewTarget" "viewTarget") viewTarget
  |> add (React.JSX.string "visibility" "visibility") visibility
  |> add (React.JSX.string "widths" "widths") widths
  |> add (React.JSX.string "word-spacing" "wordSpacing") wordSpacing
  |> add (React.JSX.string "writing-mode" "writingMode") writingMode
  |> add (React.JSX.string "x" "x") x
  |> add (React.JSX.string "x1" "x1") x1
  |> add (React.JSX.string "x2" "x2") x2
  |> add (React.JSX.string "xChannelSelector" "xChannelSelector") xChannelSelector
  |> add (React.JSX.string "x-height" "xHeight") xHeight
  |> add (React.JSX.string "xlink:arcrole" "xlinkActuate") xlinkActuate
  |> add (React.JSX.string "xlinkArcrole" "xlinkArcrole") xlinkArcrole
  |> add (React.JSX.string "xlink:href" "xlinkHref") xlinkHref
  |> add (React.JSX.string "xlink:role" "xlinkRole") xlinkRole
  |> add (React.JSX.string "xlink:show" "xlinkShow") xlinkShow
  |> add (React.JSX.string "xlink:title" "xlinkTitle") xlinkTitle
  |> add (React.JSX.string "xlink:type" "xlinkType") xlinkType
  |> add (React.JSX.string "xmlns" "xmlns") xmlns
  |> add (React.JSX.string "xmlnsXlink" "xmlnsXlink") xmlnsXlink
  |> add (React.JSX.string "xml:base" "xmlBase") xmlBase
  |> add (React.JSX.string "xml:lang" "xmlLang") xmlLang
  |> add (React.JSX.string "xml:space" "xmlSpace") xmlSpace
  |> add (React.JSX.string "y" "y") y
  |> add (React.JSX.string "y1" "y1") y1
  |> add (React.JSX.string "y2" "y2") y2
  |> add (React.JSX.string "yChannelSelector" "yChannelSelector") yChannelSelector
  |> add (React.JSX.string "z" "z") z
  |> add (React.JSX.string "zoomAndPan" "zoomAndPan") zoomAndPan
  |> add (React.JSX.string "about" "about") about
  |> add (React.JSX.string "datatype" "datatype") datatype
  |> add (React.JSX.string "inlist" "inlist") inlist
  |> add (React.JSX.string "prefix" "prefix") prefix
  |> add (React.JSX.string "property" "property") property
  |> add (React.JSX.string "resource" "resource") resource
  |> add (React.JSX.string "typeof" "typeof") typeof
  |> add (React.JSX.string "vocab" "vocab") vocab
  |> add (React.JSX.dangerouslyInnerHtml) dangerouslySetInnerHTML
  |> add (React.JSX.bool "suppressContentEditableWarning" "suppressContentEditableWarning") suppressContentEditableWarning
  |> add (React.JSX.bool "suppressHydrationWarning" "suppressHydrationWarning") suppressHydrationWarning
