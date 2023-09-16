type t = Dom.nodeList;

external toArray: t => array(Dom.node) = "Array.prototype.slice.call";

[@mel.send.pipe: t]
external forEach: ((Dom.node, int) => unit) => unit = "forEach";

[@mel.get] external length: t => int = "length";

[@mel.send.pipe: t] [@mel.return nullable]
external item: int => option(Dom.node) = "item";
