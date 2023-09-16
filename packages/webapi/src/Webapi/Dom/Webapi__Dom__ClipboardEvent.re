type t = Dom.clipboardEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "ClipboardEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "ClipboardEvent";

[@mel.get] external clipboardData: t => Dom.dataTransfer = "clipboardData";
