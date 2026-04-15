type t = Dom.history;
type state; /* TODO: should be "anything that can be serializable" apparently */

[@mel.get] external length: t => int = "length";
[@mel.get] external scrollRestoration: t => bool = "scrollRestoration"; /* experimental */
[@mel.set]
external setScrollRestoration: (t, bool) => unit = "scrollRestoration"; /* experimental */
[@mel.get] external state: t => state = "state";

[@mel.send.pipe: t] external back: unit = "back";
[@mel.send.pipe: t] external forward: unit = "forward";
[@mel.send.pipe: t] external go: int => unit = "go";
[@mel.send.pipe: t]
external pushState: (state, string, string) => unit = "pushState";
[@mel.send.pipe: t]
external replaceState: (state, string, string) => unit = "replaceState";
