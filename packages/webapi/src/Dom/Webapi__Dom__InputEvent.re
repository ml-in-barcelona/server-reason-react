type t = Dom.inputEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "InputEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "InputEvent";

[@mel.get] external data: t => string = "data";
[@mel.get] external isComposing: t => bool = "isComposing";
