module ResizeObserverEntry = Webapi__ResizeObserver__ResizeObserverEntry;

type t;

[@mel.new]
external make: (array(ResizeObserverEntry.t) => unit) => t = "ResizeObserver";
[@mel.new]
external makeWithObserver: ((array(ResizeObserverEntry.t), t) => unit) => t =
  "ResizeObserver";

[@mel.send] external disconnect: t => unit = "disconnect";
[@mel.send] external observe: (t, Dom.element) => unit = "observe";
[@mel.send] external unobserve: (t, Dom.element) => unit = "unobserve";
