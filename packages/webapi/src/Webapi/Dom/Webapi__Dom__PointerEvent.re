type t = Dom.pointerEvent;
type pointerId = Dom.eventPointerId;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});
include Webapi__Dom__MouseEvent.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "PointerEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "PointerEvent";

[@mel.get] external pointerId: t => pointerId = "pointerId";
[@mel.get] external width: t => int = "width";
[@mel.get] external height: t => int = "height";
[@mel.get] external pressure: t => float = "pressure";
[@mel.get] external tiltX: t => int = "tiltX";
[@mel.get] external tiltY: t => int = "tiltY";
[@mel.get]
external pointerType: t => string /* pointerType enum */ = "pointerType";
let pointerType: t => Webapi__Dom__Types.pointerType =
  self => Webapi__Dom__Types.decodePointerType(pointerType(self));
[@mel.get] external isPrimary: t => bool = "isPrimary";
