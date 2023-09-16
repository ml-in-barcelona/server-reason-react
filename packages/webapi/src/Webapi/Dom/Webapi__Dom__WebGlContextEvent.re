type t = Dom.webGlContextEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "WebGLContextEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "WebGLContextEvent";

[@mel.get] external statusMessage: t => string = "statusMessage";
