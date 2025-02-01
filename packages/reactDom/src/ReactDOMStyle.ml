type t = (string * string * string) list

let add name jsxName item (map : t) = match item with Some v -> (name, jsxName, v) :: map | None -> map

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

  []
  |> add "azimuth" "azimuth" azimuth
  |> add "background" "background" background
  |> add "background-attachment" "backgroundAttachment" backgroundAttachment
  |> add "background-color" "backgroundColor" backgroundColor
  |> add "background-image" "backgroundImage" backgroundImage
  |> add "background-position" "backgroundPosition" backgroundPosition
  |> add "background-repeat" "backgroundRepeat" backgroundRepeat
  |> add "border" "border" border
  |> add "border-collapse" "borderCollapse" borderCollapse
  |> add "border-color" "borderColor" borderColor
  |> add "border-spacing" "borderSpacing" borderSpacing
  |> add "border-style" "borderStyle" borderStyle
  |> add "border-top" "borderTop" borderTop
  |> add "border-right" "borderRight" borderRight
  |> add "border-bottom" "borderBottom" borderBottom
  |> add "border-left" "borderLeft" borderLeft
  |> add "border-top-color" "borderTopColor" borderTopColor
  |> add "border-right-color" "borderRightColor" borderRightColor
  |> add "border-bottom-color" "borderBottomColor" borderBottomColor
  |> add "border-left-color" "borderLeftColor" borderLeftColor
  |> add "border-top-style" "borderTopStyle" borderTopStyle
  |> add "border-right-style" "borderRightStyle" borderRightStyle
  |> add "border-bottom-style" "borderBottomStyle" borderBottomStyle
  |> add "border-left-style" "borderLeftStyle" borderLeftStyle
  |> add "border-top-width" "borderTopWidth" borderTopWidth
  |> add "border-right-width" "borderRightWidth" borderRightWidth
  |> add "border-bottom-width" "borderBottomWidth" borderBottomWidth
  |> add "border-left-width" "borderLeftWidth" borderLeftWidth
  |> add "border-width" "borderWidth" borderWidth
  |> add "bottom" "bottom" bottom
  |> add "caption-side" "captionSide" captionSide
  |> add "clear" "clear" clear
  |> add "clip" "clip" clip
  |> add "color" "color" color
  |> add "content" "content" content
  |> add "counter-increment" "counterIncrement" counterIncrement
  |> add "counter-reset" "counterReset" counterReset
  |> add "cue" "cue" cue
  |> add "cue-after" "cueAfter" cueAfter
  |> add "cue-before" "cueBefore" cueBefore
  |> add "cursor" "cursor" cursor
  |> add "direction" "direction" direction
  |> add "display" "display" display
  |> add "elevation" "elevation" elevation
  |> add "empty-cells" "emptyCells" emptyCells
  |> add "float" "float" float
  |> add "font" "font" font
  |> add "font-family" "fontFamily" fontFamily
  |> add "font-size" "fontSize" fontSize
  |> add "font-size-adjust" "fontSizeAdjust" fontSizeAdjust
  |> add "font-stretch" "fontStretch" fontStretch
  |> add "font-style" "fontStyle" fontStyle
  |> add "font-variant" "fontVariant" fontVariant
  |> add "font-weight" "fontWeight" fontWeight
  |> add "height" "height" height
  |> add "left" "left" left
  |> add "letter-spacing" "letterSpacing" letterSpacing
  |> add "line-height" "lineHeight" lineHeight
  |> add "list-style" "listStyle" listStyle
  |> add "list-style-image" "listStyleImage" listStyleImage
  |> add "list-style-position" "listStylePosition" listStylePosition
  |> add "list-style-type" "listStyleType" listStyleType
  |> add "margin" "margin" margin
  |> add "margin-top" "marginTop" marginTop
  |> add "margin-right" "marginRight" marginRight
  |> add "margin-bottom" "marginBottom" marginBottom
  |> add "margin-left" "marginLeft" marginLeft
  |> add "marker-offset" "markerOffset" markerOffset
  |> add "marks" "marks" marks
  |> add "max-height" "maxHeight" maxHeight
  |> add "max-width" "maxWidth" maxWidth
  |> add "min-height" "minHeight" minHeight
  |> add "min-width" "minWidth" minWidth
  |> add "orphans" "orphans" orphans
  |> add "outline" "outline" outline
  |> add "outline-color" "outlineColor" outlineColor
  |> add "outline-style" "outlineStyle" outlineStyle
  |> add "outline-width" "outlineWidth" outlineWidth
  |> add "overflow" "overflow" overflow
  |> add "overflow-x" "overflowX" overflowX
  |> add "overflow-y" "overflowY" overflowY
  |> add "padding" "padding" padding
  |> add "padding-top" "paddingTop" paddingTop
  |> add "padding-right" "paddingRight" paddingRight
  |> add "padding-bottom" "paddingBottom" paddingBottom
  |> add "padding-left" "paddingLeft" paddingLeft
  |> add "page" "page" page
  |> add "page-break-after" "pageBreakAfter" pageBreakAfter
  |> add "page-break-before" "pageBreakBefore" pageBreakBefore
  |> add "page-break-inside" "pageBreakInside" pageBreakInside
  |> add "pause" "pause" pause
  |> add "pause-after" "pauseAfter" pauseAfter
  |> add "pause-before" "pauseBefore" pauseBefore
  |> add "pitch" "pitch" pitch
  |> add "pitch-range" "pitchRange" pitchRange
  |> add "play-during" "playDuring" playDuring
  |> add "position" "position" position
  |> add "quotes" "quotes" quotes
  |> add "richness" "richness" richness
  |> add "right" "right" right
  |> add "size" "size" size
  |> add "speak" "speak" speak
  |> add "speak-header" "speakHeader" speakHeader
  |> add "speak-numeral" "speakNumeral" speakNumeral
  |> add "speak-punctuation" "speakPunctuation" speakPunctuation
  |> add "speech-rate" "speechRate" speechRate
  |> add "stress" "stress" stress
  |> add "table-layout" "tableLayout" tableLayout
  |> add "text-align" "textAlign" textAlign
  |> add "text-decoration" "textDecoration" textDecoration
  |> add "text-indent" "textIndent" textIndent
  |> add "text-shadow" "textShadow" textShadow
  |> add "text-transform" "textTransform" textTransform
  |> add "top" "top" top
  |> add "unicode-bidi" "unicodeBidi" unicodeBidi
  |> add "vertical-align" "verticalAlign" verticalAlign
  |> add "visibility" "visibility" visibility
  |> add "voice-family" "voiceFamily" voiceFamily
  |> add "volume" "volume" volume
  |> add "white-space" "whiteSpace" whiteSpace
  |> add "widows" "widows" widows
  |> add "width" "width" width
  |> add "word-spacing" "wordSpacing" wordSpacing
  |> add "z-index" "zIndex" zIndex
  |> add "opacity" "opacity" opacity
  |> add "background-origin" "backgroundOrigin" backgroundOrigin
  |> add "background-size" "backgroundSize" backgroundSize
  |> add "background-clip" "backgroundClip" backgroundClip
  |> add "border-radius" "borderRadius" borderRadius
  |> add "border-top-left-radius" "borderTopLeftRadius" borderTopLeftRadius
  |> add "border-top-right-radius" "borderTopRightRadius" borderTopRightRadius
  |> add "border-bottom-left-radius" "borderBottomLeftRadius" borderBottomLeftRadius
  |> add "border-bottom-right-radius" "borderBottomRightRadius" borderBottomRightRadius
  |> add "border-image" "borderImage" borderImage
  |> add "border-image-source" "borderImageSource" borderImageSource
  |> add "border-image-slice" "borderImageSlice" borderImageSlice
  |> add "border-image-width" "borderImageWidth" borderImageWidth
  |> add "border-image-outset" "borderImageOutset" borderImageOutset
  |> add "border-image-repeat" "borderImageRepeat" borderImageRepeat
  |> add "box-shadow" "boxShadow" boxShadow
  |> add "columns" "columns" columns
  |> add "column-count" "columnCount" columnCount
  |> add "column-fill" "columnFill" columnFill
  |> add "column-gap" "columnGap" columnGap
  |> add "column-rule" "columnRule" columnRule
  |> add "column-rule-color" "columnRuleColor" columnRuleColor
  |> add "column-rule-style" "columnRuleStyle" columnRuleStyle
  |> add "column-rule-width" "columnRuleWidth" columnRuleWidth
  |> add "column-span" "columnSpan" columnSpan
  |> add "column-width" "columnWidth" columnWidth
  |> add "break-after" "breakAfter" breakAfter
  |> add "break-before" "breakBefore" breakBefore
  |> add "break-inside" "breakInside" breakInside
  |> add "rest" "rest" rest
  |> add "rest-after" "restAfter" restAfter
  |> add "rest-before" "restBefore" restBefore
  |> add "speak-as" "speakAs" speakAs
  |> add "voice-balance" "voiceBalance" voiceBalance
  |> add "voice-duration" "voiceDuration" voiceDuration
  |> add "voice-pitch" "voicePitch" voicePitch
  |> add "voice-range" "voiceRange" voiceRange
  |> add "voice-rate" "voiceRate" voiceRate
  |> add "voice-stress" "voiceStress" voiceStress
  |> add "voice-volume" "voiceVolume" voiceVolume
  |> add "object-fit" "objectFit" objectFit
  |> add "object-position" "objectPosition" objectPosition
  |> add "image-resolution" "imageResolution" imageResolution
  |> add "image-orientation" "imageOrientation" imageOrientation
  |> add "align-content" "alignContent" alignContent
  |> add "align-items" "alignItems" alignItems
  |> add "align-self" "alignSelf" alignSelf
  |> add "flex" "flex" flex
  |> add "flex-basis" "flexBasis" flexBasis
  |> add "flex-direction" "flexDirection" flexDirection
  |> add "flex-flow" "flexFlow" flexFlow
  |> add "flex-grow" "flexGrow" flexGrow
  |> add "flex-shrink" "flexShrink" flexShrink
  |> add "flex-wrap" "flexWrap" flexWrap
  |> add "justify-content" "justifyContent" justifyContent
  |> add "order" "order" order
  |> add "text-decoration-color" "textDecorationColor" textDecorationColor
  |> add "text-decoration-line" "textDecorationLine" textDecorationLine
  |> add "text-decoration-skip" "textDecorationSkip" textDecorationSkip
  |> add "text-decoration-style" "textDecorationStyle" textDecorationStyle
  |> add "text-emphasis" "textEmphasis" textEmphasis
  |> add "text-emphasis-color" "textEmphasisColor" textEmphasisColor
  |> add "text-emphasis-position" "textEmphasisPosition" textEmphasisPosition
  |> add "text-emphasis-style" "textEmphasisStyle" textEmphasisStyle
  |> add "text-underline-position" "textUnderlinePosition" textUnderlinePosition
  |> add "font-feature-settings" "fontFeatureSettings" fontFeatureSettings
  |> add "font-kerning" "fontKerning" fontKerning
  |> add "font-language-override" "fontLanguageOverride" fontLanguageOverride
  |> add "font-synthesis" "fontSynthesis" fontSynthesis
  |> add "fornt-variant-alternates" "forntVariantAlternates" forntVariantAlternates
  |> add "font-variant-caps" "fontVariantCaps" fontVariantCaps
  |> add "font-variant-east-asian" "fontVariantEastAsian" fontVariantEastAsian
  |> add "font-variant-ligatures" "fontVariantLigatures" fontVariantLigatures
  |> add "font-variant-numeric" "fontVariantNumeric" fontVariantNumeric
  |> add "font-variant-position" "fontVariantPosition" fontVariantPosition
  |> add "all" "all" all
  |> add "glyph-orientation-vertical" "glyphOrientationVertical" glyphOrientationVertical
  |> add "text-combine-upright" "textCombineUpright" textCombineUpright
  |> add "text-orientation" "textOrientation" textOrientation
  |> add "writing-mode" "writingMode" writingMode
  |> add "shape-image-threshold" "shapeImageThreshold" shapeImageThreshold
  |> add "shape-margin" "shapeMargin" shapeMargin
  |> add "shape-outside" "shapeOutside" shapeOutside
  |> add "clip-path" "clipPath" clipPath
  |> add "clip-rule" "clipRule" clipRule
  |> add "mask" "mask" mask
  |> add "mask-border" "maskBorder" maskBorder
  |> add "mask-border-mode" "maskBorderMode" maskBorderMode
  |> add "mask-border-outset" "maskBorderOutset" maskBorderOutset
  |> add "mask-border-repeat" "maskBorderRepeat" maskBorderRepeat
  |> add "mask-border-slice" "maskBorderSlice" maskBorderSlice
  |> add "mask-border-source" "maskBorderSource" maskBorderSource
  |> add "mask-border-width" "maskBorderWidth" maskBorderWidth
  |> add "mask-clip" "maskClip" maskClip
  |> add "mask-composite" "maskComposite" maskComposite
  |> add "mask-image" "maskImage" maskImage
  |> add "mask-mode" "maskMode" maskMode
  |> add "mask-origin" "maskOrigin" maskOrigin
  |> add "mask-position" "maskPosition" maskPosition
  |> add "mask-repeat" "maskRepeat" maskRepeat
  |> add "mask-size" "maskSize" maskSize
  |> add "mask-type" "maskType" maskType
  |> add "background-blend-mode" "backgroundBlendMode" backgroundBlendMode
  |> add "isolation" "isolation" isolation
  |> add "mix-blend-mode" "mixBlendMode" mixBlendMode
  |> add "box-decoration-break" "boxDecorationBreak" boxDecorationBreak
  |> add "box-sizing" "boxSizing" boxSizing
  |> add "caret-color" "caretColor" caretColor
  |> add "nav-down" "navDown" navDown
  |> add "nav-left" "navLeft" navLeft
  |> add "nav-right" "navRight" navRight
  |> add "nav-up" "navUp" navUp
  |> add "outline-offset" "outlineOffset" outlineOffset
  |> add "resize" "resize" resize
  |> add "text-overflow" "textOverflow" textOverflow
  |> add "grid" "grid" grid
  |> add "grid-area" "gridArea" gridArea
  |> add "grid-auto-columns" "gridAutoColumns" gridAutoColumns
  |> add "grid-auto-flow" "gridAutoFlow" gridAutoFlow
  |> add "grid-auto-rows" "gridAutoRows" gridAutoRows
  |> add "grid-column" "gridColumn" gridColumn
  |> add "grid-column-end" "gridColumnEnd" gridColumnEnd
  |> add "grid-column-gap" "gridColumnGap" gridColumnGap
  |> add "grid-column-start" "gridColumnStart" gridColumnStart
  |> add "grid-gap" "gridGap" gridGap
  |> add "grid-row" "gridRow" gridRow
  |> add "grid-row-end" "gridRowEnd" gridRowEnd
  |> add "grid-row-gap" "gridRowGap" gridRowGap
  |> add "grid-row-start" "gridRowStart" gridRowStart
  |> add "grid-template" "gridTemplate" gridTemplate
  |> add "grid-template-areas" "gridTemplateAreas" gridTemplateAreas
  |> add "grid-template-columns" "gridTemplateColumns" gridTemplateColumns
  |> add "grid-template-rows" "gridTemplateRows" gridTemplateRows
  |> add "will-change" "willChange" willChange
  |> add "hanging-punctuation" "hangingPunctuation" hangingPunctuation
  |> add "hyphens" "hyphens" hyphens
  |> add "line-break" "lineBreak" lineBreak
  |> add "overflow-wrap" "overflowWrap" overflowWrap
  |> add "tab-size" "tabSize" tabSize
  |> add "text-align-last" "textAlignLast" textAlignLast
  |> add "text-justify" "textJustify" textJustify
  |> add "word-break" "wordBreak" wordBreak
  |> add "word-wrap" "wordWrap" wordWrap
  |> add "animation" "animation" animation
  |> add "animation-delay" "animationDelay" animationDelay
  |> add "animation-direction" "animationDirection" animationDirection
  |> add "animation-duration" "animationDuration" animationDuration
  |> add "animation-fill-mode" "animationFillMode" animationFillMode
  |> add "animation-iteration-count" "animationIterationCount" animationIterationCount
  |> add "animation-name" "animationName" animationName
  |> add "animation-play-state" "animationPlayState" animationPlayState
  |> add "animation-timing-function" "animationTimingFunction" animationTimingFunction
  |> add "transition" "transition" transition
  |> add "transition-delay" "transitionDelay" transitionDelay
  |> add "transition-duration" "transitionDuration" transitionDuration
  |> add "transition-property" "transitionProperty" transitionProperty
  |> add "transition-timing-function" "transitionTimingFunction" transitionTimingFunction
  |> add "backface-visibility" "backfaceVisibility" backfaceVisibility
  |> add "perspective" "perspective" perspective
  |> add "perspective-origin" "perspectiveOrigin" perspectiveOrigin
  |> add "transform" "transform" transform
  |> add "transform-origin" "transformOrigin" transformOrigin
  |> add "transform-style" "transformStyle" transformStyle
  |> add "justify-items" "justifyItems" justifyItems
  |> add "justify-self" "justifySelf" justifySelf
  |> add "place-content" "placeContent" placeContent
  |> add "place-items" "placeItems" placeItems
  |> add "place-self" "placeSelf" placeSelf
  |> add "appearance" "appearance" appearance
  |> add "caret" "caret" caret
  |> add "caret-animation" "caretAnimation" caretAnimation
  |> add "caret-shape" "caretShape" caretShape
  |> add "user-select" "userSelect" userSelect
  |> add "max-lines" "maxLines" maxLines
  |> add "marquee-direction" "marqueeDirection" marqueeDirection
  |> add "marquee-loop" "marqueeLoop" marqueeLoop
  |> add "marquee-speed" "marqueeSpeed" marqueeSpeed
  |> add "marquee-style" "marqueeStyle" marqueeStyle
  |> add "overflow-style" "overflowStyle" overflowStyle
  |> add "rotation" "rotation" rotation
  |> add "rotation-point" "rotationPoint" rotationPoint
  |> add "alignment-baseline" "alignmentBaseline" alignmentBaseline
  |> add "baseline-shift" "baselineShift" baselineShift
  |> add "clip" "clip" clip
  |> add "clip-path" "clipPath" clipPath
  |> add "clip-rule" "clipRule" clipRule
  |> add "color-interpolation" "colorInterpolation" colorInterpolation
  |> add "color-interpolation-filters" "colorInterpolationFilters" colorInterpolationFilters
  |> add "color-profile" "colorProfile" colorProfile
  |> add "color-rendering" "colorRendering" colorRendering
  |> add "cursor" "cursor" cursor
  |> add "dominant-baseline" "dominantBaseline" dominantBaseline
  |> add "fill" "fill" fill
  |> add "fill-opacity" "fillOpacity" fillOpacity
  |> add "fill-rule" "fillRule" fillRule
  |> add "filter" "filter" filter
  |> add "flood-color" "floodColor" floodColor
  |> add "flood-opacity" "floodOpacity" floodOpacity
  |> add "glyph-orientation-horizontal" "glyphOrientationHorizontal" glyphOrientationHorizontal
  |> add "glyph-orientation-vertical" "glyphOrientationVertical" glyphOrientationVertical
  |> add "image-rendering" "imageRendering" imageRendering
  |> add "kerning" "kerning" kerning
  |> add "lighting-color" "lightingColor" lightingColor
  |> add "marker-end" "markerEnd" markerEnd
  |> add "marker-mid" "markerMid" markerMid
  |> add "marker-start" "markerStart" markerStart
  |> add "pointer-events" "pointerEvents" pointerEvents
  |> add "shape-rendering" "shapeRendering" shapeRendering
  |> add "stop-color" "stopColor" stopColor
  |> add "stop-opacity" "stopOpacity" stopOpacity
  |> add "stroke" "stroke" stroke
  |> add "stroke-dasharray" "strokeDasharray" strokeDasharray
  |> add "stroke-dashoffset" "strokeDashoffset" strokeDashoffset
  |> add "stroke-linecap" "strokeLinecap" strokeLinecap
  |> add "stroke-linejoin" "strokeLinejoin" strokeLinejoin
  |> add "stroke-miterlimit" "strokeMiterlimit" strokeMiterlimit
  |> add "stroke-opacity" "strokeOpacity" strokeOpacity
  |> add "stroke-width" "strokeWidth" strokeWidth
  |> add "text-anchor" "textAnchor" textAnchor
  |> add "text-rendering" "textRendering" textRendering
  |> add "ruby-align" "rubyAlign" rubyAlign
  |> add "ruby-merge" "rubyMerge" rubyMerge
  |> add "ruby-position" "rubyPosition" rubyPosition
[@@@ocamlformat "enable"]

let to_string (styles : t) : string =
  let size = List.length styles in
  let buff = Buffer.create size in
  styles |> List.to_seq
  |> Seq.iteri (fun index (k, _, v) ->
         if v == "" then ()
         else if index == size - 1 then (
           Buffer.add_string buff k;
           Buffer.add_string buff ":";
           Buffer.add_string buff (String.trim v))
         else (
           Buffer.add_string buff k;
           Buffer.add_string buff ":";
           Buffer.add_string buff (String.trim v);
           Buffer.add_string buff ";"));
  Buffer.contents buff

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
