type t = Dom.popStateEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "PopStateEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "PopStateEvent";

[@mel.get] external state: t => Js.t({..}) = "state";
