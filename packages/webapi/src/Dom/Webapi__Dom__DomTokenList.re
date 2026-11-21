type t = Dom.domTokenList;

[@mel.get] external length: t => int = "length";

[@mel.send.pipe: t] [@mel.return nullable]
external item: int => option(string) = "item";
[@mel.send.pipe: t] external add: string => unit = "add";
[@mel.send.pipe: t] [@mel.splice]
external addMany: array(string) => unit = "add";
[@mel.send.pipe: t] external contains: string => bool = "contains";
[@mel.send.pipe: t]
external forEach: ((string, int) => unit) => unit = "forEach";
[@mel.send.pipe: t] external remove: string => unit = "remove";
[@mel.send.pipe: t] [@mel.splice]
external removeMany: array(string) => unit = "remove";
[@mel.send.pipe: t] external replace: (string, string) => unit = "replace";
[@mel.send.pipe: t] external supports: string => bool = "supports";
[@mel.send.pipe: t] external toggle: string => bool = "toggle";
[@mel.send.pipe: t]
external toggleForced: (string, [@mel.as {json|true|json}] _) => bool =
  "toggle";
[@mel.send.pipe: t] external toString: string = "toString";

[@mel.get] external value: t => string = "value";
[@mel.set] external setValue: (t, string) => unit = "value";
