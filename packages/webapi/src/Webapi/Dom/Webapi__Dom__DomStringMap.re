type t = Dom.domStringMap;

type key = string;

[@mel.get_index] [@mel.return nullable]
external get: (t, key) => option(string);
let get = (key, map) => get(map, key);
[@mel.set_index] external set: (t, key, string) => unit;
let set = (key, value, map) => set(map, key, value);
let unsafeDeleteKey: (key, t) => unit = [%raw
  "function(key, map) { delete map[key] }"
];
