type t = Dom.focusEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "FocusEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "FocusEvent";

[@mel.get] [@mel.return nullable]
external relatedTarget: t => option(Dom.eventTarget) = "relatedTarget";
