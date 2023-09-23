type t = Dom.mutationRecord;

[@mel.get] external type_: t => string = "type";
[@mel.get] external target: t => Dom.node = "target";
[@mel.get] external addedNodes: t => Dom.nodeList = "addedNodes";
[@mel.get] external removedNodes: t => Dom.nodeList = "removedNodes";
[@mel.get] [@mel.return nullable]
external previousSibling: t => option(Dom.node) = "previousSibling";
[@mel.get] [@mel.return nullable]
external nextSibling: t => option(Dom.node) = "nextSibling";
[@mel.get] external attributeName: t => string = "attributeName";
[@mel.get] external attributeNamespace: t => string = "attributeNamespace";
[@mel.get] external oldValue: t => string = "oldValue";
