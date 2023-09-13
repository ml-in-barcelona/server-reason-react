type t = Dom.animationEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "AnimationEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "AnimationEvent";

[@mel.get] external animationName: t => string = "animationName";
[@mel.get] external elapsedTime: t => float = "elapsedTime";
[@mel.get]
external pseudoElement: t => string /* enum-ish */ = "pseudoElement";
