type t = Dom.wheelEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});
include Webapi__Dom__MouseEvent.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "WheelEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "WheelEvent";

[@mel.get] external deltaX: t => float = "deltaX";
[@mel.get] external deltaY: t => float = "deltaY";
[@mel.get] external deltaZ: t => float = "deltaZ";
[@mel.get] external deltaMode: t => int = "deltaMode";
let deltaMode: t => Webapi__Dom__Types.deltaMode =
  self => Webapi__Dom__Types.decodeDeltaMode(deltaMode(self));
