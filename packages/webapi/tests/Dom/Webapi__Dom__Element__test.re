open Webapi.Dom;
open Element;

let el = document |> Document.createElement("strong");
let el2 = document |> Document.createElement("small");
let event = PointerEvent.make("my-event");

let _ = assignedSlot(el);
let _ = attributes(el);
let _ = classList(el);
let _ = className(el);
let _ = setClassName(el, "my-class-name");
let _ = clientHeight(el);
let _ = clientLeft(el);
let _ = clientTop(el);
let _ = clientWidth(el);
let _ = id(el);
let _ = setId(el, "my-id");
let _ = innerHTML(el);
let _ = setInnerHTML(el, "<strong>stuff</strong>");
let _ = localName(el);
let _ = namespaceURI(el);
let _ = nextElementSibling(el);
let _ = outerHTML(el);
let _ = setOuterHTML(el, "<strong>stuff</strong>");
let _ = prefix(el);
let _ = previousElementSibling(el);
let _ = scrollHeight(el);
let _ = scrollLeft(el);
let _ = setScrollLeft(el, 0.0);
let _ = scrollTop(el);
let _ = setScrollTop(el, 0.0);
let _ = scrollWidth(el);
let _ = shadowRoot(el);
let _ = slot(el);
let _ = setSlot(el, "<strong>stuff</strong>");
let _ = tagName(el);

let _ = attachShadow({"mode": "open"}, el);
let _ = attachShadowOpen(el);
let _ = attachShadowClosed(el);
let _ = animate({"transform": "translateT(0px)"}, {"duration": 1000}, el);
let _ = closest("input", el);
let _ = createShadowRoot(el);
let _ = getAttribute("href", el);
let _ = getAttributeNS("http://...", "foo", el);
let _ = getBoundingClientRect(el);
let _ = getClientRects(el);
let _ = getElementsByClassName("some-class-name", el);
let _ = getElementsByTagName("pre", el);
let _ = getElementsByTagNameNS("http://...", "td", el);
let _ = hasAttribute("data-my-value", el);
let _ = hasAttributeNS("http://...", "foo", el);
let _ = hasAttributes(el);
let _ = insertAdjacentElement(BeforeBegin, el2, el);
let _ = insertAdjacentHTML(AfterBegin, "<strong>text</strong>", el);
let _ = insertAdjacentText(AfterEnd, "text", el);
let _ = matches("input", el);
let _ = querySelector("input", el);
let _ = querySelectorAll("input", el);
let _ = releasePointerCapture(PointerEvent.pointerId(event), el);
let _ = remove(el);
let _ = removeAttribute("href", el);
let _ = removeAttributeNS("http://...", "foo", el);
let _ = requestFullscreen(el);
let _ = requestPointerLock(el);
let _ = scrollIntoView(el);
/*let _ = scrollIntoViewNoAlignToTop(el);*/
let _ = scrollIntoViewNoAlignToTop(el);
let _ =
  scrollIntoViewWithOptions(
    {
      "block": "end",
      "behavior": "smooth",
    },
    el,
  );
let _ = setAttribute("href", "http://...", el);
let _ = setAttributeNS("http://...", "foo", "bar", el);
let _ = setPointerCapture(PointerEvent.pointerId(event), el);
