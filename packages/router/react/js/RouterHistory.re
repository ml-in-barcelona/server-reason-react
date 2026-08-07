module DOM = Webapi.Dom;

type state = {
  key: string,
  revision: string,
};

[@mel.send]
external pushState: (DOM.History.t, state, string, string) => unit =
  "pushState";

[@mel.send]
external replaceState: (DOM.History.t, state, string, string) => unit =
  "replaceState";

[@mel.get]
external historyState: DOM.History.t => Js.Nullable.t(state) = "state";

[@mel.set]
external setScrollRestoration: (DOM.History.t, string) => unit =
  "scrollRestoration";

let push = (~state, ~url) => pushState(DOM.history, state, "", url);
let replace = (~state, ~url) => replaceState(DOM.history, state, "", url);
let state = () => historyState(DOM.history)->Js.Nullable.toOption;
let scrollRestoration = value => setScrollRestoration(DOM.history, value);

let listen = callback => {
  let target = DOM.Window.asEventTarget(DOM.window);
  let listener = _event => callback();
  DOM.EventTarget.addEventListener("popstate", listener, target);
  () => DOM.EventTarget.removeEventListener("popstate", listener, target);
};
