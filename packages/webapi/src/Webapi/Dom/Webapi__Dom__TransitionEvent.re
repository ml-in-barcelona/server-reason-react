type t = Dom.transitionEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "TransitionEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "TransitionEvent";

[@mel.get] external propertyName: t => string = "propertyName";
[@mel.get] external elapsedTime: t => float = "elapsedTime";
[@mel.get]
external pseudoElement: t => string /* enum-ish */ = "pseudoElement";
