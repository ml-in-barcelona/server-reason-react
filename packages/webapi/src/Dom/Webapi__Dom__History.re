type t = Dom.history;
type state;

[@mel.get] external length: t => int = "length";
[@mel.get] external scrollRestoration: t => bool = "scrollRestoration";
[@mel.set]
external setScrollRestoration: (t, bool) => unit = "scrollRestoration";
[@mel.get] external state: t => state = "state";

[@mel.send.pipe: t] external back: unit = "back";
[@mel.send.pipe: t] external forward: unit = "forward";
[@mel.send.pipe: t] external go: int => unit = "go";
[@mel.send.pipe: t]
external pushState: (state, string, string) => unit = "pushState";
[@mel.send.pipe: t]
external replaceState: (state, string, string) => unit = "replaceState";
