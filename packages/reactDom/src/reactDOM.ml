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

let attributes_to_string tag attrs =
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
          (attributes_to_string tag attributes)
    | Lower_case_element { tag; attributes; children } ->
        is_root.contents <- false;
        Printf.sprintf "<%s%s%s>%s</%s>" tag root_attribute
          (attributes_to_string tag attributes)
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
        Printf.sprintf "<%s%s />" tag (attributes_to_string tag attributes)
    | Lower_case_element { tag; attributes; children } ->
        Printf.sprintf "<%s%s>%s</%s>" tag
          (attributes_to_string tag attributes)
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

exception Impossible_in_ssr of string

let fail_impossible_action_in_ssr fn =
  let msg = Printf.sprintf "'%s' shouldn't run on the server" fn in
  raise (Impossible_in_ssr msg)

let render _element _node = fail_impossible_action_in_ssr "ReactDOM.render"
let hydrate _element _node = fail_impossible_action_in_ssr "ReactDOM.hydrate"
let createPortal _reactElement _domElement = _reactElement

module Style = ReactDOMStyle

let createDOMElementVariadic (tag : string) ~(props : JSX.prop array)
    (childrens : React.element array) =
  React.createElement tag props (childrens |> Array.to_list)

let add item (map : React.JSX.prop list) =
  match item with Some i -> map |> List.cons i | None -> map

type dangerouslySetInnerHTML = { __html : string } [@@boxed]

