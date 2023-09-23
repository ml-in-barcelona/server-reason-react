type t = Dom.closeEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "CloseEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "CloseEvent";

[@mel.get] external wasClean: t => bool = "wasClean";
[@mel.get] external code: t => int = "code";
[@mel.get] external reason: t => string = "reason";
