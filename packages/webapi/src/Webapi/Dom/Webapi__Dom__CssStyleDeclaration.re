type t = Dom.cssStyleDeclaration;
type cssRule; /* TODO: Move to Webapi__Dom */

[@bs.get] external cssText: t => string = "cssText";
[@bs.set] external setCssText: (t, string) => unit = "cssText";
[@bs.get] external length: t => int = "length";
[@bs.get] external parentRule: t => cssRule = "parentRule";

[@bs.send.pipe: t]
external getPropertyPriority: string => string = "getPropertyPriority";
[@bs.send.pipe: t]
external getPropertyValue: string => string = "getPropertyValue";
[@bs.send.pipe: t] external item: int => string = "item";
[@bs.send.pipe: t]
external removeProperty: string => string = "removeProperty";
[@bs.send.pipe: t]
external setProperty: (string, string, string) => unit = "setProperty" /*[@@bs.send.pipe : t] external setPropertyValue : (string, string) => unit = "setPropertyValue";*/; /* not mentioned by MDN and not implemented by chrome, but in the CSSOM spec:  https://drafts.csswg.org/cssom/#the-cssstyledeclaration-interface */
/* CSS2Properties */
[@bs.get] external azimuth: t => string = "azimuth";
[@bs.get] external background: t => string = "background";
[@bs.get] external backgroundAttachment: t => string = "backgroundAttachment";
[@bs.get] external backgroundColor: t => string = "backgroundColor";
[@bs.get] external backgroundImage: t => string = "backgroundImage";
[@bs.get] external backgroundPosition: t => string = "backgroundPosition";
[@bs.get] external backgroundRepeat: t => string = "backgroundRepeat";
[@bs.get] external border: t => string = "border";
[@bs.get] external borderCollapse: t => string = "borderCollapse";
[@bs.get] external borderColor: t => string = "borderColor";
[@bs.get] external borderSpacing: t => string = "borderSpacing";
[@bs.get] external borderStyle: t => string = "borderStyle";
[@bs.get] external borderTop: t => string = "borderTop";
[@bs.get] external borderRight: t => string = "borderRight";
[@bs.get] external borderBottom: t => string = "borderBottom";
[@bs.get] external borderLeft: t => string = "borderLeft";
[@bs.get] external borderTopColor: t => string = "borderTopColor";
[@bs.get] external borderRightColor: t => string = "borderRightColor";
[@bs.get] external borderBottomColor: t => string = "borderBottomColor";
[@bs.get] external borderLeftColor: t => string = "borderLeftColor";
[@bs.get] external borderTopStyle: t => string = "borderTopStyle";
[@bs.get] external borderRightStyle: t => string = "borderRightStyle";
[@bs.get] external borderBottomStyle: t => string = "borderBottomStyle";
[@bs.get] external borderLeftStyle: t => string = "borderLeftStyle";
[@bs.get] external borderTopWidth: t => string = "borderTopWidth";
[@bs.get] external borderRightWidth: t => string = "borderRightWidth";
[@bs.get] external borderBottomWidth: t => string = "borderBottomWidth";
[@bs.get] external borderLeftWidth: t => string = "borderLeftWidth";
[@bs.get] external borderWidth: t => string = "borderWidth";
[@bs.get] external bottom: t => string = "bottom";
[@bs.get] external captionSide: t => string = "captionSide";
[@bs.get] external clear: t => string = "clear";
[@bs.get] external clip: t => string = "clip";
[@bs.get] external color: t => string = "color";
[@bs.get] external content: t => string = "content";
[@bs.get] external counterIncrement: t => string = "counterIncrement";
[@bs.get] external counterReset: t => string = "counterReset";
[@bs.get] external cue: t => string = "cue";
[@bs.get] external cueAfter: t => string = "cueAfter";
[@bs.get] external cueBefore: t => string = "cueBefore";
[@bs.get] external cursor: t => string = "cursor";
[@bs.get] external direction: t => string = "direction";
[@bs.get] external display: t => string = "display";
[@bs.get] external elevation: t => string = "elevation";
[@bs.get] external emptyCells: t => string = "emptyCells";
[@bs.get] external cssFloat: t => string = "cssFloat";
[@bs.get] external font: t => string = "font";
[@bs.get] external fontFamily: t => string = "fontFamily";
[@bs.get] external fontSize: t => string = "fontSize";
[@bs.get] external fontSizeAdjust: t => string = "fontSizeAdjust";
[@bs.get] external fontStretch: t => string = "fontStretch";
[@bs.get] external fontStyle: t => string = "fontStyle";
[@bs.get] external fontVariant: t => string = "fontVariant";
[@bs.get] external fontWeight: t => string = "fontWeight";
[@bs.get] external height: t => string = "height";
[@bs.get] external left: t => string = "left";
[@bs.get] external letterSpacing: t => string = "letterSpacing";
[@bs.get] external lineHeight: t => string = "lineHeight";
[@bs.get] external listStyle: t => string = "listStyle";
[@bs.get] external listStyleImage: t => string = "listStyleImage";
[@bs.get] external listStylePosition: t => string = "listStylePosition";
[@bs.get] external listStyleType: t => string = "listStyleType";
[@bs.get] external margin: t => string = "margin";
[@bs.get] external marginTop: t => string = "marginTop";
[@bs.get] external marginRight: t => string = "marginRight";
[@bs.get] external marginBottom: t => string = "marginBottom";
[@bs.get] external marginLeft: t => string = "marginLeft";
[@bs.get] external markerOffset: t => string = "markerOffset";
[@bs.get] external marks: t => string = "marks";
[@bs.get] external maxHeight: t => string = "maxHeight";
[@bs.get] external maxWidth: t => string = "maxWidth";
[@bs.get] external minHeight: t => string = "minHeight";
[@bs.get] external minWidth: t => string = "minWidth";
[@bs.get] external orphans: t => string = "orphans";
[@bs.get] external outline: t => string = "outline";
[@bs.get] external outlineColor: t => string = "outlineColor";
[@bs.get] external outlineStyle: t => string = "outlineStyle";
[@bs.get] external outlineWidth: t => string = "outlineWidth";
[@bs.get] external overflow: t => string = "overflow";
[@bs.get] external padding: t => string = "padding";
[@bs.get] external paddingTop: t => string = "paddingTop";
[@bs.get] external paddingRight: t => string = "paddingRight";
[@bs.get] external paddingBottom: t => string = "paddingBottom";
[@bs.get] external paddingLeft: t => string = "paddingLeft";
[@bs.get] external page: t => string = "page";
[@bs.get] external pageBreakAfter: t => string = "pageBreakAfter";
[@bs.get] external pageBreakBefore: t => string = "pageBreakBefore";
[@bs.get] external pageBreakInside: t => string = "pageBreakInside";
[@bs.get] external pause: t => string = "pause";
[@bs.get] external pauseAfter: t => string = "pauseAfter";
[@bs.get] external pauseBefore: t => string = "pauseBefore";
[@bs.get] external pitch: t => string = "pitch";
[@bs.get] external pitchRange: t => string = "pitchRange";
[@bs.get] external playDuring: t => string = "playDuring";
[@bs.get] external position: t => string = "position";
[@bs.get] external quotes: t => string = "quotes";
[@bs.get] external richness: t => string = "richness";
[@bs.get] external right: t => string = "right";
[@bs.get] external size: t => string = "size";
[@bs.get] external speak: t => string = "speak";
[@bs.get] external speakHeader: t => string = "speakHeader";
[@bs.get] external speakNumeral: t => string = "speakNumeral";
[@bs.get] external speakPunctuation: t => string = "speakPunctuation";
[@bs.get] external speechRate: t => string = "speechRate";
[@bs.get] external stress: t => string = "stress";
[@bs.get] external tableLayout: t => string = "tableLayout";
[@bs.get] external textAlign: t => string = "textAlign";
[@bs.get] external textDecoration: t => string = "textDecoration";
[@bs.get] external textIndent: t => string = "textIndent";
[@bs.get] external textShadow: t => string = "textShadow";
[@bs.get] external textTransform: t => string = "textTransform";
[@bs.get] external top: t => string = "top";
[@bs.get] external unicodeBidi: t => string = "unicodeBidi";
[@bs.get] external verticalAlign: t => string = "verticalAlign";
[@bs.get] external visibility: t => string = "visibility";
[@bs.get] external voiceFamily: t => string = "voiceFamily";
[@bs.get] external volume: t => string = "volume";
[@bs.get] external whiteSpace: t => string = "whiteSpace";
[@bs.get] external widows: t => string = "widows";
[@bs.get] external width: t => string = "width";
[@bs.get] external wordSpacing: t => string = "wordSpacing";
[@bs.get] external zIndex: t => string = "zIndex";