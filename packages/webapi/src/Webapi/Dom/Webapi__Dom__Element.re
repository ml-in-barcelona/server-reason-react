/* internal, moved out of Impl to reduce unnecessary code duplication */
let ofNode = (node: Dom.node): option('a) =>
  Webapi__Dom__Node.nodeType(node) == Webapi__Dom__Types.Element
    ? Some(Obj.magic(node)) : None;

module Impl = (T: {
                 type t;
               }) => {
  let asHtmlElement: T.t => option(Dom.htmlElement) = [%raw
    {|
    function(element) {
      var ownerDocument = element.ownerDocument;

      if (ownerDocument != null) {
        var defaultView = ownerDocument.defaultView;

        if (defaultView != null) {
          var HTMLElement = defaultView.HTMLElement;

          if (HTMLElement != null && element instanceof HTMLElement) {
            return element;
          }
        }
      }
    }
  |}
  ];

  /** Unsafe cast, use [asHtmlElement] instead */
  external unsafeAsHtmlElement: T.t => Dom.htmlElement = "%identity";

  let ofNode: Dom.node => option(T.t) = ofNode;

  [@mel.get] external attributes: T.t => Dom.namedNodeMap = "attributes";
  [@mel.get] external classList: T.t => Dom.domTokenList = "classList";
  [@mel.get] external className: T.t => string = "className";
  [@mel.set] external setClassName: (T.t, string) => unit = "className";
  [@mel.get] external clientHeight: T.t => int = "clientHeight"; /* experimental */
  [@mel.get] external clientLeft: T.t => int = "clientLeft"; /* experimental */
  [@mel.get] external clientTop: T.t => int = "clientTop"; /* experimental */
  [@mel.get] external clientWidth: T.t => int = "clientWidth"; /* experimental */
  [@mel.get] external id: T.t => string = "id";
  [@mel.set] external setId: (T.t, string) => unit = "id";
  [@mel.get] external innerHTML: T.t => string = "innerHTML";
  [@mel.set] external setInnerHTML: (T.t, string) => unit = "innerHTML";
  [@mel.get] external localName: T.t => string = "localName";
  [@mel.get] [@mel.return nullable]
  external namespaceURI: T.t => option(string) = "namespaceURI";
  [@mel.get] external outerHTML: T.t => string = "outerHTML"; /* experimental, but widely supported */
  [@mel.set] external setOuterHTML: (T.t, string) => unit = "outerHTML"; /* experimental, but widely supported */
  [@mel.get] [@mel.return nullable]
  external prefix: T.t => option(string) = "prefix";
  [@mel.get] external scrollHeight: T.t => int = "scrollHeight"; /* experimental, but widely supported */
  [@mel.get] external scrollLeft: T.t => float = "scrollLeft"; /* experimental */
  [@mel.set] external setScrollLeft: (T.t, float) => unit = "scrollLeft"; /* experimental */
  [@mel.get] external scrollTop: T.t => float = "scrollTop"; /* experimental, but widely supported */
  [@mel.set] external setScrollTop: (T.t, float) => unit = "scrollTop"; /* experimental, but widely supported */
  [@mel.get] external scrollWidth: T.t => int = "scrollWidth"; /* experimental */
  [@mel.get] external shadowRoot: T.t => Dom.element = "shadowRoot"; /* experimental */
  [@mel.get] external slot: T.t => string = "slot"; /* experimental */
  [@mel.set] external setSlot: (T.t, string) => unit = "slot"; /* experimental */
  [@mel.get] external tagName: T.t => string = "tagName";

  [@mel.send.pipe: T.t]
  external attachShadow: {. "mode": string} => Dom.shadowRoot =
    "attachShadow"; /* experimental */
  [@mel.send.pipe: T.t]
  external attachShadowOpen:
    ([@mel.as {json|{ "mode": "open" }|json}] _) => Dom.shadowRoot =
    "attachShadow"; /* experimental */
  [@mel.send.pipe: T.t]
  external attachShadowClosed:
    ([@mel.as {json|{ "mode": "closed" }|json}] _) => Dom.shadowRoot =
    "attachShadow"; /* experimental */
  [@mel.send.pipe: T.t]
  external animate: (Js.t({..}), Js.t({..})) => Dom.animation = "animate"; /* experimental */
  [@mel.send.pipe: T.t] [@mel.return nullable]
  external closest: string => option(Dom.element) = "closest"; /* experimental */
  [@mel.send.pipe: T.t]
  external createShadowRoot: Dom.shadowRoot = "createShadowRoot"; /* experimental AND deprecated (?!) */
  [@mel.send.pipe: T.t] [@mel.return nullable]
  external getAttribute: string => option(string) = "getAttribute";
  [@mel.send.pipe: T.t] [@mel.return nullable]
  external getAttributeNS: (string, string) => option(string) =
    "getAttributeNS";
  [@mel.send.pipe: T.t]
  external getBoundingClientRect: Dom.domRect = "getBoundingClientRect";
  [@mel.send.pipe: T.t]
  external getClientRects: array(Dom.domRect) = "getClientRects";
  [@mel.send.pipe: T.t]
  external getElementsByClassName: string => Dom.htmlCollection =
    "getElementsByClassName";
  [@mel.send.pipe: T.t]
  external getElementsByTagName: string => Dom.htmlCollection =
    "getElementsByTagName";
  [@mel.send.pipe: T.t]
  external getElementsByTagNameNS: (string, string) => Dom.htmlCollection =
    "getElementsByTagNameNS";
  [@mel.send.pipe: T.t] external hasAttribute: string => bool = "hasAttribute";
  [@mel.send.pipe: T.t]
  external hasAttributeNS: (string, string) => bool = "hasAttributeNS";
  [@mel.send.pipe: T.t] external hasAttributes: bool = "hasAttributes";
  [@mel.send.pipe: T.t]
  external insertAdjacentElement:
    (string /* insertPosition enum */, Dom.element_like('a)) => unit =
    "insertAdjacentElement"; /* experimental, but widely supported */
  let insertAdjacentElement:
    (Webapi__Dom__Types.insertPosition, Dom.element_like('a), T.t) => unit =
    (position, element, self) =>
      insertAdjacentElement(
        Webapi__Dom__Types.encodeInsertPosition(position),
        element,
        self,
      );
  [@mel.send.pipe: T.t]
  external insertAdjacentHTML:
    (string /* insertPosition enum */, string) => unit =
    "insertAdjacentHTML"; /* experimental, but widely supported */
  let insertAdjacentHTML:
    (Webapi__Dom__Types.insertPosition, string, T.t) => unit =
    (position, text, self) =>
      insertAdjacentHTML(
        Webapi__Dom__Types.encodeInsertPosition(position),
        text,
        self,
      );
  [@mel.send.pipe: T.t]
  external insertAdjacentText:
    (string /* insertPosition enum */, string) => unit =
    "insertAdjacentText"; /* experimental, but widely supported */
  let insertAdjacentText:
    (Webapi__Dom__Types.insertPosition, string, T.t) => unit =
    (position, text, self) =>
      insertAdjacentText(
        Webapi__Dom__Types.encodeInsertPosition(position),
        text,
        self,
      );
  [@mel.send.pipe: T.t] external matches: string => bool = "matches"; /* experimental, but widely supported */
  [@mel.send.pipe: T.t]
  external releasePointerCapture: Dom.eventPointerId => unit =
    "releasePointerCapture";
  [@mel.send.pipe: T.t]
  external removeAttribute: string => unit = "removeAttribute";
  [@mel.send.pipe: T.t]
  external removeAttributeNS: (string, string) => unit = "removeAttributeNS";
  [@mel.send.pipe: T.t] external requestFullscreen: unit = "requestFullscreen"; /* experimental */
  [@mel.send.pipe: T.t]
  external requestPointerLock: unit = "requestPointerLock"; /* experimental */
  [@mel.send.pipe: T.t] external scrollIntoView: unit = "scrollIntoView"; /* experimental, but widely supported */
  [@mel.send.pipe: T.t]
  external scrollIntoViewNoAlignToTop: ([@mel.as {json|true|json}] _) => unit =
    "scrollIntoView"; /* experimental, but widely supported */
  [@mel.send.pipe: T.t]
  external scrollIntoViewWithOptions:
    {
      .
      "behavior": string,
      "block": string,
    } =>
    unit =
    "scrollIntoView"; /* experimental */
  [@mel.send.pipe: T.t] external scrollBy: (float, float) => unit = "scrollBy";
  [@mel.send.pipe: T.t]
  external scrollByWithOptions:
    {
      .
      "top": float,
      "left": float,
      "behavior": string,
    } =>
    unit =
    "scrollBy";
  [@mel.send.pipe: T.t] external scrollTo: (float, float) => unit = "scrollTo";
  [@mel.send.pipe: T.t]
  external scrollToWithOptions:
    {
      .
      "top": float,
      "left": float,
      "behavior": string,
    } =>
    unit =
    "scrollTo";
  [@mel.send.pipe: T.t]
  external setAttribute: (string, string) => unit = "setAttribute";
  [@mel.send.pipe: T.t]
  external setAttributeNS: (string, string, string) => unit = "setAttributeNS";
  [@mel.send.pipe: T.t]
  external setPointerCapture: Dom.eventPointerId => unit = "setPointerCapture";

  /* GlobalEventHandlers interface */
  /* Not sure this should be exposed, since EventTarget seems like a better API */

  [@mel.set]
  external setOnClick: (T.t, Dom.mouseEvent => unit) => unit = "onclick";
};

/* TODO: This doesn't work. Why?
   module Tree (T: { type t; }) => {
     include NodeRe.Impl { type t = Type };
     include EventTargetRe.Impl { type t = Type };
     include Impl { type t = Type };
   };

   include Tree { type t = Dom.element };
   */

type t = Dom.element;

include Webapi__Dom__Node.Impl({
  type nonrec t = t;
});
include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Webapi__Dom__GlobalEventHandlers.Impl({
  type nonrec t = t;
});
include Webapi__Dom__ParentNode.Impl({
  type nonrec t = t;
});
include Webapi__Dom__NonDocumentTypeChildNode.Impl({
  type nonrec t = t;
});
include Webapi__Dom__ChildNode.Impl({
  type nonrec t = t;
});
include Webapi__Dom__Slotable.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});
