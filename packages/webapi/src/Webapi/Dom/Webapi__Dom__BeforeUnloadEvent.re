type t = Dom.beforeUnloadEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "BeforeUnloadEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "BeforeUnloadEvent";

[@mel.get] external returnValue: t => string = "returnValue";
