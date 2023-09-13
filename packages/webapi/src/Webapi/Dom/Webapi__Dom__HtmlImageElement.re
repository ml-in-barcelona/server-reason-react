type t;

[@mel.new] external make: unit => t = "Image";
[@mel.new] external makeWithSize: (int, int) => t = "Image";

[@mel.get] external alt: t => string = "alt";
[@mel.set] external setAlt: (t, string) => unit = "alt";
[@mel.get] external src: t => string = "src";
[@mel.set] external setSrc: (t, string) => unit = "src";
[@mel.get] external srcset: t => string = "srcset";
[@mel.set] external setSrcset: (t, string) => unit = "srcset";
[@mel.get] external sizes: t => string = "sizes";
[@mel.set] external setSizes: (t, string) => unit = "sizes";
[@mel.get] [@mel.return nullable]
external crossOrigin: t => option(string) = "crossOrigin";
[@mel.set]
external setCrossOrigin: (t, Js.null(string)) => unit = "crossOrigin";
let setCrossOrigin = (self, value) =>
  setCrossOrigin(self, Js.Null.fromOption(value));
[@mel.get] external useMap: t => string = "useMap";
[@mel.set] external setUseMap: (t, string) => unit = "useMap";
[@mel.get] external isMap: t => bool = "isMap";
[@mel.set] external setIsMap: (t, bool) => unit = "isMap";
[@mel.get] external height: t => int = "height";
[@mel.set] external setHeight: (t, int) => unit = "height";
[@mel.get] external width: t => int = "width";
[@mel.set] external setWidth: (t, int) => unit = "width";
[@mel.get] external naturalHeight: t => int = "naturalHeight";
[@mel.get] external naturalWidth: t => int = "naturalWidth";
[@mel.get] external complete: t => bool = "complete";
[@mel.get] external currentSrc: t => string = "currentSrc";
[@mel.get] external referrerPolicy: t => string = "referrerPolicy";
[@mel.set] external setReferrerPolicy: (t, string) => unit = "referrerPolicy";
[@mel.get] external decoding: t => string = "decoding";
[@mel.set] external setDecoding: (t, string) => unit = "decoding";

/* [@mel.send.pipe: t] external decode : Js.Promise.t(unit) = "decode"; */

include Webapi__Dom__Node.Impl({
  type nonrec t = t;
});
include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Webapi__Dom__Element.Impl({
  type nonrec t = t;
});
include Webapi__Dom__HtmlElement.Impl({
  type nonrec t = t;
});
