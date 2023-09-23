type t = Dom.selection;

[@mel.get] [@mel.return nullable]
external anchorNode: t => option(Dom.node) = "anchorNode";
[@mel.get] external anchorOffset: t => int = "anchorOffset";
[@mel.get] [@mel.return nullable]
external focusNode: t => option(Dom.node) = "focusNode";
[@mel.get] external focusOffset: t => int = "focusOffset";
[@mel.get] external isCollapsed: t => bool = "isCollapsed";
[@mel.get] external rangeCount: t => int = "rangeCount";

[@mel.send.pipe: t] external getRangeAt: int => Dom.range = "getRangeAt";
[@mel.send.pipe: t]
external collapse: (Dom.node_like(_), int) => unit = "collapse";
[@mel.send.pipe: t]
external extend: (Dom.node_like(_), int) => unit = "extend";
[@mel.send.pipe: t] external collapseToStart: unit = "collapseToStart";
[@mel.send.pipe: t] external collapseToEnd: unit = "collapseToEnd";
[@mel.send.pipe: t]
external selectAllChildren: Dom.node_like(_) => unit = "selectAllChildren";
[@mel.send.pipe: t]
external setBaseAndExtent:
  (Dom.node_like(_), int, Dom.node_like(_), int) => unit =
  "setBaseAndExtent";
[@mel.send.pipe: t] external addRange: Dom.range => unit = "addRange";
[@mel.send.pipe: t] external removeRange: Dom.range => unit = "removeRange";
[@mel.send.pipe: t] external removeAllRanges: unit = "removeAllRanges";
[@mel.send.pipe: t] external deleteFromDocument: unit = "deleteFromDocument";
[@mel.send.pipe: t] external toString: string = "toString";
[@mel.send.pipe: t]
external containsNode:
  (Dom.node_like(_), [@mel.as {json|false|json}] _) => bool =
  "containsNode";
[@mel.send.pipe: t]
external containsNodePartly:
  (Dom.node_like(_), [@mel.as {json|true|json}] _) => bool =
  "containsNode";
