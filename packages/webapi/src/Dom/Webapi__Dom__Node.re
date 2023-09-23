module Impl = (T: {
                 type t;
               }) => {
  external asNode: T.t => Dom.node = "%identity";

  /* baseURI */
  [@mel.get] external childNodes: T.t => Dom.nodeList = "childNodes";
  [@mel.get] [@mel.return nullable]
  external firstChild: T.t => option(Dom.node) = "firstChild";
  [@mel.get] external innerText: T.t => string = "innerText";
  [@mel.set] external setInnerText: (T.t, string) => unit = "innerText";
  [@mel.get] [@mel.return nullable]
  external lastChild: T.t => option(Dom.node) = "lastChild";
  [@mel.get] [@mel.return nullable]
  external nextSibling: T.t => option(Dom.node) = "nextSibling";
  [@mel.get] external nodeName: T.t => string = "nodeName"; /* nodePrincipal */
  [@mel.get] external nodeType: T.t => int /* nodeType enum */ = "nodeType";
  let nodeType: T.t => Webapi__Dom__Types.nodeType =
    self => Webapi__Dom__Types.decodeNodeType(nodeType(self));
  [@mel.get] [@mel.return nullable]
  external nodeValue: T.t => option(string) = "nodeValue";
  [@mel.set]
  external setNodeValue: (T.t, Js.null(string)) => unit = "nodeValue" /* let setNodeValue : T.t => option string => unit = fun self value => setNodeValue self (Js.Null.fromOption value); */; /* temporarily removed to reduce codegen size */
  /* Not supported yet
     external setNodeValue : T.t => string => unit = "nodeValue" [@@mel.set];
     external clearNodeValue : T.t => _ [@mel.as {json|null|json}] => unit = "nodeValue" [@@mel.set];
     */
  /* outerText */
  [@mel.get] external ownerDocument: T.t => Dom.document = "ownerDocument";
  [@mel.get] [@mel.return nullable]
  external parentElement: T.t => option(Dom.element) = "parentElement";
  [@mel.get] [@mel.return nullable]
  external parentNode: T.t => option(Dom.node) = "parentNode";
  [@mel.get] [@mel.return nullable]
  external previousSibling: T.t => option(Dom.node) = "previousSibling";
  [@mel.get] external rootNode: T.t => Dom.node = "rootNode";
  [@mel.get] external textContent: T.t => string = "textContent";
  [@mel.set] external setTextContent: (T.t, string) => unit = "textContent";

  [@mel.send.pipe: T.t]
  external appendChild: Dom.node_like('a) => unit = "appendChild";
  [@mel.send.pipe: T.t] external cloneNode: T.t = "cloneNode";
  [@mel.send.pipe: T.t]
  external cloneNodeDeep: ([@mel.as {json|true|json}] _) => T.t = "cloneNode";
  [@mel.send.pipe: T.t]
  external compareDocumentPosition: Dom.node_like('a) => int =
    "compareDocumentPosition"; /* returns a bitmask which could also be represeneted as an enum, see https://developer.mozilla.org/en-US/docs/Web/API/Node/compareDocumentPosition */
  [@mel.send.pipe: T.t]
  external contains: Dom.node_like('a) => bool = "contains";
  [@mel.send.pipe: T.t] external getRootNode: Dom.node = "getRootNode";
  [@mel.send.pipe: T.t]
  external getRootNodeComposed:
    ([@mel.as {json|{ "composed": true }|json}] _) => Dom.node =
    "getRootNode";
  [@mel.send.pipe: T.t] external hasChildNodes: bool = "hasChildNodes";
  [@mel.send.pipe: T.t]
  external insertBefore:
    (Dom.node_like('a), Dom.node_like('b)) => Dom.node_like('a) =
    "insertBefore";
  /* (temporarily?) removed to reduce codegen size. This variant is just for convenience, `appendChild` can be used in place of passing `null` to `insertBefore`
     external insertBefore : Dom.node_like 'a => Js.null (Dom.node_like 'b) => Dom.node_like 'a = "insertBefore" [@@mel.send.pipe: T.t];
     let insertBefore : Dom.node_like 'a => option (Dom.node_like 'b) => T.t => Dom.node_like 'a = fun node reference self => insertBefore node (Js.Null.fromOption reference) self;
     */
  [@mel.send.pipe: T.t]
  external isDefaultNamespace: string => bool = "isDefaultNamespace";
  [@mel.send.pipe: T.t]
  external isEqualNode: Dom.node_like('a) => bool = "isEqualNode";
  [@mel.send.pipe: T.t]
  external isSameNode: Dom.node_like('a) => bool = "isSameNode";
  [@mel.send.pipe: T.t] [@mel.return nullable]
  external lookupNamespaceURI: string => option(string) =
    "lookupNamespaceURI";
  [@mel.send.pipe: T.t] [@mel.return nullable]
  external lookupDefaultNamespaceURI:
    ([@mel.as {json|null|json}] _) => option(string) =
    "lookupNamespaceURI";
  [@mel.send.pipe: T.t] external lookupPrefix: string = "lookupPrefix";
  [@mel.send.pipe: T.t] external normalize: unit = "normalize";
  [@mel.send.pipe: T.t]
  external removeChild: Dom.node_like('a) => Dom.node_like('a) =
    "removeChild";

  /** @since 0.19.0 */
  [@mel.send.pipe: T.t]
  external replaceChild:
    (Dom.node_like('a), Dom.node_like('b)) => Dom.node_like('b) =
    "replaceChild";
};

type t = Dom.node;

include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});
