type t = Dom.history;

[@mel.get] external length: t => int = "length";
[@mel.get] external scrollRestoration: t => bool = "scrollRestoration"; /* experimental */
[@mel.set]
external setScrollRestoration: (t, bool) => unit = "scrollRestoration"; /* experimental */
[@mel.get] external state: t => 'a = "state";

[@mel.send.pipe: t] external back: unit = "back";
[@mel.send.pipe: t] external forward: unit = "forward";
[@mel.send.pipe: t] external go: int => unit = "go";
[@mel.send.pipe: t]
external pushState: ('a, string, string) => unit = "pushState";
[@mel.send.pipe: t]
external replaceState: ('a, string, string) => unit = "replaceState";
