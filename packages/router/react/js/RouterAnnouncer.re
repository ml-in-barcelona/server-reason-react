type document;
type element;

external document: document = "document";
[@mel.get] external title: document => string = "title";
[@mel.get] external body: document => element = "body";
[@mel.send]
external createElement: (document, string) => element = "createElement";
[@mel.send]
external setAttribute: (element, string, string) => unit = "setAttribute";
[@mel.send] external appendChild: (element, element) => unit = "appendChild";
[@mel.send] external remove: element => unit = "remove";
[@mel.set] external setTextContent: (element, string) => unit = "textContent";

let hiddenStyle = "position:absolute;width:1px;height:1px;margin:-1px;padding:0;overflow:hidden;clip:rect(0 0 0 0);clip-path:inset(50%);white-space:nowrap;border:0";

let mount = () => {
  let region = createElement(document, "div");
  setAttribute(region, "aria-live", "polite");
  setAttribute(region, "aria-atomic", "true");
  setAttribute(region, "data-router-announcer", "");
  setAttribute(region, "style", hiddenStyle);
  appendChild(body(document), region);
  region;
};

let announce = region => setTextContent(region, title(document));

let unmount = remove;
