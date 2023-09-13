type t = Dom.customEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "CustomEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "CustomEvent";
