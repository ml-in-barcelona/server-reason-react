type t = Dom.compositionEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "CompositionEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "CompositionEvent";

[@mel.get] external data: t => string = "data";
