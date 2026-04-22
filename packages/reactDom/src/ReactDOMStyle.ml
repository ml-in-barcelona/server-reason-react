type t = (string * string * string) list

[@@@ocamlformat "disable"]

let make
  ?(azimuth : string option)
  ?(background : string option)
  ?(backgroundAttachment : string option)
  ?(backgroundColor : string option)
  ?(backgroundImage : string option)
  ?(backgroundPosition : string option)
  ?(backgroundRepeat : string option)
  ?(border : string option)
  ?(borderCollapse : string option)
  ?(borderColor : string option)
  ?(borderSpacing : string option)
  ?(borderStyle : string option)
  ?(borderTop : string option)
  ?(borderRight : string option)
  ?(borderBottom : string option)
  ?(borderLeft : string option)
  ?(borderTopColor : string option)
  ?(borderRightColor : string option)
  ?(borderBottomColor : string option)
  ?(borderLeftColor : string option)
  ?(borderTopStyle : string option)
  ?(borderRightStyle : string option)
  ?(borderBottomStyle : string option)
  ?(borderLeftStyle : string option)
  ?(borderTopWidth : string option)
  ?(borderRightWidth : string option)
  ?(borderBottomWidth : string option)
  ?(borderLeftWidth : string option)
  ?(borderWidth : string option)
  ?(bottom : string option)
  ?(captionSide : string option)
  ?(clear : string option)
  ?(color : string option)
  ?(content : string option)
  ?(counterIncrement : string option)
  ?(counterReset : string option)
  ?(cue : string option)
  ?(cueAfter : string option)
  ?(cueBefore : string option)
  ?(cursor : string option)
  ?(direction : string option)
  ?(display : string option)
  ?(elevation : string option)
  ?(emptyCells : string option)
  ?(float : string option)
  ?(font : string option)
  ?(fontFamily : string option)
  ?(fontSize : string option)
  ?(fontSizeAdjust : string option)
  ?(fontStretch : string option)
  ?(fontStyle : string option)
  ?(fontVariant : string option)
  ?(fontWeight : string option)
  ?(height : string option)
  ?(left : string option)
  ?(letterSpacing : string option)
  ?(lineHeight : string option)
  ?(listStyle : string option)
  ?(listStyleImage : string option)
  ?(listStylePosition : string option)
  ?(listStyleType : string option)
  ?(margin : string option)
  ?(marginTop : string option)
  ?(marginRight : string option)
  ?(marginBottom : string option)
  ?(marginLeft : string option)
  ?(markerOffset : string option)
  ?(marks : string option)
  ?(maxHeight : string option)
  ?(maxWidth : string option)
  ?(minHeight : string option)
  ?(minWidth : string option)
  ?(orphans : string option)
  ?(outline : string option)
  ?(outlineColor : string option)
  ?(outlineStyle : string option)
  ?(outlineWidth : string option)
  ?(overflow : string option)
  ?(overflowX : string option)
  ?(overflowY : string option)
  ?(padding : string option)
  ?(paddingTop : string option)
  ?(paddingRight : string option)
  ?(paddingBottom : string option)
  ?(paddingLeft : string option)
  ?(page : string option)
  ?(pageBreakAfter : string option)
  ?(pageBreakBefore : string option)
  ?(pageBreakInside : string option)
  ?(pause : string option)
  ?(pauseAfter : string option)
  ?(pauseBefore : string option)
  ?(pitch : string option)
  ?(pitchRange : string option)
  ?(playDuring : string option)
  ?(position : string option)
  ?(quotes : string option)
  ?(richness : string option)
  ?(right : string option)
  ?(size : string option)
  ?(speak : string option)
  ?(speakHeader : string option)
  ?(speakNumeral : string option)
  ?(speakPunctuation : string option)
  ?(speechRate : string option)
  ?(stress : string option)
  ?(tableLayout : string option)
  ?(textAlign : string option)
  ?(textDecoration : string option)
  ?(textIndent : string option)
  ?(textShadow : string option)
  ?(textTransform : string option)
  ?(top : string option)
  ?(unicodeBidi : string option)
  ?(verticalAlign : string option)
  ?(visibility : string option)
  ?(voiceFamily : string option)
  ?(volume : string option)
  ?(whiteSpace : string option)
  ?(widows : string option)
  ?(width : string option)
  ?(wordSpacing : string option)
  ?(zIndex : string option)
  ?(opacity : string option)
  ?(backgroundOrigin : string option)
  ?(backgroundSize : string option)
  ?(backgroundClip : string option)
  ?(borderRadius : string option)
  ?(borderTopLeftRadius : string option)
  ?(borderTopRightRadius : string option)
  ?(borderBottomLeftRadius : string option)
  ?(borderBottomRightRadius : string option)
  ?(borderImage : string option)
  ?(borderImageSource : string option)
  ?(borderImageSlice : string option)
  ?(borderImageWidth : string option)
  ?(borderImageOutset : string option)
  ?(borderImageRepeat : string option)
  ?(boxShadow : string option)
  ?(columns : string option)
  ?(columnCount : string option)
  ?(columnFill : string option)
  ?(columnGap : string option)
  ?(columnRule : string option)
  ?(columnRuleColor : string option)
  ?(columnRuleStyle : string option)
  ?(columnRuleWidth : string option)
  ?(columnSpan : string option)
  ?(columnWidth : string option)
  ?(breakAfter : string option)
  ?(breakBefore : string option)
  ?(breakInside : string option)
  ?(rest : string option)
  ?(restAfter : string option)
  ?(restBefore : string option)
  ?(speakAs : string option)
  ?(voiceBalance : string option)
  ?(voiceDuration : string option)
  ?(voicePitch : string option)
  ?(voiceRange : string option)
  ?(voiceRate : string option)
  ?(voiceStress : string option)
  ?(voiceVolume : string option)
  ?(objectFit : string option)
  ?(objectPosition : string option)
  ?(imageResolution : string option)
  ?(imageOrientation : string option)
  ?(alignContent : string option)
  ?(alignItems : string option)
  ?(alignSelf : string option)
  ?(flex : string option)
  ?(flexBasis : string option)
  ?(flexDirection : string option)
  ?(flexFlow : string option)
  ?(flexGrow : string option)
  ?(flexShrink : string option)
  ?(flexWrap : string option)
  ?(justifyContent : string option)
  ?(order : string option)
  ?(textDecorationColor : string option)
  ?(textDecorationLine : string option)
  ?(textDecorationSkip : string option)
  ?(textDecorationStyle : string option)
  ?(textEmphasis : string option)
  ?(textEmphasisColor : string option)
  ?(textEmphasisPosition : string option)
  ?(textEmphasisStyle : string option)
  ?(textUnderlinePosition : string option)
  ?(fontFeatureSettings : string option)
  ?(fontKerning : string option)
  ?(fontLanguageOverride : string option)
  ?(fontSynthesis : string option)
  ?(forntVariantAlternates : string option)
  ?(fontVariantCaps : string option)
  ?(fontVariantEastAsian : string option)
  ?(fontVariantLigatures : string option)
  ?(fontVariantNumeric : string option)
  ?(fontVariantPosition : string option)
  ?(all : string option)
  ?(textCombineUpright : string option)
  ?(textOrientation : string option)
  ?(writingMode : string option)
  ?(shapeImageThreshold : string option)
  ?(shapeMargin : string option)
  ?(shapeOutside : string option)
  ?(mask : string option)
  ?(maskBorder : string option)
  ?(maskBorderMode : string option)
  ?(maskBorderOutset : string option)
  ?(maskBorderRepeat : string option)
  ?(maskBorderSlice : string option)
  ?(maskBorderSource : string option)
  ?(maskBorderWidth : string option)
  ?(maskClip : string option)
  ?(maskComposite : string option)
  ?(maskImage : string option)
  ?(maskMode : string option)
  ?(maskOrigin : string option)
  ?(maskPosition : string option)
  ?(maskRepeat : string option)
  ?(maskSize : string option)
  ?(maskType : string option)
  ?(backgroundBlendMode : string option)
  ?(isolation : string option)
  ?(mixBlendMode : string option)
  ?(boxDecorationBreak : string option)
  ?(boxSizing : string option)
  ?(caretColor : string option)
  ?(navDown : string option)
  ?(navLeft : string option)
  ?(navRight : string option)
  ?(navUp : string option)
  ?(outlineOffset : string option)
  ?(resize : string option)
  ?(textOverflow : string option)
  ?(grid : string option)
  ?(gridArea : string option)
  ?(gridAutoColumns : string option)
  ?(gridAutoFlow : string option)
  ?(gridAutoRows : string option)
  ?(gridColumn : string option)
  ?(gridColumnEnd : string option)
  ?(gridColumnGap : string option)
  ?(gridColumnStart : string option)
  ?(gridGap : string option)
  ?(gridRow : string option)
  ?(gridRowEnd : string option)
  ?(gridRowGap : string option)
  ?(gridRowStart : string option)
  ?(gridTemplate : string option)
  ?(gridTemplateAreas : string option)
  ?(gridTemplateColumns : string option)
  ?(gridTemplateRows : string option)
  ?(willChange : string option)
  ?(hangingPunctuation : string option)
  ?(hyphens : string option)
  ?(lineBreak : string option)
  ?(overflowWrap : string option)
  ?(tabSize : string option)
  ?(textAlignLast : string option)
  ?(textJustify : string option)
  ?(wordBreak : string option)
  ?(wordWrap : string option)
  ?(animation : string option)
  ?(animationDelay : string option)
  ?(animationDirection : string option)
  ?(animationDuration : string option)
  ?(animationFillMode : string option)
  ?(animationIterationCount : string option)
  ?(animationName : string option)
  ?(animationPlayState : string option)
  ?(animationTimingFunction : string option)
  ?(transition : string option)
  ?(transitionDelay : string option)
  ?(transitionDuration : string option)
  ?(transitionProperty : string option)
  ?(transitionTimingFunction : string option)
  ?(backfaceVisibility : string option)
  ?(perspective : string option)
  ?(perspectiveOrigin : string option)
  ?(transform : string option)
  ?(transformOrigin : string option)
  ?(transformStyle : string option)
  ?(justifyItems : string option)
  ?(justifySelf : string option)
  ?(placeContent : string option)
  ?(placeItems : string option)
  ?(placeSelf : string option)
  ?(appearance : string option)
  ?(caret : string option)
  ?(caretAnimation : string option)
  ?(caretShape : string option)
  ?(userSelect : string option)
  ?(maxLines : string option)
  ?(marqueeDirection : string option)
  ?(marqueeLoop : string option)
  ?(marqueeSpeed : string option)
  ?(marqueeStyle : string option)
  ?(overflowStyle : string option)
  ?(rotation : string option)
  ?(rotationPoint : string option)
  ?(alignmentBaseline : string option)
  ?(baselineShift : string option)
  ?(clip : string option)
  ?(clipPath : string option)
  ?(clipRule : string option)
  ?(colorInterpolation : string option)
  ?(colorInterpolationFilters : string option)
  ?(colorProfile : string option)
  ?(colorRendering : string option)
  ?(dominantBaseline : string option)
  ?(fill : string option)
  ?(fillOpacity : string option)
  ?(fillRule : string option)
  ?(filter : string option)
  ?(floodColor : string option)
  ?(floodOpacity : string option)
  ?(glyphOrientationHorizontal : string option)
  ?(glyphOrientationVertical : string option)
  ?(imageRendering : string option)
  ?(kerning : string option)
  ?(lightingColor : string option)
  ?(markerEnd : string option)
  ?(markerMid : string option)
  ?(markerStart : string option)
  ?(pointerEvents : string option)
  ?(shapeRendering : string option)
  ?(stopColor : string option)
  ?(stopOpacity : string option)
  ?(stroke : string option)
  ?(strokeDasharray : string option)
  ?(strokeDashoffset : string option)
  ?(strokeLinecap : string option)
  ?(strokeLinejoin : string option)
  ?(strokeMiterlimit : string option)
  ?(strokeOpacity : string option)
  ?(strokeWidth : string option)
  ?(textAnchor : string option)
  ?(textRendering : string option)
  ?(rubyAlign : string option)
  ?(rubyMerge : string option)
  ?(rubyPosition : string option)
  () =
  (*
     The order of addition matters since it will need to be the same order as
  the JS object defined in https://github.com/reasonml/reason-react/blob/3327dc214905c4b2863b19807aaac375633645cf/src/dOMStyle.re

  The following shell script can be run from the reason-react repository to generate the calls to "add" below:

  for style in $(cat src/dOMStyle.re | grep "~" | sed 's/.*\~\([^:]*\):.*/\1/'); do
    dashed=$(echo "$style" | sed 's/\([A-Z]\)/-\L\1/g')
    echo "|> add \"$dashed\" $style"
  done
  *)

  let acc = [] in
  let acc = match azimuth with Some v -> ("azimuth", "azimuth", v) :: acc | None -> acc in
  let acc = match background with Some v -> ("background", "background", v) :: acc | None -> acc in
  let acc = match backgroundAttachment with Some v -> ("background-attachment", "backgroundAttachment", v) :: acc | None -> acc in
  let acc = match backgroundColor with Some v -> ("background-color", "backgroundColor", v) :: acc | None -> acc in
  let acc = match backgroundImage with Some v -> ("background-image", "backgroundImage", v) :: acc | None -> acc in
  let acc = match backgroundPosition with Some v -> ("background-position", "backgroundPosition", v) :: acc | None -> acc in
  let acc = match backgroundRepeat with Some v -> ("background-repeat", "backgroundRepeat", v) :: acc | None -> acc in
  let acc = match border with Some v -> ("border", "border", v) :: acc | None -> acc in
  let acc = match borderCollapse with Some v -> ("border-collapse", "borderCollapse", v) :: acc | None -> acc in
  let acc = match borderColor with Some v -> ("border-color", "borderColor", v) :: acc | None -> acc in
  let acc = match borderSpacing with Some v -> ("border-spacing", "borderSpacing", v) :: acc | None -> acc in
  let acc = match borderStyle with Some v -> ("border-style", "borderStyle", v) :: acc | None -> acc in
  let acc = match borderTop with Some v -> ("border-top", "borderTop", v) :: acc | None -> acc in
  let acc = match borderRight with Some v -> ("border-right", "borderRight", v) :: acc | None -> acc in
  let acc = match borderBottom with Some v -> ("border-bottom", "borderBottom", v) :: acc | None -> acc in
  let acc = match borderLeft with Some v -> ("border-left", "borderLeft", v) :: acc | None -> acc in
  let acc = match borderTopColor with Some v -> ("border-top-color", "borderTopColor", v) :: acc | None -> acc in
  let acc = match borderRightColor with Some v -> ("border-right-color", "borderRightColor", v) :: acc | None -> acc in
  let acc = match borderBottomColor with Some v -> ("border-bottom-color", "borderBottomColor", v) :: acc | None -> acc in
  let acc = match borderLeftColor with Some v -> ("border-left-color", "borderLeftColor", v) :: acc | None -> acc in
  let acc = match borderTopStyle with Some v -> ("border-top-style", "borderTopStyle", v) :: acc | None -> acc in
  let acc = match borderRightStyle with Some v -> ("border-right-style", "borderRightStyle", v) :: acc | None -> acc in
  let acc = match borderBottomStyle with Some v -> ("border-bottom-style", "borderBottomStyle", v) :: acc | None -> acc in
  let acc = match borderLeftStyle with Some v -> ("border-left-style", "borderLeftStyle", v) :: acc | None -> acc in
  let acc = match borderTopWidth with Some v -> ("border-top-width", "borderTopWidth", v) :: acc | None -> acc in
  let acc = match borderRightWidth with Some v -> ("border-right-width", "borderRightWidth", v) :: acc | None -> acc in
  let acc = match borderBottomWidth with Some v -> ("border-bottom-width", "borderBottomWidth", v) :: acc | None -> acc in
  let acc = match borderLeftWidth with Some v -> ("border-left-width", "borderLeftWidth", v) :: acc | None -> acc in
  let acc = match borderWidth with Some v -> ("border-width", "borderWidth", v) :: acc | None -> acc in
  let acc = match bottom with Some v -> ("bottom", "bottom", v) :: acc | None -> acc in
  let acc = match captionSide with Some v -> ("caption-side", "captionSide", v) :: acc | None -> acc in
  let acc = match clear with Some v -> ("clear", "clear", v) :: acc | None -> acc in
  let acc = match clip with Some v -> ("clip", "clip", v) :: acc | None -> acc in
  let acc = match color with Some v -> ("color", "color", v) :: acc | None -> acc in
  let acc = match content with Some v -> ("content", "content", v) :: acc | None -> acc in
  let acc = match counterIncrement with Some v -> ("counter-increment", "counterIncrement", v) :: acc | None -> acc in
  let acc = match counterReset with Some v -> ("counter-reset", "counterReset", v) :: acc | None -> acc in
  let acc = match cue with Some v -> ("cue", "cue", v) :: acc | None -> acc in
  let acc = match cueAfter with Some v -> ("cue-after", "cueAfter", v) :: acc | None -> acc in
  let acc = match cueBefore with Some v -> ("cue-before", "cueBefore", v) :: acc | None -> acc in
  let acc = match cursor with Some v -> ("cursor", "cursor", v) :: acc | None -> acc in
  let acc = match direction with Some v -> ("direction", "direction", v) :: acc | None -> acc in
  let acc = match display with Some v -> ("display", "display", v) :: acc | None -> acc in
  let acc = match elevation with Some v -> ("elevation", "elevation", v) :: acc | None -> acc in
  let acc = match emptyCells with Some v -> ("empty-cells", "emptyCells", v) :: acc | None -> acc in
  let acc = match float with Some v -> ("float", "float", v) :: acc | None -> acc in
  let acc = match font with Some v -> ("font", "font", v) :: acc | None -> acc in
  let acc = match fontFamily with Some v -> ("font-family", "fontFamily", v) :: acc | None -> acc in
  let acc = match fontSize with Some v -> ("font-size", "fontSize", v) :: acc | None -> acc in
  let acc = match fontSizeAdjust with Some v -> ("font-size-adjust", "fontSizeAdjust", v) :: acc | None -> acc in
  let acc = match fontStretch with Some v -> ("font-stretch", "fontStretch", v) :: acc | None -> acc in
  let acc = match fontStyle with Some v -> ("font-style", "fontStyle", v) :: acc | None -> acc in
  let acc = match fontVariant with Some v -> ("font-variant", "fontVariant", v) :: acc | None -> acc in
  let acc = match fontWeight with Some v -> ("font-weight", "fontWeight", v) :: acc | None -> acc in
  let acc = match height with Some v -> ("height", "height", v) :: acc | None -> acc in
  let acc = match left with Some v -> ("left", "left", v) :: acc | None -> acc in
  let acc = match letterSpacing with Some v -> ("letter-spacing", "letterSpacing", v) :: acc | None -> acc in
  let acc = match lineHeight with Some v -> ("line-height", "lineHeight", v) :: acc | None -> acc in
  let acc = match listStyle with Some v -> ("list-style", "listStyle", v) :: acc | None -> acc in
  let acc = match listStyleImage with Some v -> ("list-style-image", "listStyleImage", v) :: acc | None -> acc in
  let acc = match listStylePosition with Some v -> ("list-style-position", "listStylePosition", v) :: acc | None -> acc in
  let acc = match listStyleType with Some v -> ("list-style-type", "listStyleType", v) :: acc | None -> acc in
  let acc = match margin with Some v -> ("margin", "margin", v) :: acc | None -> acc in
  let acc = match marginTop with Some v -> ("margin-top", "marginTop", v) :: acc | None -> acc in
  let acc = match marginRight with Some v -> ("margin-right", "marginRight", v) :: acc | None -> acc in
  let acc = match marginBottom with Some v -> ("margin-bottom", "marginBottom", v) :: acc | None -> acc in
  let acc = match marginLeft with Some v -> ("margin-left", "marginLeft", v) :: acc | None -> acc in
  let acc = match markerOffset with Some v -> ("marker-offset", "markerOffset", v) :: acc | None -> acc in
  let acc = match marks with Some v -> ("marks", "marks", v) :: acc | None -> acc in
  let acc = match maxHeight with Some v -> ("max-height", "maxHeight", v) :: acc | None -> acc in
  let acc = match maxWidth with Some v -> ("max-width", "maxWidth", v) :: acc | None -> acc in
  let acc = match minHeight with Some v -> ("min-height", "minHeight", v) :: acc | None -> acc in
  let acc = match minWidth with Some v -> ("min-width", "minWidth", v) :: acc | None -> acc in
  let acc = match orphans with Some v -> ("orphans", "orphans", v) :: acc | None -> acc in
  let acc = match outline with Some v -> ("outline", "outline", v) :: acc | None -> acc in
  let acc = match outlineColor with Some v -> ("outline-color", "outlineColor", v) :: acc | None -> acc in
  let acc = match outlineStyle with Some v -> ("outline-style", "outlineStyle", v) :: acc | None -> acc in
  let acc = match outlineWidth with Some v -> ("outline-width", "outlineWidth", v) :: acc | None -> acc in
  let acc = match overflow with Some v -> ("overflow", "overflow", v) :: acc | None -> acc in
  let acc = match overflowX with Some v -> ("overflow-x", "overflowX", v) :: acc | None -> acc in
  let acc = match overflowY with Some v -> ("overflow-y", "overflowY", v) :: acc | None -> acc in
  let acc = match padding with Some v -> ("padding", "padding", v) :: acc | None -> acc in
  let acc = match paddingTop with Some v -> ("padding-top", "paddingTop", v) :: acc | None -> acc in
  let acc = match paddingRight with Some v -> ("padding-right", "paddingRight", v) :: acc | None -> acc in
  let acc = match paddingBottom with Some v -> ("padding-bottom", "paddingBottom", v) :: acc | None -> acc in
  let acc = match paddingLeft with Some v -> ("padding-left", "paddingLeft", v) :: acc | None -> acc in
  let acc = match page with Some v -> ("page", "page", v) :: acc | None -> acc in
  let acc = match pageBreakAfter with Some v -> ("page-break-after", "pageBreakAfter", v) :: acc | None -> acc in
  let acc = match pageBreakBefore with Some v -> ("page-break-before", "pageBreakBefore", v) :: acc | None -> acc in
  let acc = match pageBreakInside with Some v -> ("page-break-inside", "pageBreakInside", v) :: acc | None -> acc in
  let acc = match pause with Some v -> ("pause", "pause", v) :: acc | None -> acc in
  let acc = match pauseAfter with Some v -> ("pause-after", "pauseAfter", v) :: acc | None -> acc in
  let acc = match pauseBefore with Some v -> ("pause-before", "pauseBefore", v) :: acc | None -> acc in
  let acc = match pitch with Some v -> ("pitch", "pitch", v) :: acc | None -> acc in
  let acc = match pitchRange with Some v -> ("pitch-range", "pitchRange", v) :: acc | None -> acc in
  let acc = match playDuring with Some v -> ("play-during", "playDuring", v) :: acc | None -> acc in
  let acc = match position with Some v -> ("position", "position", v) :: acc | None -> acc in
  let acc = match quotes with Some v -> ("quotes", "quotes", v) :: acc | None -> acc in
  let acc = match richness with Some v -> ("richness", "richness", v) :: acc | None -> acc in
  let acc = match right with Some v -> ("right", "right", v) :: acc | None -> acc in
  let acc = match size with Some v -> ("size", "size", v) :: acc | None -> acc in
  let acc = match speak with Some v -> ("speak", "speak", v) :: acc | None -> acc in
  let acc = match speakHeader with Some v -> ("speak-header", "speakHeader", v) :: acc | None -> acc in
  let acc = match speakNumeral with Some v -> ("speak-numeral", "speakNumeral", v) :: acc | None -> acc in
  let acc = match speakPunctuation with Some v -> ("speak-punctuation", "speakPunctuation", v) :: acc | None -> acc in
  let acc = match speechRate with Some v -> ("speech-rate", "speechRate", v) :: acc | None -> acc in
  let acc = match stress with Some v -> ("stress", "stress", v) :: acc | None -> acc in
  let acc = match tableLayout with Some v -> ("table-layout", "tableLayout", v) :: acc | None -> acc in
  let acc = match textAlign with Some v -> ("text-align", "textAlign", v) :: acc | None -> acc in
  let acc = match textDecoration with Some v -> ("text-decoration", "textDecoration", v) :: acc | None -> acc in
  let acc = match textIndent with Some v -> ("text-indent", "textIndent", v) :: acc | None -> acc in
  let acc = match textShadow with Some v -> ("text-shadow", "textShadow", v) :: acc | None -> acc in
  let acc = match textTransform with Some v -> ("text-transform", "textTransform", v) :: acc | None -> acc in
  let acc = match top with Some v -> ("top", "top", v) :: acc | None -> acc in
  let acc = match unicodeBidi with Some v -> ("unicode-bidi", "unicodeBidi", v) :: acc | None -> acc in
  let acc = match verticalAlign with Some v -> ("vertical-align", "verticalAlign", v) :: acc | None -> acc in
  let acc = match visibility with Some v -> ("visibility", "visibility", v) :: acc | None -> acc in
  let acc = match voiceFamily with Some v -> ("voice-family", "voiceFamily", v) :: acc | None -> acc in
  let acc = match volume with Some v -> ("volume", "volume", v) :: acc | None -> acc in
  let acc = match whiteSpace with Some v -> ("white-space", "whiteSpace", v) :: acc | None -> acc in
  let acc = match widows with Some v -> ("widows", "widows", v) :: acc | None -> acc in
  let acc = match width with Some v -> ("width", "width", v) :: acc | None -> acc in
  let acc = match wordSpacing with Some v -> ("word-spacing", "wordSpacing", v) :: acc | None -> acc in
  let acc = match zIndex with Some v -> ("z-index", "zIndex", v) :: acc | None -> acc in
  let acc = match opacity with Some v -> ("opacity", "opacity", v) :: acc | None -> acc in
  let acc = match backgroundOrigin with Some v -> ("background-origin", "backgroundOrigin", v) :: acc | None -> acc in
  let acc = match backgroundSize with Some v -> ("background-size", "backgroundSize", v) :: acc | None -> acc in
  let acc = match backgroundClip with Some v -> ("background-clip", "backgroundClip", v) :: acc | None -> acc in
  let acc = match borderRadius with Some v -> ("border-radius", "borderRadius", v) :: acc | None -> acc in
  let acc = match borderTopLeftRadius with Some v -> ("border-top-left-radius", "borderTopLeftRadius", v) :: acc | None -> acc in
  let acc = match borderTopRightRadius with Some v -> ("border-top-right-radius", "borderTopRightRadius", v) :: acc | None -> acc in
  let acc = match borderBottomLeftRadius with Some v -> ("border-bottom-left-radius", "borderBottomLeftRadius", v) :: acc | None -> acc in
  let acc = match borderBottomRightRadius with Some v -> ("border-bottom-right-radius", "borderBottomRightRadius", v) :: acc | None -> acc in
  let acc = match borderImage with Some v -> ("border-image", "borderImage", v) :: acc | None -> acc in
  let acc = match borderImageSource with Some v -> ("border-image-source", "borderImageSource", v) :: acc | None -> acc in
  let acc = match borderImageSlice with Some v -> ("border-image-slice", "borderImageSlice", v) :: acc | None -> acc in
  let acc = match borderImageWidth with Some v -> ("border-image-width", "borderImageWidth", v) :: acc | None -> acc in
  let acc = match borderImageOutset with Some v -> ("border-image-outset", "borderImageOutset", v) :: acc | None -> acc in
  let acc = match borderImageRepeat with Some v -> ("border-image-repeat", "borderImageRepeat", v) :: acc | None -> acc in
  let acc = match boxShadow with Some v -> ("box-shadow", "boxShadow", v) :: acc | None -> acc in
  let acc = match columns with Some v -> ("columns", "columns", v) :: acc | None -> acc in
  let acc = match columnCount with Some v -> ("column-count", "columnCount", v) :: acc | None -> acc in
  let acc = match columnFill with Some v -> ("column-fill", "columnFill", v) :: acc | None -> acc in
  let acc = match columnGap with Some v -> ("column-gap", "columnGap", v) :: acc | None -> acc in
  let acc = match columnRule with Some v -> ("column-rule", "columnRule", v) :: acc | None -> acc in
  let acc = match columnRuleColor with Some v -> ("column-rule-color", "columnRuleColor", v) :: acc | None -> acc in
  let acc = match columnRuleStyle with Some v -> ("column-rule-style", "columnRuleStyle", v) :: acc | None -> acc in
  let acc = match columnRuleWidth with Some v -> ("column-rule-width", "columnRuleWidth", v) :: acc | None -> acc in
  let acc = match columnSpan with Some v -> ("column-span", "columnSpan", v) :: acc | None -> acc in
  let acc = match columnWidth with Some v -> ("column-width", "columnWidth", v) :: acc | None -> acc in
  let acc = match breakAfter with Some v -> ("break-after", "breakAfter", v) :: acc | None -> acc in
  let acc = match breakBefore with Some v -> ("break-before", "breakBefore", v) :: acc | None -> acc in
  let acc = match breakInside with Some v -> ("break-inside", "breakInside", v) :: acc | None -> acc in
  let acc = match rest with Some v -> ("rest", "rest", v) :: acc | None -> acc in
  let acc = match restAfter with Some v -> ("rest-after", "restAfter", v) :: acc | None -> acc in
  let acc = match restBefore with Some v -> ("rest-before", "restBefore", v) :: acc | None -> acc in
  let acc = match speakAs with Some v -> ("speak-as", "speakAs", v) :: acc | None -> acc in
  let acc = match voiceBalance with Some v -> ("voice-balance", "voiceBalance", v) :: acc | None -> acc in
  let acc = match voiceDuration with Some v -> ("voice-duration", "voiceDuration", v) :: acc | None -> acc in
  let acc = match voicePitch with Some v -> ("voice-pitch", "voicePitch", v) :: acc | None -> acc in
  let acc = match voiceRange with Some v -> ("voice-range", "voiceRange", v) :: acc | None -> acc in
  let acc = match voiceRate with Some v -> ("voice-rate", "voiceRate", v) :: acc | None -> acc in
  let acc = match voiceStress with Some v -> ("voice-stress", "voiceStress", v) :: acc | None -> acc in
  let acc = match voiceVolume with Some v -> ("voice-volume", "voiceVolume", v) :: acc | None -> acc in
  let acc = match objectFit with Some v -> ("object-fit", "objectFit", v) :: acc | None -> acc in
  let acc = match objectPosition with Some v -> ("object-position", "objectPosition", v) :: acc | None -> acc in
  let acc = match imageResolution with Some v -> ("image-resolution", "imageResolution", v) :: acc | None -> acc in
  let acc = match imageOrientation with Some v -> ("image-orientation", "imageOrientation", v) :: acc | None -> acc in
  let acc = match alignContent with Some v -> ("align-content", "alignContent", v) :: acc | None -> acc in
  let acc = match alignItems with Some v -> ("align-items", "alignItems", v) :: acc | None -> acc in
  let acc = match alignSelf with Some v -> ("align-self", "alignSelf", v) :: acc | None -> acc in
  let acc = match flex with Some v -> ("flex", "flex", v) :: acc | None -> acc in
  let acc = match flexBasis with Some v -> ("flex-basis", "flexBasis", v) :: acc | None -> acc in
  let acc = match flexDirection with Some v -> ("flex-direction", "flexDirection", v) :: acc | None -> acc in
  let acc = match flexFlow with Some v -> ("flex-flow", "flexFlow", v) :: acc | None -> acc in
  let acc = match flexGrow with Some v -> ("flex-grow", "flexGrow", v) :: acc | None -> acc in
  let acc = match flexShrink with Some v -> ("flex-shrink", "flexShrink", v) :: acc | None -> acc in
  let acc = match flexWrap with Some v -> ("flex-wrap", "flexWrap", v) :: acc | None -> acc in
  let acc = match justifyContent with Some v -> ("justify-content", "justifyContent", v) :: acc | None -> acc in
  let acc = match order with Some v -> ("order", "order", v) :: acc | None -> acc in
  let acc = match textDecorationColor with Some v -> ("text-decoration-color", "textDecorationColor", v) :: acc | None -> acc in
  let acc = match textDecorationLine with Some v -> ("text-decoration-line", "textDecorationLine", v) :: acc | None -> acc in
  let acc = match textDecorationSkip with Some v -> ("text-decoration-skip", "textDecorationSkip", v) :: acc | None -> acc in
  let acc = match textDecorationStyle with Some v -> ("text-decoration-style", "textDecorationStyle", v) :: acc | None -> acc in
  let acc = match textEmphasis with Some v -> ("text-emphasis", "textEmphasis", v) :: acc | None -> acc in
  let acc = match textEmphasisColor with Some v -> ("text-emphasis-color", "textEmphasisColor", v) :: acc | None -> acc in
  let acc = match textEmphasisPosition with Some v -> ("text-emphasis-position", "textEmphasisPosition", v) :: acc | None -> acc in
  let acc = match textEmphasisStyle with Some v -> ("text-emphasis-style", "textEmphasisStyle", v) :: acc | None -> acc in
  let acc = match textUnderlinePosition with Some v -> ("text-underline-position", "textUnderlinePosition", v) :: acc | None -> acc in
  let acc = match fontFeatureSettings with Some v -> ("font-feature-settings", "fontFeatureSettings", v) :: acc | None -> acc in
  let acc = match fontKerning with Some v -> ("font-kerning", "fontKerning", v) :: acc | None -> acc in
  let acc = match fontLanguageOverride with Some v -> ("font-language-override", "fontLanguageOverride", v) :: acc | None -> acc in
  let acc = match fontSynthesis with Some v -> ("font-synthesis", "fontSynthesis", v) :: acc | None -> acc in
  let acc = match forntVariantAlternates with Some v -> ("fornt-variant-alternates", "forntVariantAlternates", v) :: acc | None -> acc in
  let acc = match fontVariantCaps with Some v -> ("font-variant-caps", "fontVariantCaps", v) :: acc | None -> acc in
  let acc = match fontVariantEastAsian with Some v -> ("font-variant-east-asian", "fontVariantEastAsian", v) :: acc | None -> acc in
  let acc = match fontVariantLigatures with Some v -> ("font-variant-ligatures", "fontVariantLigatures", v) :: acc | None -> acc in
  let acc = match fontVariantNumeric with Some v -> ("font-variant-numeric", "fontVariantNumeric", v) :: acc | None -> acc in
  let acc = match fontVariantPosition with Some v -> ("font-variant-position", "fontVariantPosition", v) :: acc | None -> acc in
  let acc = match all with Some v -> ("all", "all", v) :: acc | None -> acc in
  let acc = match glyphOrientationVertical with Some v -> ("glyph-orientation-vertical", "glyphOrientationVertical", v) :: acc | None -> acc in
  let acc = match textCombineUpright with Some v -> ("text-combine-upright", "textCombineUpright", v) :: acc | None -> acc in
  let acc = match textOrientation with Some v -> ("text-orientation", "textOrientation", v) :: acc | None -> acc in
  let acc = match writingMode with Some v -> ("writing-mode", "writingMode", v) :: acc | None -> acc in
  let acc = match shapeImageThreshold with Some v -> ("shape-image-threshold", "shapeImageThreshold", v) :: acc | None -> acc in
  let acc = match shapeMargin with Some v -> ("shape-margin", "shapeMargin", v) :: acc | None -> acc in
  let acc = match shapeOutside with Some v -> ("shape-outside", "shapeOutside", v) :: acc | None -> acc in
  let acc = match clipPath with Some v -> ("clip-path", "clipPath", v) :: acc | None -> acc in
  let acc = match clipRule with Some v -> ("clip-rule", "clipRule", v) :: acc | None -> acc in
  let acc = match mask with Some v -> ("mask", "mask", v) :: acc | None -> acc in
  let acc = match maskBorder with Some v -> ("mask-border", "maskBorder", v) :: acc | None -> acc in
  let acc = match maskBorderMode with Some v -> ("mask-border-mode", "maskBorderMode", v) :: acc | None -> acc in
  let acc = match maskBorderOutset with Some v -> ("mask-border-outset", "maskBorderOutset", v) :: acc | None -> acc in
  let acc = match maskBorderRepeat with Some v -> ("mask-border-repeat", "maskBorderRepeat", v) :: acc | None -> acc in
  let acc = match maskBorderSlice with Some v -> ("mask-border-slice", "maskBorderSlice", v) :: acc | None -> acc in
  let acc = match maskBorderSource with Some v -> ("mask-border-source", "maskBorderSource", v) :: acc | None -> acc in
  let acc = match maskBorderWidth with Some v -> ("mask-border-width", "maskBorderWidth", v) :: acc | None -> acc in
  let acc = match maskClip with Some v -> ("mask-clip", "maskClip", v) :: acc | None -> acc in
  let acc = match maskComposite with Some v -> ("mask-composite", "maskComposite", v) :: acc | None -> acc in
  let acc = match maskImage with Some v -> ("mask-image", "maskImage", v) :: acc | None -> acc in
  let acc = match maskMode with Some v -> ("mask-mode", "maskMode", v) :: acc | None -> acc in
  let acc = match maskOrigin with Some v -> ("mask-origin", "maskOrigin", v) :: acc | None -> acc in
  let acc = match maskPosition with Some v -> ("mask-position", "maskPosition", v) :: acc | None -> acc in
  let acc = match maskRepeat with Some v -> ("mask-repeat", "maskRepeat", v) :: acc | None -> acc in
  let acc = match maskSize with Some v -> ("mask-size", "maskSize", v) :: acc | None -> acc in
  let acc = match maskType with Some v -> ("mask-type", "maskType", v) :: acc | None -> acc in
  let acc = match backgroundBlendMode with Some v -> ("background-blend-mode", "backgroundBlendMode", v) :: acc | None -> acc in
  let acc = match isolation with Some v -> ("isolation", "isolation", v) :: acc | None -> acc in
  let acc = match mixBlendMode with Some v -> ("mix-blend-mode", "mixBlendMode", v) :: acc | None -> acc in
  let acc = match boxDecorationBreak with Some v -> ("box-decoration-break", "boxDecorationBreak", v) :: acc | None -> acc in
  let acc = match boxSizing with Some v -> ("box-sizing", "boxSizing", v) :: acc | None -> acc in
  let acc = match caretColor with Some v -> ("caret-color", "caretColor", v) :: acc | None -> acc in
  let acc = match navDown with Some v -> ("nav-down", "navDown", v) :: acc | None -> acc in
  let acc = match navLeft with Some v -> ("nav-left", "navLeft", v) :: acc | None -> acc in
  let acc = match navRight with Some v -> ("nav-right", "navRight", v) :: acc | None -> acc in
  let acc = match navUp with Some v -> ("nav-up", "navUp", v) :: acc | None -> acc in
  let acc = match outlineOffset with Some v -> ("outline-offset", "outlineOffset", v) :: acc | None -> acc in
  let acc = match resize with Some v -> ("resize", "resize", v) :: acc | None -> acc in
  let acc = match textOverflow with Some v -> ("text-overflow", "textOverflow", v) :: acc | None -> acc in
  let acc = match grid with Some v -> ("grid", "grid", v) :: acc | None -> acc in
  let acc = match gridArea with Some v -> ("grid-area", "gridArea", v) :: acc | None -> acc in
  let acc = match gridAutoColumns with Some v -> ("grid-auto-columns", "gridAutoColumns", v) :: acc | None -> acc in
  let acc = match gridAutoFlow with Some v -> ("grid-auto-flow", "gridAutoFlow", v) :: acc | None -> acc in
  let acc = match gridAutoRows with Some v -> ("grid-auto-rows", "gridAutoRows", v) :: acc | None -> acc in
  let acc = match gridColumn with Some v -> ("grid-column", "gridColumn", v) :: acc | None -> acc in
  let acc = match gridColumnEnd with Some v -> ("grid-column-end", "gridColumnEnd", v) :: acc | None -> acc in
  let acc = match gridColumnGap with Some v -> ("grid-column-gap", "gridColumnGap", v) :: acc | None -> acc in
  let acc = match gridColumnStart with Some v -> ("grid-column-start", "gridColumnStart", v) :: acc | None -> acc in
  let acc = match gridGap with Some v -> ("grid-gap", "gridGap", v) :: acc | None -> acc in
  let acc = match gridRow with Some v -> ("grid-row", "gridRow", v) :: acc | None -> acc in
  let acc = match gridRowEnd with Some v -> ("grid-row-end", "gridRowEnd", v) :: acc | None -> acc in
  let acc = match gridRowGap with Some v -> ("grid-row-gap", "gridRowGap", v) :: acc | None -> acc in
  let acc = match gridRowStart with Some v -> ("grid-row-start", "gridRowStart", v) :: acc | None -> acc in
  let acc = match gridTemplate with Some v -> ("grid-template", "gridTemplate", v) :: acc | None -> acc in
  let acc = match gridTemplateAreas with Some v -> ("grid-template-areas", "gridTemplateAreas", v) :: acc | None -> acc in
  let acc = match gridTemplateColumns with Some v -> ("grid-template-columns", "gridTemplateColumns", v) :: acc | None -> acc in
  let acc = match gridTemplateRows with Some v -> ("grid-template-rows", "gridTemplateRows", v) :: acc | None -> acc in
  let acc = match willChange with Some v -> ("will-change", "willChange", v) :: acc | None -> acc in
  let acc = match hangingPunctuation with Some v -> ("hanging-punctuation", "hangingPunctuation", v) :: acc | None -> acc in
  let acc = match hyphens with Some v -> ("hyphens", "hyphens", v) :: acc | None -> acc in
  let acc = match lineBreak with Some v -> ("line-break", "lineBreak", v) :: acc | None -> acc in
  let acc = match overflowWrap with Some v -> ("overflow-wrap", "overflowWrap", v) :: acc | None -> acc in
  let acc = match tabSize with Some v -> ("tab-size", "tabSize", v) :: acc | None -> acc in
  let acc = match textAlignLast with Some v -> ("text-align-last", "textAlignLast", v) :: acc | None -> acc in
  let acc = match textJustify with Some v -> ("text-justify", "textJustify", v) :: acc | None -> acc in
  let acc = match wordBreak with Some v -> ("word-break", "wordBreak", v) :: acc | None -> acc in
  let acc = match wordWrap with Some v -> ("word-wrap", "wordWrap", v) :: acc | None -> acc in
  let acc = match animation with Some v -> ("animation", "animation", v) :: acc | None -> acc in
  let acc = match animationDelay with Some v -> ("animation-delay", "animationDelay", v) :: acc | None -> acc in
  let acc = match animationDirection with Some v -> ("animation-direction", "animationDirection", v) :: acc | None -> acc in
  let acc = match animationDuration with Some v -> ("animation-duration", "animationDuration", v) :: acc | None -> acc in
  let acc = match animationFillMode with Some v -> ("animation-fill-mode", "animationFillMode", v) :: acc | None -> acc in
  let acc = match animationIterationCount with Some v -> ("animation-iteration-count", "animationIterationCount", v) :: acc | None -> acc in
  let acc = match animationName with Some v -> ("animation-name", "animationName", v) :: acc | None -> acc in
  let acc = match animationPlayState with Some v -> ("animation-play-state", "animationPlayState", v) :: acc | None -> acc in
  let acc = match animationTimingFunction with Some v -> ("animation-timing-function", "animationTimingFunction", v) :: acc | None -> acc in
  let acc = match transition with Some v -> ("transition", "transition", v) :: acc | None -> acc in
  let acc = match transitionDelay with Some v -> ("transition-delay", "transitionDelay", v) :: acc | None -> acc in
  let acc = match transitionDuration with Some v -> ("transition-duration", "transitionDuration", v) :: acc | None -> acc in
  let acc = match transitionProperty with Some v -> ("transition-property", "transitionProperty", v) :: acc | None -> acc in
  let acc = match transitionTimingFunction with Some v -> ("transition-timing-function", "transitionTimingFunction", v) :: acc | None -> acc in
  let acc = match backfaceVisibility with Some v -> ("backface-visibility", "backfaceVisibility", v) :: acc | None -> acc in
  let acc = match perspective with Some v -> ("perspective", "perspective", v) :: acc | None -> acc in
  let acc = match perspectiveOrigin with Some v -> ("perspective-origin", "perspectiveOrigin", v) :: acc | None -> acc in
  let acc = match transform with Some v -> ("transform", "transform", v) :: acc | None -> acc in
  let acc = match transformOrigin with Some v -> ("transform-origin", "transformOrigin", v) :: acc | None -> acc in
  let acc = match transformStyle with Some v -> ("transform-style", "transformStyle", v) :: acc | None -> acc in
  let acc = match justifyItems with Some v -> ("justify-items", "justifyItems", v) :: acc | None -> acc in
  let acc = match justifySelf with Some v -> ("justify-self", "justifySelf", v) :: acc | None -> acc in
  let acc = match placeContent with Some v -> ("place-content", "placeContent", v) :: acc | None -> acc in
  let acc = match placeItems with Some v -> ("place-items", "placeItems", v) :: acc | None -> acc in
  let acc = match placeSelf with Some v -> ("place-self", "placeSelf", v) :: acc | None -> acc in
  let acc = match appearance with Some v -> ("appearance", "appearance", v) :: acc | None -> acc in
  let acc = match caret with Some v -> ("caret", "caret", v) :: acc | None -> acc in
  let acc = match caretAnimation with Some v -> ("caret-animation", "caretAnimation", v) :: acc | None -> acc in
  let acc = match caretShape with Some v -> ("caret-shape", "caretShape", v) :: acc | None -> acc in
  let acc = match userSelect with Some v -> ("user-select", "userSelect", v) :: acc | None -> acc in
  let acc = match maxLines with Some v -> ("max-lines", "maxLines", v) :: acc | None -> acc in
  let acc = match marqueeDirection with Some v -> ("marquee-direction", "marqueeDirection", v) :: acc | None -> acc in
  let acc = match marqueeLoop with Some v -> ("marquee-loop", "marqueeLoop", v) :: acc | None -> acc in
  let acc = match marqueeSpeed with Some v -> ("marquee-speed", "marqueeSpeed", v) :: acc | None -> acc in
  let acc = match marqueeStyle with Some v -> ("marquee-style", "marqueeStyle", v) :: acc | None -> acc in
  let acc = match overflowStyle with Some v -> ("overflow-style", "overflowStyle", v) :: acc | None -> acc in
  let acc = match rotation with Some v -> ("rotation", "rotation", v) :: acc | None -> acc in
  let acc = match rotationPoint with Some v -> ("rotation-point", "rotationPoint", v) :: acc | None -> acc in
  let acc = match alignmentBaseline with Some v -> ("alignment-baseline", "alignmentBaseline", v) :: acc | None -> acc in
  let acc = match baselineShift with Some v -> ("baseline-shift", "baselineShift", v) :: acc | None -> acc in
  let acc = match clip with Some v -> ("clip", "clip", v) :: acc | None -> acc in
  let acc = match clipPath with Some v -> ("clip-path", "clipPath", v) :: acc | None -> acc in
  let acc = match clipRule with Some v -> ("clip-rule", "clipRule", v) :: acc | None -> acc in
  let acc = match colorInterpolation with Some v -> ("color-interpolation", "colorInterpolation", v) :: acc | None -> acc in
  let acc = match colorInterpolationFilters with Some v -> ("color-interpolation-filters", "colorInterpolationFilters", v) :: acc | None -> acc in
  let acc = match colorProfile with Some v -> ("color-profile", "colorProfile", v) :: acc | None -> acc in
  let acc = match colorRendering with Some v -> ("color-rendering", "colorRendering", v) :: acc | None -> acc in
  let acc = match cursor with Some v -> ("cursor", "cursor", v) :: acc | None -> acc in
  let acc = match dominantBaseline with Some v -> ("dominant-baseline", "dominantBaseline", v) :: acc | None -> acc in
  let acc = match fill with Some v -> ("fill", "fill", v) :: acc | None -> acc in
  let acc = match fillOpacity with Some v -> ("fill-opacity", "fillOpacity", v) :: acc | None -> acc in
  let acc = match fillRule with Some v -> ("fill-rule", "fillRule", v) :: acc | None -> acc in
  let acc = match filter with Some v -> ("filter", "filter", v) :: acc | None -> acc in
  let acc = match floodColor with Some v -> ("flood-color", "floodColor", v) :: acc | None -> acc in
  let acc = match floodOpacity with Some v -> ("flood-opacity", "floodOpacity", v) :: acc | None -> acc in
  let acc = match glyphOrientationHorizontal with Some v -> ("glyph-orientation-horizontal", "glyphOrientationHorizontal", v) :: acc | None -> acc in
  let acc = match glyphOrientationVertical with Some v -> ("glyph-orientation-vertical", "glyphOrientationVertical", v) :: acc | None -> acc in
  let acc = match imageRendering with Some v -> ("image-rendering", "imageRendering", v) :: acc | None -> acc in
  let acc = match kerning with Some v -> ("kerning", "kerning", v) :: acc | None -> acc in
  let acc = match lightingColor with Some v -> ("lighting-color", "lightingColor", v) :: acc | None -> acc in
  let acc = match markerEnd with Some v -> ("marker-end", "markerEnd", v) :: acc | None -> acc in
  let acc = match markerMid with Some v -> ("marker-mid", "markerMid", v) :: acc | None -> acc in
  let acc = match markerStart with Some v -> ("marker-start", "markerStart", v) :: acc | None -> acc in
  let acc = match pointerEvents with Some v -> ("pointer-events", "pointerEvents", v) :: acc | None -> acc in
  let acc = match shapeRendering with Some v -> ("shape-rendering", "shapeRendering", v) :: acc | None -> acc in
  let acc = match stopColor with Some v -> ("stop-color", "stopColor", v) :: acc | None -> acc in
  let acc = match stopOpacity with Some v -> ("stop-opacity", "stopOpacity", v) :: acc | None -> acc in
  let acc = match stroke with Some v -> ("stroke", "stroke", v) :: acc | None -> acc in
  let acc = match strokeDasharray with Some v -> ("stroke-dasharray", "strokeDasharray", v) :: acc | None -> acc in
  let acc = match strokeDashoffset with Some v -> ("stroke-dashoffset", "strokeDashoffset", v) :: acc | None -> acc in
  let acc = match strokeLinecap with Some v -> ("stroke-linecap", "strokeLinecap", v) :: acc | None -> acc in
  let acc = match strokeLinejoin with Some v -> ("stroke-linejoin", "strokeLinejoin", v) :: acc | None -> acc in
  let acc = match strokeMiterlimit with Some v -> ("stroke-miterlimit", "strokeMiterlimit", v) :: acc | None -> acc in
  let acc = match strokeOpacity with Some v -> ("stroke-opacity", "strokeOpacity", v) :: acc | None -> acc in
  let acc = match strokeWidth with Some v -> ("stroke-width", "strokeWidth", v) :: acc | None -> acc in
  let acc = match textAnchor with Some v -> ("text-anchor", "textAnchor", v) :: acc | None -> acc in
  let acc = match textRendering with Some v -> ("text-rendering", "textRendering", v) :: acc | None -> acc in
  let acc = match rubyAlign with Some v -> ("ruby-align", "rubyAlign", v) :: acc | None -> acc in
  let acc = match rubyMerge with Some v -> ("ruby-merge", "rubyMerge", v) :: acc | None -> acc in
  let acc = match rubyPosition with Some v -> ("ruby-position", "rubyPosition", v) :: acc | None -> acc in
  acc
