type t = Dom.nodeIterator;

[@mel.get] external root: t => Dom.node = "root";
[@mel.get] external referenceNode: t => Dom.node = "referenceNode";
[@mel.get]
external pointerBeforeReferenceNode: t => bool = "pointerBeforeReferenceNode";
[@mel.get]
external whatToShow: t => Webapi__Dom__Types.WhatToShow.t = "whatToShow";
[@mel.get] [@mel.return nullable]
external filter: t => option(Dom.nodeFilter) = "filter";

[@mel.send.pipe: t] [@mel.return nullable]
external nextNode: option(Dom.node) = "nextNode";
[@mel.send.pipe: t] [@mel.return nullable]
external previousNode: option(Dom.node) = "previousNode";
[@mel.send.pipe: t] external detach: unit = "detach";
