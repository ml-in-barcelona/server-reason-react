let make = cns => cns->Belt.List.keep(x => x !== "") |> String.concat(" ");

let ifTrue = (cn, x) => x ? cn : "";

let ifSome = (cn, x) =>
  switch (x) {
  | Some(_) => cn
  | None => ""
  };

let mapSome = (x, fn) =>
  switch (x) {
  | Some(x) => fn(x)
  | None => ""
  };

let unpack =
  fun
  | Some(x) => x
  | None => "";
