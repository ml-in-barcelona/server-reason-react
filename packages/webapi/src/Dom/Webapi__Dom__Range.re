type t = Dom.range;

[@mel.new] external make: unit => t = "Range"; /* experimental */

[@mel.get] external collapsed: t => bool = "collapsed";
[@mel.get]
external commonAncestorContainer: t => Dom.node = "commonAncestorContainer";
[@mel.get] external endContainer: t => Dom.node = "endContainer";
[@mel.get] external endOffset: t => int = "endOffset";
[@mel.get] external startContainer: t => Dom.node = "startContainer";
[@mel.get] external startOffset: t => int = "startOffset";

[@mel.send.pipe: t]
external setStart: (Dom.node_like('a), int) => unit = "setStart";
[@mel.send.pipe: t]
external setEnd: (Dom.node_like('a), int) => unit = "setEnd";
[@mel.send.pipe: t]
external setStartBefore: Dom.node_like('a) => unit = "setStartBefore";
[@mel.send.pipe: t]
external setStartAfter: Dom.node_like('a) => unit = "setStartAfter";
[@mel.send.pipe: t]
external setEndBefore: Dom.node_like('a) => unit = "setEndBefore";
[@mel.send.pipe: t]
external setEndAfter: Dom.node_like('a) => unit = "setEndAfter";
[@mel.send.pipe: t]
external selectNode: Dom.node_like('a) => unit = "selectNode";
[@mel.send.pipe: t]
external selectNodeContents: Dom.node_like('a) => unit = "selectNodeContents";
[@mel.send.pipe: t] external collapse: unit = "collapse";
[@mel.send.pipe: t]
external collapseToStart: ([@mel.as {json|true|json}] _) => unit = "collapse";
[@mel.send.pipe: t]
external cloneContents: Dom.documentFragment = "cloneContents";
[@mel.send.pipe: t] external deleteContents: unit = "deleteContents";
[@mel.send.pipe: t]
external extractContents: Dom.documentFragment = "extractContents";
[@mel.send.pipe: t]
external insertNode: Dom.node_like('a) => unit = "insertNode";
[@mel.send.pipe: t]
external surroundContents: Dom.node_like('a) => unit = "surroundContents";
[@mel.send.pipe: t]
external compareBoundaryPoints:
  (int /* compareHow enum */, t) => int /* compareResult enum */ =
  "compareBoundaryPoints";
let compareBoundaryPoint:
  (Webapi__Dom__Types.compareHow, t, t) => Webapi__Dom__Types.compareResult =
  (how, range, self) =>
    Webapi__Dom__Types.decodeCompareResult(
      compareBoundaryPoints(
        Webapi__Dom__Types.encodeCompareHow(how),
        range,
        self,
      ),
    );
[@mel.send.pipe: t] external cloneRange: t = "cloneRange";
[@mel.send.pipe: t] external detach: unit = "detach";
[@mel.send.pipe: t] external toString: string = "toString";
[@mel.send.pipe: t]
external comparePoint: (Dom.node_like('a), int) => int /* compareRsult enum */ =
  "comparePoint";
let comparePoint:
  (Dom.node_like('a), int, t) => Webapi__Dom__Types.compareResult =
  (node, offset, self) =>
    Webapi__Dom__Types.decodeCompareResult(comparePoint(node, offset, self));
[@mel.send.pipe: t]
external createContextualFragment: string => Dom.documentFragment =
  "createContextualFragment"; /* experimental, but widely supported */
[@mel.send.pipe: t]
external getBoundingClientRect: Dom.domRect = "getBoundingClientRect"; /* experimental, but widely supported */
[@mel.send.pipe: t]
external getClientRects: array(Dom.domRect) = "getClientRects"; /* experimental, but widely supported */
[@mel.send.pipe: t]
external intersectsNode: Dom.node_like('a) => bool = "intersectsNode";
[@mel.send.pipe: t]
external isPointInRange: (Dom.node_like('a), int) => bool = "isPointInRange";
