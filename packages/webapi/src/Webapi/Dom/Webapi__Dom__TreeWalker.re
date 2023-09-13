type t = Dom.treeWalker;

[@mel.get] external root: t => Dom.node = "root";
[@mel.get]
external whatToShow: t => Webapi__Dom__Types.WhatToShow.t = "whatToShow";
[@mel.get] [@mel.return nullable]
external filter: t => option(Dom.nodeFilter) = "filter";
[@mel.get] external currentNode: t => Dom.node = "currentNode";
[@mel.set] external setCurrentNode: (t, Dom.node) => unit = "setCurrentNode";

[@mel.send.pipe: t] [@mel.return nullable]
external parentNode: option(Dom.node) = "parentNode";
[@mel.send.pipe: t] [@mel.return nullable]
external firstChild: option(Dom.node) = "firstChild";
[@mel.send.pipe: t] [@mel.return nullable]
external lastChild: option(Dom.node) = "lastChild";
[@mel.send.pipe: t] [@mel.return nullable]
external previousSibling: option(Dom.node) = "previousSibling";
[@mel.send.pipe: t] [@mel.return nullable]
external nextSibling: option(Dom.node) = "nextSibling";
[@mel.send.pipe: t] [@mel.return nullable]
external previousNode: option(Dom.node) = "previousNode";
[@mel.send.pipe: t] [@mel.return nullable]
external nextNode: option(Dom.node) = "nextNode";
