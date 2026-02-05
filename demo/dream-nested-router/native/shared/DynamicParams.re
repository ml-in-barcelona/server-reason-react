open Melange_json.Primitives;

[@deriving json]
type t = array((string, string));

let create = () => [||];

let add = (t, key, value) => {
  Array.append(t, [|(key, value)|]);
};

let find = (paramKey, t) =>
  if (Array.length(t) == 0) {
    None;
  } else {
    Array.find_map(
      ((key, value)) => {key == paramKey ? Some(value) : None},
      t,
    );
  };
