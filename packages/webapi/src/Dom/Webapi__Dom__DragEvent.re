type t = Dom.dragEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});
include Webapi__Dom__MouseEvent.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "DragEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "DragEvent";

[@mel.get] external dataTransfer: t => Dom.dataTransfer = "dataTransfer";