(* domProps isn't used by the generated code from the ppx, and it's purpose is to
   allow usages from user's code via createElementVariadic and custom usages outside JSX *)
let domProps ?key ?ref ?ariaDetails ?ariaDisabled ?ariaHidden ?ariaKeyshortcuts
    ?ariaLabel ?ariaRoledescription ?ariaExpanded ?ariaLevel ?ariaModal
    ?ariaMultiline ?ariaMultiselectable ?ariaPlaceholder ?ariaReadonly
    ?ariaRequired ?ariaSelected ?ariaSort ?ariaValuemax ?ariaValuemin
    ?ariaValuenow ?ariaValuetext ?ariaAtomic ?ariaBusy ?ariaRelevant
    ?ariaGrabbed ?ariaActivedescendant ?ariaColcount ?ariaColindex ?ariaColspan
    ?ariaControls ?ariaDescribedby ?ariaErrormessage ?ariaFlowto ?ariaLabelledby
    ?ariaOwns ?ariaPosinset ?ariaRowcount ?ariaRowindex ?ariaRowspan
    ?ariaSetsize ?defaultChecked ?defaultValue ?accessKey ?className
    ?contentEditable ?contextMenu ?dir ?draggable ?hidden ?id ?lang ?role ?style
    ?spellCheck ?tabIndex ?title ?itemID ?itemProp ?itemRef ?itemScope ?itemType
    ?accept ?acceptCharset ?action ?allowFullScreen ?alt ?async ?autoComplete
    ?autoCapitalize ?autoFocus ?autoPlay ?challenge ?charSet ?checked ?cite
    ?crossOrigin ?cols ?colSpan ?content ?controls ?coords ?data ?dateTime
    ?default ?defer ?disabled ?download ?encType ?form ?formAction ?formTarget
    ?formMethod ?headers ?height ?high ?href ?hrefLang ?htmlFor ?httpEquiv ?icon
    ?inputMode ?integrity ?keyType ?kind ?label ?list ?loop ?low ?manifest ?max
    ?maxLength ?media ?mediaGroup ?method_ ?min ?minLength ?multiple ?muted
    ?name ?nonce ?noValidate ?open_ ?optimum ?pattern ?placeholder ?playsInline
    ?poster ?preload ?radioGroup ?readOnly ?rel ?required ?reversed ?rows
    ?rowSpan ?sandbox ?scope ?scoped ?scrolling ?selected ?shape ?size ?sizes
    ?span ?src ?srcDoc ?srcLang ?srcSet ?start ?step ?summary ?target ?type_
    ?useMap ?value ?width ?wrap ?onCopy ?onCut ?onPaste ?onCompositionEnd
    ?onCompositionStart ?onCompositionUpdate ?onKeyDown ?onKeyPress ?onKeyUp
    ?onFocus ?onBlur ?onChange ?onInput ?onSubmit ?onInvalid ?onClick
    ?onContextMenu ?onDoubleClick ?onDrag ?onDragEnd ?onDragEnter ?onDragExit
    ?onDragLeave ?onDragOver ?onDragStart ?onDrop ?onMouseDown ?onMouseEnter
    ?onMouseLeave ?onMouseMove ?onMouseOut ?onMouseOver ?onMouseUp ?onSelect
    ?onTouchCancel ?onTouchEnd ?onTouchMove ?onTouchStart ?onPointerOver
    ?onPointerEnter ?onPointerDown ?onPointerMove ?onPointerUp ?onPointerCancel
    ?onPointerOut ?onPointerLeave ?onGotPointerCapture ?onLostPointerCapture
    ?onScroll ?onWheel ?onAbort ?onCanPlay ?onCanPlayThrough ?onDurationChange
    ?onEmptied ?onEncrypetd ?onEnded ?onError ?onLoadedData ?onLoadedMetadata
    ?onLoadStart ?onPause ?onPlay ?onPlaying ?onProgress ?onRateChange ?onSeeked
    ?onSeeking ?onStalled ?onSuspend ?onTimeUpdate ?onVolumeChange ?onWaiting
    ?onAnimationStart ?onAnimationEnd ?onAnimationIteration ?onTransitionEnd
    ?accentHeight ?accumulate ?additive ?alignmentBaseline ?allowReorder
    ?alphabetic ?amplitude ?arabicForm ?ascent ?attributeName ?attributeType
    ?autoReverse ?azimuth ?baseFrequency ?baseProfile ?baselineShift ?bbox
    ?begin_ ?bias ?by ?calcMode ?capHeight ?clip ?clipPath ?clipPathUnits
    ?clipRule ?colorInterpolation ?colorInterpolationFilters ?colorProfile
    ?colorRendering ?contentScriptType ?contentStyleType ?cursor ?cx ?cy ?d
    ?decelerate ?descent ?diffuseConstant ?direction ?display ?divisor
    ?dominantBaseline ?dur ?dx ?dy ?edgeMode ?elevation ?enableBackground ?end_
    ?exponent ?externalResourcesRequired ?fill ?fillOpacity ?fillRule ?filter
    ?filterRes ?filterUnits ?floodColor ?floodOpacity ?focusable ?fontFamily
    ?fontSize ?fontSizeAdjust ?fontStretch ?fontStyle ?fontVariant ?fontWeight
    ?fomat ?from ?fx ?fy ?g1 ?g2 ?glyphName ?glyphOrientationHorizontal
    ?glyphOrientationVertical ?glyphRef ?gradientTransform ?gradientUnits
    ?hanging ?horizAdvX ?horizOriginX ?ideographic ?imageRendering ?in_ ?in2
    ?intercept ?k ?k1 ?k2 ?k3 ?k4 ?kernelMatrix ?kernelUnitLength ?kerning
    ?keyPoints ?keySplines ?keyTimes ?lengthAdjust ?letterSpacing ?lightingColor
    ?limitingConeAngle ?local ?markerEnd ?markerHeight ?markerMid ?markerStart
    ?markerUnits ?markerWidth ?mask ?maskContentUnits ?maskUnits ?mathematical
    ?mode ?numOctaves ?offset ?opacity ?operator ?order ?orient ?orientation
    ?origin ?overflow ?overflowX ?overflowY ?overlinePosition ?overlineThickness
    ?paintOrder ?panose1 ?pathLength ?patternContentUnits ?patternTransform
    ?patternUnits ?pointerEvents ?points ?pointsAtX ?pointsAtY ?pointsAtZ
    ?preserveAlpha ?preserveAspectRatio ?primitiveUnits ?r ?radius ?refX ?refY
    ?renderingIntent ?repeatCount ?repeatDur ?requiredExtensions
    ?requiredFeatures ?restart ?result ?rotate ?rx ?ry ?scale ?seed
    ?shapeRendering ?slope ?spacing ?specularConstant ?specularExponent ?speed
    ?spreadMethod ?startOffset ?stdDeviation ?stemh ?stemv ?stitchTiles
    ?stopColor ?stopOpacity ?strikethroughPosition ?strikethroughThickness
    ?stroke ?strokeDasharray ?strokeDashoffset ?strokeLinecap ?strokeLinejoin
    ?strokeMiterlimit ?strokeOpacity ?strokeWidth ?surfaceScale ?systemLanguage
    ?tableValues ?targetX ?targetY ?textAnchor ?textDecoration ?textLength
    ?textRendering ?to_ ?transform ?u1 ?u2 ?underlinePosition
    ?underlineThickness ?unicode ?unicodeBidi ?unicodeRange ?unitsPerEm
    ?vAlphabetic ?vHanging ?vIdeographic ?vMathematical ?values ?vectorEffect
    ?version ?vertAdvX ?vertAdvY ?vertOriginX ?vertOriginY ?viewBox ?viewTarget
    ?visibility ?widths ?wordSpacing ?writingMode ?x ?x1 ?x2 ?xChannelSelector
    ?xHeight ?xlinkActuate ?xlinkArcrole ?xlinkHref ?xlinkRole ?xlinkShow
    ?xlinkTitle ?xlinkType ?xmlns ?xmlnsXlink ?xmlBase ?xmlLang ?xmlSpace ?y ?y1
    ?y2 ?yChannelSelector ?z ?zoomAndPan ?about ?datatype ?inlist ?prefix
    ?property ?resource ?typeof ?vocab ?dangerouslySetInnerHTML
    ?suppressContentEditableWarning ?suppressHydrationWarning () =
  let open React.JSX in
  []
  |> add (Option.map (fun v -> String ("key", v)) key)
  |> add (Option.map (fun v -> Ref v) ref)
  |> add (Option.map (fun v -> String ("aria-details", v)) ariaDetails)
  |> add (Option.map (fun v -> String ("aria-details", v)) ariaDetails)
  |> add (Option.map (fun v -> Bool ("aria-disabled", v)) ariaDisabled)
  |> add (Option.map (fun v -> Bool ("aria-hidden", v)) ariaHidden)
  |> add
       (Option.map (fun v -> String ("aria-keyshortcuts", v)) ariaKeyshortcuts)
  |> add (Option.map (fun v -> String ("aria-label", v)) ariaLabel)
  |> add
       (Option.map
          (fun v -> String ("aria-roledescription", v))
          ariaRoledescription)
  |> add (Option.map (fun v -> Bool ("aria-expanded", v)) ariaExpanded)
  |> add
       (Option.map (fun v -> String ("aria-level", string_of_int v)) ariaLevel)
  |> add (Option.map (fun v -> Bool ("aria-modal", v)) ariaModal)
  |> add (Option.map (fun v -> Bool ("aria-multiline", v)) ariaMultiline)
  |> add
       (Option.map
          (fun v -> Bool ("aria-multiselectable", v))
          ariaMultiselectable)
  |> add (Option.map (fun v -> String ("aria-placeholder", v)) ariaPlaceholder)
  |> add (Option.map (fun v -> Bool ("aria-readonly", v)) ariaReadonly)
  |> add (Option.map (fun v -> Bool ("aria-required", v)) ariaRequired)
  |> add (Option.map (fun v -> Bool ("aria-selected", v)) ariaSelected)
  |> add (Option.map (fun v -> String ("aria-sort", v)) ariaSort)
  |> add
       (Option.map
          (fun v -> String ("aria-valuemax", string_of_float v))
          ariaValuemax)
  |> add
       (Option.map
          (fun v -> String ("aria-valuemin", string_of_float v))
          ariaValuemin)
  |> add
       (Option.map
          (fun v -> String ("aria-valuenow", string_of_float v))
          ariaValuenow)
  |> add (Option.map (fun v -> String ("aria-valuetext", v)) ariaValuetext)
  |> add (Option.map (fun v -> Bool ("aria-atomic", v)) ariaAtomic)
  |> add (Option.map (fun v -> Bool ("aria-busy", v)) ariaBusy)
  |> add (Option.map (fun v -> String ("aria-relevant", v)) ariaRelevant)
  |> add (Option.map (fun v -> Bool ("aria-grabbed", v)) ariaGrabbed)
  |> add
       (Option.map
          (fun v -> String ("aria-activedescendant", v))
          ariaActivedescendant)
  |> add
       (Option.map
          (fun v -> String ("aria-colcount", string_of_int v))
          ariaColcount)
  |> add
       (Option.map
          (fun v -> String ("aria-colindex", string_of_int v))
          ariaColindex)
  |> add
       (Option.map
          (fun v -> String ("aria-colspan", string_of_int v))
          ariaColspan)
  |> add (Option.map (fun v -> String ("aria-controls", v)) ariaControls)
  |> add (Option.map (fun v -> String ("aria-describedby", v)) ariaDescribedby)
  |> add
       (Option.map (fun v -> String ("aria-errormessage", v)) ariaErrormessage)
  |> add (Option.map (fun v -> String ("aria-flowto", v)) ariaFlowto)
  |> add (Option.map (fun v -> String ("aria-labelledby", v)) ariaLabelledby)
  |> add (Option.map (fun v -> String ("aria-owns", v)) ariaOwns)
  |> add
       (Option.map
          (fun v -> String ("aria-posinset", string_of_int v))
          ariaPosinset)
  |> add
       (Option.map
          (fun v -> String ("aria-rowcount", string_of_int v))
          ariaRowcount)
  |> add
       (Option.map
          (fun v -> String ("aria-rowindex", string_of_int v))
          ariaRowindex)
  |> add
       (Option.map
          (fun v -> String ("aria-rowspan", string_of_int v))
          ariaRowspan)
  |> add
       (Option.map
          (fun v -> String ("aria-setsize", string_of_int v))
          ariaSetsize)
  |> add (Option.map (fun v -> Bool ("checked", v)) defaultChecked)
  |> add (Option.map (fun v -> String ("value", v)) defaultValue)
  |> add (Option.map (fun v -> String ("accessKey", v)) accessKey)
  |> add (Option.map (fun v -> String ("class", v)) className)
  |> add (Option.map (fun v -> Bool ("contentEditable", v)) contentEditable)
  |> add (Option.map (fun v -> String ("contextMenu", v)) contextMenu)
  |> add (Option.map (fun v -> String ("dir", v)) dir)
  |> add (Option.map (fun v -> Bool ("draggable", v)) draggable)
  |> add (Option.map (fun v -> Bool ("hidden", v)) hidden)
  |> add (Option.map (fun v -> String ("id", v)) id)
  |> add (Option.map (fun v -> String ("lang", v)) lang)
  |> add (Option.map (fun v -> String ("role", v)) role)
  |> add (Option.map (fun v -> Style (ReactDOMStyle.to_string v)) style)
  |> add (Option.map (fun v -> Bool ("spellCheck", v)) spellCheck)
  |> add (Option.map (fun v -> String ("tabIndex", string_of_int v)) tabIndex)
  |> add (Option.map (fun v -> String ("title", v)) title)
  |> add (Option.map (fun v -> String ("itemID", v)) itemID)
  |> add (Option.map (fun v -> String ("itemProp", v)) itemProp)
  |> add (Option.map (fun v -> String ("itemRef", v)) itemRef)
  |> add (Option.map (fun v -> Bool ("itemScope", v)) itemScope)
  |> add (Option.map (fun v -> String ("itemType", v)) itemType)
  |> add (Option.map (fun v -> String ("accept", v)) accept)
  |> add (Option.map (fun v -> String ("acceptCharset", v)) acceptCharset)
  |> add (Option.map (fun v -> String ("action", v)) action)
  |> add (Option.map (fun v -> Bool ("allowFullScreen", v)) allowFullScreen)
  |> add (Option.map (fun v -> String ("alt", v)) alt)
  |> add (Option.map (fun v -> Bool ("async", v)) async)
  |> add (Option.map (fun v -> String ("autoComplete", v)) autoComplete)
  |> add (Option.map (fun v -> String ("autoCapitalize", v)) autoCapitalize)
  |> add (Option.map (fun v -> Bool ("autoFocus", v)) autoFocus)
  |> add (Option.map (fun v -> Bool ("autoPlay", v)) autoPlay)
  |> add (Option.map (fun v -> String ("challenge", v)) challenge)
  |> add (Option.map (fun v -> String ("charSet", v)) charSet)
  |> add (Option.map (fun v -> Bool ("checked", v)) checked)
  |> add (Option.map (fun v -> String ("cite", v)) cite)
  |> add (Option.map (fun v -> String ("crossOrigin", v)) crossOrigin)
  |> add (Option.map (fun v -> String ("cols", string_of_int v)) cols)
  |> add (Option.map (fun v -> String ("colSpan", string_of_int v)) colSpan)
  |> add (Option.map (fun v -> String ("content", v)) content)
  |> add (Option.map (fun v -> Bool ("controls", v)) controls)
  |> add (Option.map (fun v -> String ("coords", v)) coords)
  |> add (Option.map (fun v -> String ("data", v)) data)
  |> add (Option.map (fun v -> String ("dateTime", v)) dateTime)
  |> add (Option.map (fun v -> Bool ("default", v)) default)
  |> add (Option.map (fun v -> Bool ("defer", v)) defer)
  |> add (Option.map (fun v -> Bool ("disabled", v)) disabled)
  |> add (Option.map (fun v -> String ("download", v)) download)
  |> add (Option.map (fun v -> String ("encType", v)) encType)
  |> add (Option.map (fun v -> String ("form", v)) form)
  |> add (Option.map (fun v -> String ("formAction", v)) formAction)
  |> add (Option.map (fun v -> String ("formTarget", v)) formTarget)
  |> add (Option.map (fun v -> String ("formMethod", v)) formMethod)
  |> add (Option.map (fun v -> String ("headers", v)) headers)
  |> add (Option.map (fun v -> String ("height", v)) height)
  |> add (Option.map (fun v -> String ("high", string_of_int v)) high)
  |> add (Option.map (fun v -> String ("href", v)) href)
  |> add (Option.map (fun v -> String ("hrefLang", v)) hrefLang)
  |> add (Option.map (fun v -> String ("htmlFor", v)) htmlFor)
  |> add (Option.map (fun v -> String ("httpEquiv", v)) httpEquiv)
  |> add (Option.map (fun v -> String ("icon", v)) icon)
  |> add (Option.map (fun v -> String ("inputMode", v)) inputMode)
  |> add (Option.map (fun v -> String ("integrity", v)) integrity)
  |> add (Option.map (fun v -> String ("keyType", v)) keyType)
  |> add (Option.map (fun v -> String ("kind", v)) kind)
  |> add (Option.map (fun v -> String ("label", v)) label)
  |> add (Option.map (fun v -> String ("list", v)) list)
  |> add (Option.map (fun v -> Bool ("loop", v)) loop)
  |> add (Option.map (fun v -> String ("low", string_of_int v)) low)
  |> add (Option.map (fun v -> String ("manifest", v)) manifest)
  |> add (Option.map (fun v -> String ("max", v)) max)
  |> add (Option.map (fun v -> String ("maxLength", string_of_int v)) maxLength)
  |> add (Option.map (fun v -> String ("media", v)) media)
  |> add (Option.map (fun v -> String ("mediaGroup", v)) mediaGroup)
  |> add (Option.map (fun v -> String ("method", v)) method_)
  |> add (Option.map (fun v -> String ("min", v)) min)
  |> add (Option.map (fun v -> String ("minLength", string_of_int v)) minLength)
  |> add (Option.map (fun v -> Bool ("multiple", v)) multiple)
  |> add (Option.map (fun v -> Bool ("muted", v)) muted)
  |> add (Option.map (fun v -> String ("name", v)) name)
  |> add (Option.map (fun v -> String ("nonce", v)) nonce)
  |> add (Option.map (fun v -> Bool ("noValidate", v)) noValidate)
  |> add (Option.map (fun v -> Bool ("open", v)) open_)
  |> add (Option.map (fun v -> String ("optimum", string_of_int v)) optimum)
  |> add (Option.map (fun v -> String ("pattern", v)) pattern)
  |> add (Option.map (fun v -> String ("placeholder", v)) placeholder)
  |> add (Option.map (fun v -> Bool ("playsInline", v)) playsInline)
  |> add (Option.map (fun v -> String ("poster", v)) poster)
  |> add (Option.map (fun v -> String ("preload", v)) preload)
  |> add (Option.map (fun v -> String ("radioGroup", v)) radioGroup)
  |> add (Option.map (fun v -> Bool ("readOnly", v)) readOnly)
  |> add (Option.map (fun v -> String ("rel", v)) rel)
  |> add (Option.map (fun v -> Bool ("required", v)) required)
  |> add (Option.map (fun v -> Bool ("reversed", v)) reversed)
  |> add (Option.map (fun v -> String ("rows", string_of_int v)) rows)
  |> add (Option.map (fun v -> String ("rowSpan", string_of_int v)) rowSpan)
  |> add (Option.map (fun v -> String ("sandbox", v)) sandbox)
  |> add (Option.map (fun v -> String ("scope", v)) scope)
  |> add (Option.map (fun v -> Bool ("scoped", v)) scoped)
  |> add (Option.map (fun v -> String ("scrolling", v)) scrolling)
  |> add (Option.map (fun v -> Bool ("selected", v)) selected)
  |> add (Option.map (fun v -> String ("shape", v)) shape)
  |> add (Option.map (fun v -> String ("size", string_of_int v)) size)
  |> add (Option.map (fun v -> String ("sizes", v)) sizes)
  |> add (Option.map (fun v -> String ("span", string_of_int v)) span)
  |> add (Option.map (fun v -> String ("src", v)) src)
  |> add (Option.map (fun v -> String ("srcDoc", v)) srcDoc)
  |> add (Option.map (fun v -> String ("srcLang", v)) srcLang)
  |> add (Option.map (fun v -> String ("srcSet", v)) srcSet)
  |> add (Option.map (fun v -> String ("start", string_of_int v)) start)
  |> add (Option.map (fun v -> String ("step", string_of_float v)) step)
  |> add (Option.map (fun v -> String ("summary", v)) summary)
  |> add (Option.map (fun v -> String ("target", v)) target)
  |> add (Option.map (fun v -> String ("type", v)) type_)
  |> add (Option.map (fun v -> String ("useMap", v)) useMap)
  |> add (Option.map (fun v -> String ("value", v)) value)
  |> add (Option.map (fun v -> String ("width", v)) width)
  |> add (Option.map (fun v -> String ("wrap", v)) wrap)
  |> add (Option.map (fun v -> Event ("onCopy", Clipboard v)) onCopy)
  |> add (Option.map (fun v -> Event ("onCut", Clipboard v)) onCut)
  |> add (Option.map (fun v -> Event ("onPaste", Clipboard v)) onPaste)
  |> add
       (Option.map
          (fun v -> Event ("onCompositionEnd", Composition v))
          onCompositionEnd)
  |> add
       (Option.map
          (fun v -> Event ("onCompositionStart", Composition v))
          onCompositionStart)
  |> add
       (Option.map
          (fun v -> Event ("onCompositionUpdate", Composition v))
          onCompositionUpdate)
  |> add (Option.map (fun v -> Event ("onKeyDown", Keyboard v)) onKeyDown)
  |> add (Option.map (fun v -> Event ("onKeyPress", Keyboard v)) onKeyPress)
  |> add (Option.map (fun v -> Event ("onKeyUp", Keyboard v)) onKeyUp)
  |> add (Option.map (fun v -> Event ("onFocus", Focus v)) onFocus)
  |> add (Option.map (fun v -> Event ("onBlur", Focus v)) onBlur)
  |> add (Option.map (fun v -> Event ("onChange", Form v)) onChange)
  |> add (Option.map (fun v -> Event ("onInput", Form v)) onInput)
  |> add (Option.map (fun v -> Event ("onSubmit", Form v)) onSubmit)
  |> add (Option.map (fun v -> Event ("onInvalid", Form v)) onInvalid)
  |> add (Option.map (fun v -> Event ("onClick", Mouse v)) onClick)
  |> add (Option.map (fun v -> Event ("onContextMenu", Mouse v)) onContextMenu)
  |> add (Option.map (fun v -> Event ("onDoubleClick", Mouse v)) onDoubleClick)
  |> add (Option.map (fun v -> Event ("onDrag", Mouse v)) onDrag)
  |> add (Option.map (fun v -> Event ("onDragEnd", Mouse v)) onDragEnd)
  |> add (Option.map (fun v -> Event ("onDragEnter", Mouse v)) onDragEnter)
  |> add (Option.map (fun v -> Event ("onDragExit", Mouse v)) onDragExit)
  |> add (Option.map (fun v -> Event ("onDragLeave", Mouse v)) onDragLeave)
  |> add (Option.map (fun v -> Event ("onDragOver", Mouse v)) onDragOver)
  |> add (Option.map (fun v -> Event ("onDragStart", Mouse v)) onDragStart)
  |> add (Option.map (fun v -> Event ("onDrop", Mouse v)) onDrop)
  |> add (Option.map (fun v -> Event ("onMouseDown", Mouse v)) onMouseDown)
  |> add (Option.map (fun v -> Event ("onMouseEnter", Mouse v)) onMouseEnter)
  |> add (Option.map (fun v -> Event ("onMouseLeave", Mouse v)) onMouseLeave)
  |> add (Option.map (fun v -> Event ("onMouseMove", Mouse v)) onMouseMove)
  |> add (Option.map (fun v -> Event ("onMouseOut", Mouse v)) onMouseOut)
  |> add (Option.map (fun v -> Event ("onMouseOver", Mouse v)) onMouseOver)
  |> add (Option.map (fun v -> Event ("onMouseUp", Mouse v)) onMouseUp)
  |> add (Option.map (fun v -> Event ("onSelect", Selection v)) onSelect)
  |> add (Option.map (fun v -> Event ("onTouchCancel", Touch v)) onTouchCancel)
  |> add (Option.map (fun v -> Event ("onTouchEnd", Touch v)) onTouchEnd)
  |> add (Option.map (fun v -> Event ("onTouchMove", Touch v)) onTouchMove)
  |> add (Option.map (fun v -> Event ("onTouchStart", Touch v)) onTouchStart)
  |> add
       (Option.map (fun v -> Event ("onPointerOver", Pointer v)) onPointerOver)
  |> add
       (Option.map
          (fun v -> Event ("onPointerEnter", Pointer v))
          onPointerEnter)
  |> add
       (Option.map (fun v -> Event ("onPointerDown", Pointer v)) onPointerDown)
  |> add
       (Option.map (fun v -> Event ("onPointerMove", Pointer v)) onPointerMove)
  |> add (Option.map (fun v -> Event ("onPointerUp", Pointer v)) onPointerUp)
  |> add
       (Option.map
          (fun v -> Event ("onPointerCancel", Pointer v))
          onPointerCancel)
  |> add (Option.map (fun v -> Event ("onPointerOut", Pointer v)) onPointerOut)
  |> add
       (Option.map
          (fun v -> Event ("onPointerLeave", Pointer v))
          onPointerLeave)
  |> add
       (Option.map
          (fun v -> Event ("onGotPointerCapture", Pointer v))
          onGotPointerCapture)
  |> add
       (Option.map
          (fun v -> Event ("onLostPointerCapture", Pointer v))
          onLostPointerCapture)
  |> add (Option.map (fun v -> Event ("onScroll", UI v)) onScroll)
  |> add (Option.map (fun v -> Event ("onWheel", Wheel v)) onWheel)
  |> add (Option.map (fun v -> Event ("onAbort", Media v)) onAbort)
  |> add (Option.map (fun v -> Event ("onCanPlay", Media v)) onCanPlay)
  |> add
       (Option.map
          (fun v -> Event ("onCanPlayThrough", Media v))
          onCanPlayThrough)
  |> add
       (Option.map
          (fun v -> Event ("onDurationChange", Media v))
          onDurationChange)
  |> add (Option.map (fun v -> Event ("onEmptied", Media v)) onEmptied)
  |> add (Option.map (fun v -> Event ("onEncrypetd", Media v)) onEncrypetd)
  |> add (Option.map (fun v -> Event ("onEnded", Media v)) onEnded)
  |> add (Option.map (fun v -> Event ("onError", Media v)) onError)
  |> add (Option.map (fun v -> Event ("onLoadedData", Media v)) onLoadedData)
  |> add
       (Option.map
          (fun v -> Event ("onLoadedMetadata", Media v))
          onLoadedMetadata)
  |> add (Option.map (fun v -> Event ("onLoadStart", Media v)) onLoadStart)
  |> add (Option.map (fun v -> Event ("onPause", Media v)) onPause)
  |> add (Option.map (fun v -> Event ("onPlay", Media v)) onPlay)
  |> add (Option.map (fun v -> Event ("onPlaying", Media v)) onPlaying)
  |> add (Option.map (fun v -> Event ("onProgress", Media v)) onProgress)
  |> add (Option.map (fun v -> Event ("onRateChange", Media v)) onRateChange)
  |> add (Option.map (fun v -> Event ("onSeeked", Media v)) onSeeked)
  |> add (Option.map (fun v -> Event ("onSeeking", Media v)) onSeeking)
  |> add (Option.map (fun v -> Event ("onStalled", Media v)) onStalled)
  |> add (Option.map (fun v -> Event ("onSuspend", Media v)) onSuspend)
  |> add (Option.map (fun v -> Event ("onTimeUpdate", Media v)) onTimeUpdate)
  |> add
       (Option.map (fun v -> Event ("onVolumeChange", Media v)) onVolumeChange)
  |> add (Option.map (fun v -> Event ("onWaiting", Media v)) onWaiting)
  |> add
       (Option.map
          (fun v -> Event ("onAnimationStart", Animation v))
          onAnimationStart)
  |> add
       (Option.map
          (fun v -> Event ("onAnimationEnd", Animation v))
          onAnimationEnd)
  |> add
       (Option.map
          (fun v -> Event ("onAnimationIteration", Animation v))
          onAnimationIteration)
  |> add
       (Option.map
          (fun v -> Event ("onTransitionEnd", Transition v))
          onTransitionEnd)
  |> add (Option.map (fun v -> String ("accentHeight", v)) accentHeight)
  |> add (Option.map (fun v -> String ("accumulate", v)) accumulate)
  |> add (Option.map (fun v -> String ("additive", v)) additive)
  |> add
       (Option.map (fun v -> String ("alignmentBaseline", v)) alignmentBaseline)
  |> add (Option.map (fun v -> String ("allowReorder", v)) allowReorder)
  |> add (Option.map (fun v -> String ("alphabetic", v)) alphabetic)
  |> add (Option.map (fun v -> String ("amplitude", v)) amplitude)
  |> add (Option.map (fun v -> String ("arabicForm", v)) arabicForm)
  |> add (Option.map (fun v -> String ("ascent", v)) ascent)
  |> add (Option.map (fun v -> String ("attributeName", v)) attributeName)
  |> add (Option.map (fun v -> String ("attributeType", v)) attributeType)
  |> add (Option.map (fun v -> String ("autoReverse", v)) autoReverse)
  |> add (Option.map (fun v -> String ("azimuth", v)) azimuth)
  |> add (Option.map (fun v -> String ("baseFrequency", v)) baseFrequency)
  |> add (Option.map (fun v -> String ("baseProfile", v)) baseProfile)
  |> add (Option.map (fun v -> String ("baselineShift", v)) baselineShift)
  |> add (Option.map (fun v -> String ("bbox", v)) bbox)
  |> add (Option.map (fun v -> String ("begin", v)) begin_)
  |> add (Option.map (fun v -> String ("bias", v)) bias)
  |> add (Option.map (fun v -> String ("by", v)) by)
  |> add (Option.map (fun v -> String ("calcMode", v)) calcMode)
  |> add (Option.map (fun v -> String ("capHeight", v)) capHeight)
  |> add (Option.map (fun v -> String ("clip", v)) clip)
  |> add (Option.map (fun v -> String ("clipPath", v)) clipPath)
  |> add (Option.map (fun v -> String ("clipPathUnits", v)) clipPathUnits)
  |> add (Option.map (fun v -> String ("clipRule", v)) clipRule)
  |> add
       (Option.map
          (fun v -> String ("colorInterpolation", v))
          colorInterpolation)
  |> add
       (Option.map
          (fun v -> String ("colorInterpolationFilters", v))
          colorInterpolationFilters)
  |> add (Option.map (fun v -> String ("colorProfile", v)) colorProfile)
  |> add (Option.map (fun v -> String ("colorRendering", v)) colorRendering)
  |> add
       (Option.map (fun v -> String ("contentScriptType", v)) contentScriptType)
  |> add (Option.map (fun v -> String ("contentStyleType", v)) contentStyleType)
  |> add (Option.map (fun v -> String ("cursor", v)) cursor)
  |> add (Option.map (fun v -> String ("cx", v)) cx)
  |> add (Option.map (fun v -> String ("cy", v)) cy)
  |> add (Option.map (fun v -> String ("d", v)) d)
  |> add (Option.map (fun v -> String ("decelerate", v)) decelerate)
  |> add (Option.map (fun v -> String ("descent", v)) descent)
  |> add (Option.map (fun v -> String ("diffuseConstant", v)) diffuseConstant)
  |> add (Option.map (fun v -> String ("direction", v)) direction)
  |> add (Option.map (fun v -> String ("display", v)) display)
  |> add (Option.map (fun v -> String ("divisor", v)) divisor)
  |> add (Option.map (fun v -> String ("dominantBaseline", v)) dominantBaseline)
  |> add (Option.map (fun v -> String ("dur", v)) dur)
  |> add (Option.map (fun v -> String ("dx", v)) dx)
  |> add (Option.map (fun v -> String ("dy", v)) dy)
  |> add (Option.map (fun v -> String ("edgeMode", v)) edgeMode)
  |> add (Option.map (fun v -> String ("elevation", v)) elevation)
  |> add (Option.map (fun v -> String ("enableBackground", v)) enableBackground)
  |> add (Option.map (fun v -> String ("end", v)) end_)
  |> add (Option.map (fun v -> String ("exponent", v)) exponent)
  |> add
       (Option.map
          (fun v -> String ("externalResourcesRequired", v))
          externalResourcesRequired)
  |> add (Option.map (fun v -> String ("fill", v)) fill)
  |> add (Option.map (fun v -> String ("fillOpacity", v)) fillOpacity)
  |> add (Option.map (fun v -> String ("fillRule", v)) fillRule)
  |> add (Option.map (fun v -> String ("filter", v)) filter)
  |> add (Option.map (fun v -> String ("filterRes", v)) filterRes)
  |> add (Option.map (fun v -> String ("filterUnits", v)) filterUnits)
  |> add (Option.map (fun v -> String ("floodColor", v)) floodColor)
  |> add (Option.map (fun v -> String ("floodOpacity", v)) floodOpacity)
  |> add (Option.map (fun v -> String ("focusable", v)) focusable)
  |> add (Option.map (fun v -> String ("fontFamily", v)) fontFamily)
  |> add (Option.map (fun v -> String ("fontSize", v)) fontSize)
  |> add (Option.map (fun v -> String ("fontSizeAdjust", v)) fontSizeAdjust)
  |> add (Option.map (fun v -> String ("fontStretch", v)) fontStretch)
  |> add (Option.map (fun v -> String ("fontStyle", v)) fontStyle)
  |> add (Option.map (fun v -> String ("fontVariant", v)) fontVariant)
  |> add (Option.map (fun v -> String ("fontWeight", v)) fontWeight)
  |> add (Option.map (fun v -> String ("fomat", v)) fomat)
  |> add (Option.map (fun v -> String ("from", v)) from)
  |> add (Option.map (fun v -> String ("fx", v)) fx)
  |> add (Option.map (fun v -> String ("fy", v)) fy)
  |> add (Option.map (fun v -> String ("g1", v)) g1)
  |> add (Option.map (fun v -> String ("g2", v)) g2)
  |> add (Option.map (fun v -> String ("glyphName", v)) glyphName)
  |> add
       (Option.map
          (fun v -> String ("glyphOrientationHorizontal", v))
          glyphOrientationHorizontal)
  |> add
       (Option.map
          (fun v -> String ("glyphOrientationVertical", v))
          glyphOrientationVertical)
  |> add (Option.map (fun v -> String ("glyphRef", v)) glyphRef)
  |> add
       (Option.map (fun v -> String ("gradientTransform", v)) gradientTransform)
  |> add (Option.map (fun v -> String ("gradientUnits", v)) gradientUnits)
  |> add (Option.map (fun v -> String ("hanging", v)) hanging)
  |> add (Option.map (fun v -> String ("horizAdvX", v)) horizAdvX)
  |> add (Option.map (fun v -> String ("horizOriginX", v)) horizOriginX)
  |> add (Option.map (fun v -> String ("ideographic", v)) ideographic)
  |> add (Option.map (fun v -> String ("imageRendering", v)) imageRendering)
  |> add (Option.map (fun v -> String ("in", v)) in_)
  |> add (Option.map (fun v -> String ("in2", v)) in2)
  |> add (Option.map (fun v -> String ("intercept", v)) intercept)
  |> add (Option.map (fun v -> String ("k", v)) k)
  |> add (Option.map (fun v -> String ("k1", v)) k1)
  |> add (Option.map (fun v -> String ("k2", v)) k2)
  |> add (Option.map (fun v -> String ("k3", v)) k3)
  |> add (Option.map (fun v -> String ("k4", v)) k4)
  |> add (Option.map (fun v -> String ("kernelMatrix", v)) kernelMatrix)
  |> add (Option.map (fun v -> String ("kernelUnitLength", v)) kernelUnitLength)
  |> add (Option.map (fun v -> String ("kerning", v)) kerning)
  |> add (Option.map (fun v -> String ("keyPoints", v)) keyPoints)
  |> add (Option.map (fun v -> String ("keySplines", v)) keySplines)
  |> add (Option.map (fun v -> String ("keyTimes", v)) keyTimes)
  |> add (Option.map (fun v -> String ("lengthAdjust", v)) lengthAdjust)
  |> add (Option.map (fun v -> String ("letterSpacing", v)) letterSpacing)
  |> add (Option.map (fun v -> String ("lightingColor", v)) lightingColor)
  |> add
       (Option.map (fun v -> String ("limitingConeAngle", v)) limitingConeAngle)
  |> add (Option.map (fun v -> String ("local", v)) local)
  |> add (Option.map (fun v -> String ("markerEnd", v)) markerEnd)
  |> add (Option.map (fun v -> String ("markerHeight", v)) markerHeight)
  |> add (Option.map (fun v -> String ("markerMid", v)) markerMid)
  |> add (Option.map (fun v -> String ("markerStart", v)) markerStart)
  |> add (Option.map (fun v -> String ("markerUnits", v)) markerUnits)
  |> add (Option.map (fun v -> String ("markerWidth", v)) markerWidth)
  |> add (Option.map (fun v -> String ("mask", v)) mask)
  |> add (Option.map (fun v -> String ("maskContentUnits", v)) maskContentUnits)
  |> add (Option.map (fun v -> String ("maskUnits", v)) maskUnits)
  |> add (Option.map (fun v -> String ("mathematical", v)) mathematical)
  |> add (Option.map (fun v -> String ("mode", v)) mode)
  |> add (Option.map (fun v -> String ("numOctaves", v)) numOctaves)
  |> add (Option.map (fun v -> String ("offset", v)) offset)
  |> add (Option.map (fun v -> String ("opacity", v)) opacity)
  |> add (Option.map (fun v -> String ("operator", v)) operator)
  |> add (Option.map (fun v -> String ("order", v)) order)
  |> add (Option.map (fun v -> String ("orient", v)) orient)
  |> add (Option.map (fun v -> String ("orientation", v)) orientation)
  |> add (Option.map (fun v -> String ("origin", v)) origin)
  |> add (Option.map (fun v -> String ("overflow", v)) overflow)
  |> add (Option.map (fun v -> String ("overflowX", v)) overflowX)
  |> add (Option.map (fun v -> String ("overflowY", v)) overflowY)
  |> add (Option.map (fun v -> String ("overlinePosition", v)) overlinePosition)
  |> add
       (Option.map (fun v -> String ("overlineThickness", v)) overlineThickness)
  |> add (Option.map (fun v -> String ("paintOrder", v)) paintOrder)
  |> add (Option.map (fun v -> String ("panose1", v)) panose1)
  |> add (Option.map (fun v -> String ("pathLength", v)) pathLength)
  |> add
       (Option.map
          (fun v -> String ("patternContentUnits", v))
          patternContentUnits)
  |> add (Option.map (fun v -> String ("patternTransform", v)) patternTransform)
  |> add (Option.map (fun v -> String ("patternUnits", v)) patternUnits)
  |> add (Option.map (fun v -> String ("pointerEvents", v)) pointerEvents)
  |> add (Option.map (fun v -> String ("points", v)) points)
  |> add (Option.map (fun v -> String ("pointsAtX", v)) pointsAtX)
  |> add (Option.map (fun v -> String ("pointsAtY", v)) pointsAtY)
  |> add (Option.map (fun v -> String ("pointsAtZ", v)) pointsAtZ)
  |> add (Option.map (fun v -> String ("preserveAlpha", v)) preserveAlpha)
  |> add
       (Option.map
          (fun v -> String ("preserveAspectRatio", v))
          preserveAspectRatio)
  |> add (Option.map (fun v -> String ("primitiveUnits", v)) primitiveUnits)
  |> add (Option.map (fun v -> String ("r", v)) r)
  |> add (Option.map (fun v -> String ("radius", v)) radius)
  |> add (Option.map (fun v -> String ("refX", v)) refX)
  |> add (Option.map (fun v -> String ("refY", v)) refY)
  |> add (Option.map (fun v -> String ("renderingIntent", v)) renderingIntent)
  |> add (Option.map (fun v -> String ("repeatCount", v)) repeatCount)
  |> add (Option.map (fun v -> String ("repeatDur", v)) repeatDur)
  |> add
       (Option.map
          (fun v -> String ("requiredExtensions", v))
          requiredExtensions)
  |> add (Option.map (fun v -> String ("requiredFeatures", v)) requiredFeatures)
  |> add (Option.map (fun v -> String ("restart", v)) restart)
  |> add (Option.map (fun v -> String ("result", v)) result)
  |> add (Option.map (fun v -> String ("rotate", v)) rotate)
  |> add (Option.map (fun v -> String ("rx", v)) rx)
  |> add (Option.map (fun v -> String ("ry", v)) ry)
  |> add (Option.map (fun v -> String ("scale", v)) scale)
  |> add (Option.map (fun v -> String ("seed", v)) seed)
  |> add (Option.map (fun v -> String ("shapeRendering", v)) shapeRendering)
  |> add (Option.map (fun v -> String ("slope", v)) slope)
  |> add (Option.map (fun v -> String ("spacing", v)) spacing)
  |> add (Option.map (fun v -> String ("specularConstant", v)) specularConstant)
  |> add (Option.map (fun v -> String ("specularExponent", v)) specularExponent)
  |> add (Option.map (fun v -> String ("speed", v)) speed)
  |> add (Option.map (fun v -> String ("spreadMethod", v)) spreadMethod)
  |> add (Option.map (fun v -> String ("startOffset", v)) startOffset)
  |> add (Option.map (fun v -> String ("stdDeviation", v)) stdDeviation)
  |> add (Option.map (fun v -> String ("stemh", v)) stemh)
  |> add (Option.map (fun v -> String ("stemv", v)) stemv)
  |> add (Option.map (fun v -> String ("stitchTiles", v)) stitchTiles)
  |> add (Option.map (fun v -> String ("stopColor", v)) stopColor)
  |> add (Option.map (fun v -> String ("stopOpacity", v)) stopOpacity)
  |> add
       (Option.map
          (fun v -> String ("strikethroughPosition", v))
          strikethroughPosition)
  |> add
       (Option.map
          (fun v -> String ("strikethroughThickness", v))
          strikethroughThickness)
  |> add (Option.map (fun v -> String ("stroke", v)) stroke)
  |> add (Option.map (fun v -> String ("strokeDasharray", v)) strokeDasharray)
  |> add (Option.map (fun v -> String ("strokeDashoffset", v)) strokeDashoffset)
  |> add (Option.map (fun v -> String ("strokeLinecap", v)) strokeLinecap)
  |> add (Option.map (fun v -> String ("strokeLinejoin", v)) strokeLinejoin)
  |> add (Option.map (fun v -> String ("strokeMiterlimit", v)) strokeMiterlimit)
  |> add (Option.map (fun v -> String ("strokeOpacity", v)) strokeOpacity)
  |> add (Option.map (fun v -> String ("strokeWidth", v)) strokeWidth)
  |> add (Option.map (fun v -> String ("surfaceScale", v)) surfaceScale)
  |> add (Option.map (fun v -> String ("systemLanguage", v)) systemLanguage)
  |> add (Option.map (fun v -> String ("tableValues", v)) tableValues)
  |> add (Option.map (fun v -> String ("targetX", v)) targetX)
  |> add (Option.map (fun v -> String ("targetY", v)) targetY)
  |> add (Option.map (fun v -> String ("textAnchor", v)) textAnchor)
  |> add (Option.map (fun v -> String ("textDecoration", v)) textDecoration)
  |> add (Option.map (fun v -> String ("textLength", v)) textLength)
  |> add (Option.map (fun v -> String ("textRendering", v)) textRendering)
  |> add (Option.map (fun v -> String ("to", v)) to_)
  |> add (Option.map (fun v -> String ("transform", v)) transform)
  |> add (Option.map (fun v -> String ("u1", v)) u1)
  |> add (Option.map (fun v -> String ("u2", v)) u2)
  |> add
       (Option.map (fun v -> String ("underlinePosition", v)) underlinePosition)
  |> add
       (Option.map
          (fun v -> String ("underlineThickness", v))
          underlineThickness)
  |> add (Option.map (fun v -> String ("unicode", v)) unicode)
  |> add (Option.map (fun v -> String ("unicodeBidi", v)) unicodeBidi)
  |> add (Option.map (fun v -> String ("unicodeRange", v)) unicodeRange)
  |> add (Option.map (fun v -> String ("unitsPerEm", v)) unitsPerEm)
  |> add (Option.map (fun v -> String ("vAlphabetic", v)) vAlphabetic)
  |> add (Option.map (fun v -> String ("vHanging", v)) vHanging)
  |> add (Option.map (fun v -> String ("vIdeographic", v)) vIdeographic)
  |> add (Option.map (fun v -> String ("vMathematical", v)) vMathematical)
  |> add (Option.map (fun v -> String ("values", v)) values)
  |> add (Option.map (fun v -> String ("vectorEffect", v)) vectorEffect)
  |> add (Option.map (fun v -> String ("version", v)) version)
  |> add (Option.map (fun v -> String ("vertAdvX", v)) vertAdvX)
  |> add (Option.map (fun v -> String ("vertAdvY", v)) vertAdvY)
  |> add (Option.map (fun v -> String ("vertOriginX", v)) vertOriginX)
  |> add (Option.map (fun v -> String ("vertOriginY", v)) vertOriginY)
  |> add (Option.map (fun v -> String ("viewBox", v)) viewBox)
  |> add (Option.map (fun v -> String ("viewTarget", v)) viewTarget)
  |> add (Option.map (fun v -> String ("visibility", v)) visibility)
  |> add (Option.map (fun v -> String ("widths", v)) widths)
  |> add (Option.map (fun v -> String ("wordSpacing", v)) wordSpacing)
  |> add (Option.map (fun v -> String ("writingMode", v)) writingMode)
  |> add (Option.map (fun v -> String ("x", v)) x)
  |> add (Option.map (fun v -> String ("x1", v)) x1)
  |> add (Option.map (fun v -> String ("x2", v)) x2)
  |> add (Option.map (fun v -> String ("xChannelSelector", v)) xChannelSelector)
  |> add (Option.map (fun v -> String ("xHeight", v)) xHeight)
  |> add (Option.map (fun v -> String ("xlinkActuate", v)) xlinkActuate)
  |> add (Option.map (fun v -> String ("xlinkArcrole", v)) xlinkArcrole)
  |> add (Option.map (fun v -> String ("xlinkHref", v)) xlinkHref)
  |> add (Option.map (fun v -> String ("xlinkRole", v)) xlinkRole)
  |> add (Option.map (fun v -> String ("xlinkShow", v)) xlinkShow)
  |> add (Option.map (fun v -> String ("xlinkTitle", v)) xlinkTitle)
  |> add (Option.map (fun v -> String ("xlinkType", v)) xlinkType)
  |> add (Option.map (fun v -> String ("xmlns", v)) xmlns)
  |> add (Option.map (fun v -> String ("xmlnsXlink", v)) xmlnsXlink)
  |> add (Option.map (fun v -> String ("xmlBase", v)) xmlBase)
  |> add (Option.map (fun v -> String ("xmlLang", v)) xmlLang)
  |> add (Option.map (fun v -> String ("xmlSpace", v)) xmlSpace)
  |> add (Option.map (fun v -> String ("y", v)) y)
  |> add (Option.map (fun v -> String ("y1", v)) y1)
  |> add (Option.map (fun v -> String ("y2", v)) y2)
  |> add (Option.map (fun v -> String ("yChannelSelector", v)) yChannelSelector)
  |> add (Option.map (fun v -> String ("z", v)) z)
  |> add (Option.map (fun v -> String ("zoomAndPan", v)) zoomAndPan)
  |> add (Option.map (fun v -> String ("about", v)) about)
  |> add (Option.map (fun v -> String ("datatype", v)) datatype)
  |> add (Option.map (fun v -> String ("inlist", v)) inlist)
  |> add (Option.map (fun v -> String ("prefix", v)) prefix)
  |> add (Option.map (fun v -> String ("property", v)) property)
  |> add (Option.map (fun v -> String ("resource", v)) resource)
  |> add (Option.map (fun v -> String ("typeof", v)) typeof)
  |> add (Option.map (fun v -> String ("vocab", v)) vocab)
  |> add
       (Option.map
          (fun v -> DangerouslyInnerHtml v.__html)
          dangerouslySetInnerHTML)
  |> add
       (Option.map
          (fun v -> Bool ("suppressContentEditableWarning", v))
          suppressContentEditableWarning)
  |> add
       (Option.map
          (fun v -> Bool ("suppressHydrationWarning", v))
          suppressHydrationWarning)
  |> Array.of_list
