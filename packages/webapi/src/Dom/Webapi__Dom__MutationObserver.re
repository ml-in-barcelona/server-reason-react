type t = Dom.mutationObserver;

[@mel.new]
external make: ((array(Dom.mutationRecord), t) => unit) => t =
  "MutationObserver";

[@mel.send.pipe: t]
external observe: (Dom.node_like('a), Js.t({..})) => unit = "observe";
[@mel.send.pipe: t] external disconnect: unit = "disconnect";
[@mel.send.pipe: t]
external takeRecords: array(Dom.mutationRecord) = "takeRecords";
