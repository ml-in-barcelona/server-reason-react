type t = Dom.progressEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "ProgressEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "ProgressEvent";

[@mel.get] external lengthComputable: t => bool = "lengthComputable";
[@mel.get] external loaded: t => int = "loaded";
[@mel.get] external total: t => int = "total";
