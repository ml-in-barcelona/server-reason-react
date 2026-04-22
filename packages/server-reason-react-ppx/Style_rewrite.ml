(* Rewrites [ReactDOM.Style.make ~foo:a ~bar:b ()] at compile time into a
   direct list of [(kebab, camel, value)] tuples, avoiding the 347-optional-arg
   calling convention overhead (~1460 words/call on stock OCaml).

   The PPX only rewrites calls where:
   - the function is literally [ReactDOM.Style.make] (or [Style.make] in the
     ReactDOM module namespace), and
   - all arguments are labelled (not optional), and
   - the final arg is [()].
   Calls that don't fit fall through to the runtime function. *)

open Ppxlib
open Ast_builder.Default

(* CamelCase -> kebab-case mapping, kept in sync with ReactDOMStyle.ml. *)
let mapping =
  [
    ("azimuth", "azimuth");
    ("background", "background");
    ("backgroundAttachment", "background-attachment");
    ("backgroundColor", "background-color");
    ("backgroundImage", "background-image");
    ("backgroundPosition", "background-position");
    ("backgroundRepeat", "background-repeat");
    ("border", "border");
    ("borderCollapse", "border-collapse");
    ("borderColor", "border-color");
    ("borderSpacing", "border-spacing");
    ("borderStyle", "border-style");
    ("borderTop", "border-top");
    ("borderRight", "border-right");
    ("borderBottom", "border-bottom");
    ("borderLeft", "border-left");
    ("borderTopColor", "border-top-color");
    ("borderRightColor", "border-right-color");
    ("borderBottomColor", "border-bottom-color");
    ("borderLeftColor", "border-left-color");
    ("borderTopStyle", "border-top-style");
    ("borderRightStyle", "border-right-style");
    ("borderBottomStyle", "border-bottom-style");
    ("borderLeftStyle", "border-left-style");
    ("borderTopWidth", "border-top-width");
    ("borderRightWidth", "border-right-width");
    ("borderBottomWidth", "border-bottom-width");
    ("borderLeftWidth", "border-left-width");
    ("borderWidth", "border-width");
    ("bottom", "bottom");
    ("captionSide", "caption-side");
    ("clear", "clear");
    ("color", "color");
    ("content", "content");
    ("counterIncrement", "counter-increment");
    ("counterReset", "counter-reset");
    ("cue", "cue");
    ("cueAfter", "cue-after");
    ("cueBefore", "cue-before");
    ("cursor", "cursor");
    ("direction", "direction");
    ("display", "display");
    ("elevation", "elevation");
    ("emptyCells", "empty-cells");
    ("float", "float");
    ("font", "font");
    ("fontFamily", "font-family");
    ("fontSize", "font-size");
    ("fontSizeAdjust", "font-size-adjust");
    ("fontStretch", "font-stretch");
    ("fontStyle", "font-style");
    ("fontVariant", "font-variant");
    ("fontWeight", "font-weight");
    ("height", "height");
    ("left", "left");
    ("letterSpacing", "letter-spacing");
    ("lineHeight", "line-height");
    ("listStyle", "list-style");
    ("listStyleImage", "list-style-image");
    ("listStylePosition", "list-style-position");
    ("listStyleType", "list-style-type");
    ("margin", "margin");
    ("marginTop", "margin-top");
    ("marginRight", "margin-right");
    ("marginBottom", "margin-bottom");
    ("marginLeft", "margin-left");
    ("markerOffset", "marker-offset");
    ("marks", "marks");
    ("maxHeight", "max-height");
    ("maxWidth", "max-width");
    ("minHeight", "min-height");
    ("minWidth", "min-width");
    ("orphans", "orphans");
    ("outline", "outline");
    ("outlineColor", "outline-color");
    ("outlineStyle", "outline-style");
    ("outlineWidth", "outline-width");
    ("overflow", "overflow");
    ("overflowX", "overflow-x");
    ("overflowY", "overflow-y");
    ("padding", "padding");
    ("paddingTop", "padding-top");
    ("paddingRight", "padding-right");
    ("paddingBottom", "padding-bottom");
    ("paddingLeft", "padding-left");
    ("page", "page");
    ("pageBreakAfter", "page-break-after");
    ("pageBreakBefore", "page-break-before");
    ("pageBreakInside", "page-break-inside");
    ("pause", "pause");
    ("pauseAfter", "pause-after");
    ("pauseBefore", "pause-before");
    ("pitch", "pitch");
    ("pitchRange", "pitch-range");
    ("playDuring", "play-during");
    ("position", "position");
    ("quotes", "quotes");
    ("richness", "richness");
    ("right", "right");
    ("size", "size");
    ("speak", "speak");
    ("speakHeader", "speak-header");
    ("speakNumeral", "speak-numeral");
    ("speakPunctuation", "speak-punctuation");
    ("speechRate", "speech-rate");
    ("stress", "stress");
    ("tableLayout", "table-layout");
    ("textAlign", "text-align");
    ("textDecoration", "text-decoration");
    ("textIndent", "text-indent");
    ("textShadow", "text-shadow");
    ("textTransform", "text-transform");
    ("top", "top");
    ("unicodeBidi", "unicode-bidi");
    ("verticalAlign", "vertical-align");
    ("visibility", "visibility");
    ("voiceFamily", "voice-family");
    ("volume", "volume");
    ("whiteSpace", "white-space");
    ("widows", "widows");
    ("width", "width");
    ("wordSpacing", "word-spacing");
    ("zIndex", "z-index");
    ("opacity", "opacity");
    ("backgroundOrigin", "background-origin");
    ("backgroundSize", "background-size");
    ("backgroundClip", "background-clip");
    ("borderRadius", "border-radius");
    ("borderTopLeftRadius", "border-top-left-radius");
    ("borderTopRightRadius", "border-top-right-radius");
    ("borderBottomLeftRadius", "border-bottom-left-radius");
    ("borderBottomRightRadius", "border-bottom-right-radius");
    ("borderImage", "border-image");
    ("borderImageSource", "border-image-source");
    ("borderImageSlice", "border-image-slice");
    ("borderImageWidth", "border-image-width");
    ("borderImageOutset", "border-image-outset");
    ("borderImageRepeat", "border-image-repeat");
    ("boxShadow", "box-shadow");
    ("columns", "columns");
    ("columnCount", "column-count");
    ("columnFill", "column-fill");
    ("columnGap", "column-gap");
    ("columnRule", "column-rule");
    ("columnRuleColor", "column-rule-color");
    ("columnRuleStyle", "column-rule-style");
    ("columnRuleWidth", "column-rule-width");
    ("columnSpan", "column-span");
    ("columnWidth", "column-width");
    ("breakAfter", "break-after");
    ("breakBefore", "break-before");
    ("breakInside", "break-inside");
    ("rest", "rest");
    ("restAfter", "rest-after");
    ("restBefore", "rest-before");
    ("speakAs", "speak-as");
    ("voiceBalance", "voice-balance");
    ("voiceDuration", "voice-duration");
    ("voicePitch", "voice-pitch");
    ("voiceRange", "voice-range");
    ("voiceRate", "voice-rate");
    ("voiceStress", "voice-stress");
    ("voiceVolume", "voice-volume");
    ("objectFit", "object-fit");
    ("objectPosition", "object-position");
    ("imageResolution", "image-resolution");
    ("imageOrientation", "image-orientation");
    ("alignContent", "align-content");
    ("alignItems", "align-items");
    ("alignSelf", "align-self");
    ("flex", "flex");
    ("flexBasis", "flex-basis");
    ("flexDirection", "flex-direction");
    ("flexFlow", "flex-flow");
    ("flexGrow", "flex-grow");
    ("flexShrink", "flex-shrink");
    ("flexWrap", "flex-wrap");
    ("justifyContent", "justify-content");
    ("order", "order");
    ("textDecorationColor", "text-decoration-color");
    ("textDecorationLine", "text-decoration-line");
    ("textDecorationSkip", "text-decoration-skip");
    ("textDecorationStyle", "text-decoration-style");
    ("textEmphasis", "text-emphasis");
    ("textEmphasisColor", "text-emphasis-color");
    ("textEmphasisPosition", "text-emphasis-position");
    ("textEmphasisStyle", "text-emphasis-style");
    ("textUnderlinePosition", "text-underline-position");
    ("fontFeatureSettings", "font-feature-settings");
    ("fontKerning", "font-kerning");
    ("fontLanguageOverride", "font-language-override");
    ("fontSynthesis", "font-synthesis");
    ("forntVariantAlternates", "fornt-variant-alternates");
    ("fontVariantCaps", "font-variant-caps");
    ("fontVariantEastAsian", "font-variant-east-asian");
    ("fontVariantLigatures", "font-variant-ligatures");
    ("fontVariantNumeric", "font-variant-numeric");
    ("fontVariantPosition", "font-variant-position");
    ("all", "all");
    ("textCombineUpright", "text-combine-upright");
    ("textOrientation", "text-orientation");
    ("writingMode", "writing-mode");
    ("shapeImageThreshold", "shape-image-threshold");
    ("shapeMargin", "shape-margin");
    ("shapeOutside", "shape-outside");
    ("mask", "mask");
    ("maskBorder", "mask-border");
    ("maskBorderMode", "mask-border-mode");
    ("maskBorderOutset", "mask-border-outset");
    ("maskBorderRepeat", "mask-border-repeat");
    ("maskBorderSlice", "mask-border-slice");
    ("maskBorderSource", "mask-border-source");
    ("maskBorderWidth", "mask-border-width");
    ("maskClip", "mask-clip");
    ("maskComposite", "mask-composite");
    ("maskImage", "mask-image");
    ("maskMode", "mask-mode");
    ("maskOrigin", "mask-origin");
    ("maskPosition", "mask-position");
    ("maskRepeat", "mask-repeat");
    ("maskSize", "mask-size");
    ("maskType", "mask-type");
    ("backgroundBlendMode", "background-blend-mode");
    ("isolation", "isolation");
    ("mixBlendMode", "mix-blend-mode");
    ("boxDecorationBreak", "box-decoration-break");
    ("boxSizing", "box-sizing");
    ("caretColor", "caret-color");
    ("navDown", "nav-down");
    ("navLeft", "nav-left");
    ("navRight", "nav-right");
    ("navUp", "nav-up");
    ("outlineOffset", "outline-offset");
    ("resize", "resize");
    ("textOverflow", "text-overflow");
    ("grid", "grid");
    ("gridArea", "grid-area");
    ("gridAutoColumns", "grid-auto-columns");
    ("gridAutoFlow", "grid-auto-flow");
    ("gridAutoRows", "grid-auto-rows");
    ("gridColumn", "grid-column");
    ("gridColumnEnd", "grid-column-end");
    ("gridColumnGap", "grid-column-gap");
    ("gridColumnStart", "grid-column-start");
    ("gridGap", "grid-gap");
    ("gridRow", "grid-row");
    ("gridRowEnd", "grid-row-end");
    ("gridRowGap", "grid-row-gap");
    ("gridRowStart", "grid-row-start");
    ("gridTemplate", "grid-template");
    ("gridTemplateAreas", "grid-template-areas");
    ("gridTemplateColumns", "grid-template-columns");
    ("gridTemplateRows", "grid-template-rows");
    ("willChange", "will-change");
    ("hangingPunctuation", "hanging-punctuation");
    ("hyphens", "hyphens");
    ("lineBreak", "line-break");
    ("overflowWrap", "overflow-wrap");
    ("tabSize", "tab-size");
    ("textAlignLast", "text-align-last");
    ("textJustify", "text-justify");
    ("wordBreak", "word-break");
    ("wordWrap", "word-wrap");
    ("animation", "animation");
    ("animationDelay", "animation-delay");
    ("animationDirection", "animation-direction");
    ("animationDuration", "animation-duration");
    ("animationFillMode", "animation-fill-mode");
    ("animationIterationCount", "animation-iteration-count");
    ("animationName", "animation-name");
    ("animationPlayState", "animation-play-state");
    ("animationTimingFunction", "animation-timing-function");
    ("transition", "transition");
    ("transitionDelay", "transition-delay");
    ("transitionDuration", "transition-duration");
    ("transitionProperty", "transition-property");
    ("transitionTimingFunction", "transition-timing-function");
    ("backfaceVisibility", "backface-visibility");
    ("perspective", "perspective");
    ("perspectiveOrigin", "perspective-origin");
    ("transform", "transform");
    ("transformOrigin", "transform-origin");
    ("transformStyle", "transform-style");
    ("justifyItems", "justify-items");
    ("justifySelf", "justify-self");
    ("placeContent", "place-content");
    ("placeItems", "place-items");
    ("placeSelf", "place-self");
    ("appearance", "appearance");
    ("caret", "caret");
    ("caretAnimation", "caret-animation");
    ("caretShape", "caret-shape");
    ("userSelect", "user-select");
    ("maxLines", "max-lines");
    ("marqueeDirection", "marquee-direction");
    ("marqueeLoop", "marquee-loop");
    ("marqueeSpeed", "marquee-speed");
    ("marqueeStyle", "marquee-style");
    ("overflowStyle", "overflow-style");
    ("rotation", "rotation");
    ("rotationPoint", "rotation-point");
    ("alignmentBaseline", "alignment-baseline");
    ("baselineShift", "baseline-shift");
    ("clip", "clip");
    ("clipPath", "clip-path");
    ("clipRule", "clip-rule");
    ("colorInterpolation", "color-interpolation");
    ("colorInterpolationFilters", "color-interpolation-filters");
    ("colorProfile", "color-profile");
    ("colorRendering", "color-rendering");
    ("dominantBaseline", "dominant-baseline");
    ("fill", "fill");
    ("fillOpacity", "fill-opacity");
    ("fillRule", "fill-rule");
    ("filter", "filter");
    ("floodColor", "flood-color");
    ("floodOpacity", "flood-opacity");
    ("glyphOrientationHorizontal", "glyph-orientation-horizontal");
    ("glyphOrientationVertical", "glyph-orientation-vertical");
    ("imageRendering", "image-rendering");
    ("kerning", "kerning");
    ("lightingColor", "lighting-color");
    ("markerEnd", "marker-end");
    ("markerMid", "marker-mid");
    ("markerStart", "marker-start");
    ("pointerEvents", "pointer-events");
    ("shapeRendering", "shape-rendering");
    ("stopColor", "stop-color");
    ("stopOpacity", "stop-opacity");
    ("stroke", "stroke");
    ("strokeDasharray", "stroke-dasharray");
    ("strokeDashoffset", "stroke-dashoffset");
    ("strokeLinecap", "stroke-linecap");
    ("strokeLinejoin", "stroke-linejoin");
    ("strokeMiterlimit", "stroke-miterlimit");
    ("strokeOpacity", "stroke-opacity");
    ("strokeWidth", "stroke-width");
    ("textAnchor", "text-anchor");
    ("textRendering", "text-rendering");
    ("rubyAlign", "ruby-align");
    ("rubyMerge", "ruby-merge");
    ("rubyPosition", "ruby-position");
  ]

(* Assoc of camel -> (kebab, signature_index). *)
let indexed_mapping = List.mapi (fun i (camel, kebab) -> (camel, (kebab, i))) mapping
let find_camel camel = List.assoc_opt camel indexed_mapping

(* Returns true if [longident] is [ReactDOM.Style.make] (possibly prefixed). *)
let is_style_make_ident = function
  | Ldot (Ldot (Lident "ReactDOM", "Style"), "make") -> true
  | Ldot (Lident "Style", "make") -> true (* used inside ReactDOM module *)
  | _ -> false

(* Attempt to rewrite a call [ReactDOM.Style.make ~foo:a ~bar:b ()] to a direct
   list expression. Returns [Some new_expr] on success, [None] otherwise.

   The final arg must be [()] (Nolabel, unit), and there must be no optional
   args and no unknown label names.

   The output list must match the runtime order produced by [Style.make]: items
   appear in reverse-signature-order (because the body prepends in signature
   order, last prepend ends up at head). The visible CSS output then reads
   reverse-signature-order, which tests and the [style_order_matters]
   assertions depend on. *)
let try_rewrite_call ~loc:_ args =
  let rec collect acc = function
    | [] -> None (* missing the final unit *)
    | [ (Nolabel, { pexp_desc = Pexp_construct ({ txt = Lident "()"; _ }, None); _ }) ] -> Some acc
    | (Labelled name, expr) :: rest -> (
        match find_camel name with
        | Some (kebab, idx) -> collect ((idx, name, kebab, expr) :: acc) rest
        | None ->
            (* unknown style name — fall back *)
            None)
    | (Optional _, _) :: _ -> None (* optional arg — fall back *)
    | (Nolabel, _) :: _ -> None (* unexpected positional — fall back *)
  in
  match collect [] args with
  | None -> None
  | Some entries ->
      (* Sort by signature index ascending; since [make]'s body prepends in
         signature order, the resulting list has the last (highest-index) entry
         at the head. We build [head :: ... :: tail] in that order. *)
      let sorted = List.sort (fun (i, _, _, _) (j, _, _, _) -> Int.compare j i) entries in
      let loc = Location.none in
      let list_expr =
        List.fold_right
          (fun (_, camel, kebab, expr) acc ->
            let loc = expr.pexp_loc in
            [%expr ([%e estring ~loc kebab], [%e estring ~loc camel], [%e expr]) :: [%e acc]])
          sorted
          [%expr ([] : (string * string * string) list)]
      in
      Some [%expr ([%e list_expr] : ReactDOM.Style.t)]

(* Top-level rewriter: looks at any [Pexp_apply] and rewrites eligible ones. *)
let rewrite_expression expr =
  match expr.pexp_desc with
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt; _ }; _ }, args) when is_style_make_ident txt -> (
      match try_rewrite_call ~loc:expr.pexp_loc args with Some new_expr -> new_expr | None -> expr)
  | _ -> expr