[@@@ocamlformat "enable"]

let write_to_buffer buf (styles : t) : unit =
  let rec loop first = function
    | [] -> ()
    | (k, _, v) :: rest ->
        if v == "" then loop first rest
        else (
          if not first then Buffer.add_char buf ';';
          Buffer.add_string buf k;
          Buffer.add_char buf ':';
          Buffer.add_string buf (String.trim v);
          loop false rest)
  in
  loop true styles

let to_string (styles : t) : string =
  let buf = Buffer.create 64 in
  write_to_buffer buf styles;
  Buffer.contents buf

(* TODO: Remove conversion to sequences, can do List.combine *)
let combine (styles1 : t) (styles2 : t) : t =
  let seq1 = styles1 |> List.to_seq in
  let seq2 = styles2 |> List.to_seq in
  Seq.append seq1 seq2 |> List.of_seq

let string_of_chars chars =
  let buf = Buffer.create 16 in
  List.iter (Buffer.add_char buf) chars;
  Buffer.contents buf

let chars_of_string str = List.init (String.length str) (String.get str)

let camelcaseToKebabcase str =
  let rec loop acc = function
    | [] -> acc
    | [ x ] -> x :: acc
    | x :: y :: xs ->
        if Char.uppercase_ascii y == y then loop ('-' :: x :: acc) (Char.lowercase_ascii y :: xs)
        else loop (x :: acc) (y :: xs)
  in
  str |> chars_of_string |> loop [] |> List.rev |> string_of_chars

let unsafeAddProp styles key value : t =
  (* Adds the (key, value) into last position *)
  (camelcaseToKebabcase key, key, value) :: styles

(* Since we don't have a proper representation of `< .. > Js.t` yet,
   we can't make the unsafeAddStyle
   external unsafeAddStyle :
      ((_)[@mel.as {json|{}|json}]) -> t -> < .. > Js.t -> t = "Object.assign" *)
