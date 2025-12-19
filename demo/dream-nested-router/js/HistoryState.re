module DOM = Webapi.Dom;
module History = DOM.History;

/**
 * Melange webapi don't set state type, so we use Obj.magic to cast it to the correct type while the PR is not merged.
 * https://github.com/melange-community/melange-webapi/blob/80c6ededd06cc66b75445d1ed5c855e050b156a0/src/Webapi/Dom/Webapi__Dom__History.re#L2
 * PR: https://github.com/melange-community/melange-webapi/pull/29
 */
[@platform js]
type t = History.state;

let fromEvent = event =>
  DOM.Event.target(event)
  ->DOM.EventTarget.unsafeAsWindow
  ->DOM.Window.history
  ->History.state;

let toJs: History.state => Js.t({..}) = state => state |> Obj.magic;
let fromJs: Js.t({..}) => History.state = state => state |> Obj.magic;

[@platform js]
let push = (state, path) => {
  History.pushState(state, "", path, DOM.history);
  let _ =
    DOM.EventTarget.dispatchEvent(
      DOM.Event.make("popstate"),
      DOM.Window.asEventTarget(DOM.window),
    );
  ();
};

[@platform js]
let replace = (state, path) => {
  History.replaceState(state, "", path, DOM.history);
  let _ =
    DOM.EventTarget.dispatchEvent(
      DOM.Event.make("popstate"),
      DOM.Window.asEventTarget(DOM.window),
    );
  ();
};
