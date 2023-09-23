type t = Dom.svgZoomEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "SVGZoomEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "SVGZoomEvent";

[@mel.get] external zoomRectScreen: t => Dom.svgRect = "zoomRectScreen";
[@mel.get] external previousScale: t => float = "previousScale";
[@mel.get] external previousTranslate: t => Dom.svgPoint = "previousTranslate";
[@mel.get] external newScale: t => float = "newScale";
[@mel.get] external newTranslate: t => Dom.svgPoint = "newTranslate";
