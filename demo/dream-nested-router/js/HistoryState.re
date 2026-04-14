module DOM = Webapi.Dom;

/* Custom History bindings with polymorphic state, replacing the upstream opaque type from melange-webapi. Also waiting for the PR to be merged: https://github.com/melange-community/melange-webapi/pull/29 */
module History = {
  type t = Dom.history;

  [@mel.get] external state: t => 'a = "state";

  [@mel.send]
  external pushState: ([@mel.this] t, 'a, string, string) => unit =
    "pushState";

  [@mel.send]
  external replaceState: ([@mel.this] t, 'a, string, string) => unit =
    "replaceState";
};

let fromEvent = event =>
  DOM.Event.target(event)
  ->DOM.EventTarget.unsafeAsWindow
  ->DOM.Window.history
  ->History.state;

[@platform js]
let push = (state, path) => {
  History.pushState(DOM.history, state, "", path);
  let (_: bool) =
    DOM.EventTarget.dispatchEvent(
      DOM.Event.make("popstate"),
      DOM.Window.asEventTarget(DOM.window),
    );
  ();
};

[@platform js]
let replace = (state, path) => {
  History.replaceState(DOM.history, state, "", path);
  let (_: bool) =
    DOM.EventTarget.dispatchEvent(
      DOM.Event.make("popstate"),
      DOM.Window.asEventTarget(DOM.window),
    );
  ();
};
