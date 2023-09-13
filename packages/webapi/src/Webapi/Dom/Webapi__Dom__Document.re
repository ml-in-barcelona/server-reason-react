module Impl = (T: {
                 type t;
               }) => {
  external asDocument: T.t => Dom.document = "%identity";

  let asHtmlDocument: T.t => option(Dom.htmlDocument) = [%raw
    {|
    function(document) {
      var defaultView = document.defaultView;

      if (defaultView != null) {
        var HTMLDocument = defaultView.HTMLDocument;

        if (HTMLDocument != null && document instanceof HTMLDocument) {
          return document;
        }
      }
    }
  |}
  ];

  /** Unsafe cast, use [ashtmlDocument] instead */
  external unsafeAsHtmlDocument: T.t => Dom.htmlDocument = "%identity";

  let ofNode = (node: Dom.node): option(T.t) =>
    Webapi__Dom__Node.nodeType(node) == Webapi__Dom__Types.Document
      ? Some(Obj.magic(node)) : None;

  [@mel.get] external characterSet: T.t => string = "characterSet";
  [@mel.get]
  external compatMode: T.t => string /* compatMode enum */ = "compatMode"; /* experimental */
  let compatMode: T.t => Webapi__Dom__Types.compatMode =
    self => Webapi__Dom__Types.decodeCompatMode(compatMode(self));
  [@mel.get] external doctype: T.t => Dom.documentType = "doctype";
  [@mel.get] external documentElement: T.t => Dom.element = "documentElement";
  [@mel.get] external documentURI: T.t => string = "documentURI";
  [@mel.get] external hidden: T.t => bool = "hidden";
  [@mel.get]
  external implementation: T.t => Dom.domImplementation = "implementation";
  [@mel.get] external lastStyleSheetSet: T.t => string = "lastStyleSheetSet";
  [@mel.get] [@mel.return nullable]
  external pointerLockElement: T.t => option(Dom.element) =
    "pointerLockElement"; /* experimental */

  [@mel.get]
  external preferredStyleSheetSet: T.t => string = "preferredStyleSheetSet";
  [@mel.get] [@mel.return nullable]
  external scrollingElement: T.t => option(Dom.element) = "scrollingElement";
  [@mel.get]
  external selectedStyleSheetSet: T.t => string = "selectedStyleSheetSet";
  [@mel.set]
  external setSelectedStyleSheetSet: (T.t, string) => unit =
    "selectedStyleSheetSet";
  [@mel.get]
  external styleSheets: T.t => array(Dom.cssStyleSheet) = "styleSheets"; /* return StyleSheetList, not array */
  [@mel.get] external styleSheetSets: T.t => array(string) = "styleSheetSets";
  [@mel.get]
  external visibilityState: T.t => string /* visibilityState enum */ =
    "visibilityState";
  let visibilityState: T.t => Webapi__Dom__Types.visibilityState =
    self => Webapi__Dom__Types.decodeVisibilityState(visibilityState(self));

  [@mel.send.pipe: T.t]
  external adoptNode: Dom.element_like('a) => Dom.element_like('a) =
    "adoptNode";
  [@mel.send.pipe: T.t]
  external createAttribute: string => Dom.attr = "createAttribute";
  [@mel.send.pipe: T.t]
  external createAttributeNS: (string, string) => Dom.attr =
    "createAttributeNS";
  [@mel.send.pipe: T.t]
  external createComment: string => Dom.comment = "createComment";
  [@mel.send.pipe: T.t]
  external createDocumentFragment: Dom.documentFragment =
    "createDocumentFragment";
  [@mel.send.pipe: T.t]
  external createElement: string => Dom.element = "createElement";
  [@mel.send.pipe: T.t]
  external createElementWithOptions: (string, Js.t({..})) => Dom.element =
    "createElement"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external createElementNS: (string, string) => Dom.element =
    "createElementNS";
  [@mel.send.pipe: T.t]
  external createElementNSWithOptions:
    (string, string, Js.t({..})) => Dom.element =
    "createElementNS"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external createEvent: string /* large enum */ => Dom.event = "createEvent"; /* discouraged (but not deprecated) in favor of Event constructors */
  [@mel.send.pipe: T.t]
  external createNodeIterator: Dom.node_like('a) => Dom.nodeIterator =
    "createNodeIterator";
  [@mel.send.pipe: T.t]
  external createNodeIteratorWithWhatToShow:
    (Dom.node_like('a), Webapi__Dom__Types.WhatToShow.t) => Dom.nodeIterator =
    "createNodeIterator";
  [@mel.send.pipe: T.t]
  external createNodeIteratorWithWhatToShowFilter:
    (Dom.node_like('a), Webapi__Dom__Types.WhatToShow.t, Dom.nodeFilter) =>
    Dom.nodeIterator =
    "createNodeIterator"; /* createProcessingInstruction */
  [@mel.send.pipe: T.t] external createRange: Dom.range = "createRange";
  [@mel.send.pipe: T.t]
  external createTextNode: string => Dom.text = "createTextNode";
  [@mel.send.pipe: T.t]
  external createTreeWalker: Dom.element_like('a) => Dom.treeWalker =
    "createTreeWalker";
  [@mel.send.pipe: T.t]
  external createTreeWalkerWithWhatToShow:
    (Dom.element_like('a), Webapi__Dom__Types.WhatToShow.t) => Dom.treeWalker =
    "createTreeWalker";
  [@mel.send.pipe: T.t]
  external createTreeWalkerWithWhatToShowFilter:
    (Dom.element_like('a), Webapi__Dom__Types.WhatToShow.t, Dom.nodeFilter) =>
    Dom.treeWalker =
    "createTreeWalker";
  [@mel.send.pipe: T.t]
  external elementFromPoint: (int, int) => Dom.element = "elementFromPoint"; /* experimental, but widely supported */
  [@mel.send.pipe: T.t]
  external elementsFromPoint: (int, int) => array(Dom.element) =
    "elementsFromPoint"; /* experimental */
  [@mel.send.pipe: T.t]
  external enableStyleSheetsForSet: string => unit = "enableStyleSheetsForSet";
  [@mel.send.pipe: T.t] external exitPointerLock: unit = "exitPointerLock"; /* experimental */
  [@mel.send.pipe: T.t]
  external getAnimations: array(Dom.animation) = "getAnimations"; /* experimental */
  [@mel.send.pipe: T.t]
  external getElementsByClassName: string => Dom.htmlCollection =
    "getElementsByClassName";
  [@mel.send.pipe: T.t]
  external getElementsByTagName: string => Dom.htmlCollection =
    "getElementsByTagName";
  [@mel.send.pipe: T.t]
  external getElementsByTagNameNS: (string, string) => Dom.htmlCollection =
    "getElementsByTagNameNS";
  [@mel.send.pipe: T.t]
  external importNode: Dom.element_like('a) => Dom.element_like('a) =
    "importNode";
  [@mel.send.pipe: T.t]
  external importNodeDeep:
    (Dom.element_like('a), [@mel.as {json|true|json}] _) =>
    Dom.element_like('a) =
    "importNode";
  [@mel.send.pipe: T.t]
  external registerElement: (string, unit) => Dom.element = "registerElement"; /* experimental and deprecated in favor of customElements.define() */
  [@mel.send.pipe: T.t]
  external registerElementWithOptions:
    (string, Js.t({..}), unit) => Dom.element =
    "registerElement"; /* experimental and deprecated in favor of customElements.define() */

  /** XPath stuff */;
  /* createExpression */
  /* createNSResolver */
  /* evaluate */
  /* GlobalEventHandlers interface */
};

type t = Dom.document;

include Webapi__Dom__Node.Impl({
  type nonrec t = t;
});
include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Webapi__Dom__NonElementParentNode.Impl({
  type nonrec t = t;
});
include Webapi__Dom__DocumentOrShadowRoot.Impl();
include Webapi__Dom__ParentNode.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});
