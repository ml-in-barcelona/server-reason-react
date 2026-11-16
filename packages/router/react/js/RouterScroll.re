type position = (float, float);

type storage;

external sessionStorage: storage = "sessionStorage";
[@mel.send] [@mel.return nullable]
external getItem: (storage, string) => option(string) = "getItem";
[@mel.send] external setItem: (storage, string, string) => unit = "setItem";

let storageKey = "server-reason-react.router.scroll";
let limit = 100;

let entryId = (~revision, ~key) => revision ++ " " ++ key;

let memory: ref(list((string, position))) = ref([]);
let storageFailed = ref(false);

let decodeEntry = json =>
  switch (Js.Json.decodeArray(json)) {
  | Some([|id, x, y|]) =>
    switch (
      Js.Json.decodeString(id),
      Js.Json.decodeNumber(x),
      Js.Json.decodeNumber(y),
    ) {
    | (Some(id), Some(x), Some(y)) => Some((id, (x, y)))
    | _ => None
    }
  | _ => None
  };

let encodeEntry = ((id, (x, y))) =>
  Js.Json.array([|
    Js.Json.string(id),
    Js.Json.number(x),
    Js.Json.number(y),
  |]);

let stored = () =>
  try(
    switch (getItem(sessionStorage, storageKey)) {
    | None => Some([])
    | Some(text) =>
      switch (Js.Json.decodeArray(Js.Json.parseExn(text))) {
      | Some(entries) =>
        Some(entries |> Array.to_list |> List.filter_map(decodeEntry))
      | None => Some([])
      }
    }
  ) {
  | _ => None
  };

let entries = () =>
  if (storageFailed^) {
    memory^;
  } else {
    switch (stored()) {
    | Some(entries) => entries
    | None =>
      storageFailed := true;
      memory^;
    };
  };

let rec take = (count, values) =>
  switch (values) {
  | [value, ...values] when count > 0 => [value, ...take(count - 1, values)]
  | _ => []
  };

let save = (id, position) => {
  let next =
    take(limit, [(id, position), ...List.remove_assoc(id, entries())]);
  memory := next;
  try(
    setItem(
      sessionStorage,
      storageKey,
      Js.Json.stringify(
        Js.Json.array(next |> List.map(encodeEntry) |> Array.of_list),
      ),
    )
  ) {
  | _ => storageFailed := true
  };
};

let find = id => List.assoc_opt(id, entries());
