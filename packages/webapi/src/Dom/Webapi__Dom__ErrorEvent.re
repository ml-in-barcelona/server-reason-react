type t = Dom.errorEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "ErrorEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "ErrorEvent";

[@mel.get] external message: t => string = "message";
[@mel.get] external filename: t => string = "filename";
[@mel.get] external lineno: t => int = "lineno";
[@mel.get] external colno: t => int = "colno";
[@mel.get] external error: t => Js.t({..}) = "error";
