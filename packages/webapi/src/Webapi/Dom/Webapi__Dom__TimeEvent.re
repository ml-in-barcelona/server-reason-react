type t = Dom.timeEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "TimeEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "TimeEvent";

[@mel.get] external detail: t => int = "detail";
[@mel.get] external view: t => Dom.window = "view"; /* technically returns a `WindowProxy` */
