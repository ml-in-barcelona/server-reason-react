type t = Dom.pageTransitionEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "PageTransitionEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "PageTransitionEvent";

[@mel.get] external persisted: t => bool = "persisted";
