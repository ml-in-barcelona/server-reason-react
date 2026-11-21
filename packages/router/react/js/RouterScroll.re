type position = (float, float);

type saved = {
  window: position,
  containers: list((string, position)),
};

type storage;

external sessionStorage: storage = "sessionStorage";
[@mel.send] [@mel.return nullable]
external getItem: (storage, string) => option(string) = "getItem";
[@mel.send] external setItem: (storage, string, string) => unit = "setItem";

let storageKey = "server-reason-react.router.scroll";
let limit = 100;

let containerPositions: unit => array((string, position)) = [%mel.raw
  {|() => {
  const seen = new Set();
  const positions = [];
  for (const element of document.querySelectorAll("[data-router-scroll]")) {
    const id = element.getAttribute("data-router-scroll");
    if (id === "" || seen.has(id)) continue;
    seen.add(id);
    positions.push([id, [element.scrollLeft, element.scrollTop]]);
  }
  return positions;
}|}
];

let scrollContainers: array((string, position)) => unit = [%mel.raw
  {|(positions) => {
  const saved = new Map(positions);
  const seen = new Set();
  for (const element of document.querySelectorAll("[data-router-scroll]")) {
    const id = element.getAttribute("data-router-scroll");
    if (seen.has(id) || !saved.has(id)) continue;
    seen.add(id);
    const [x, y] = saved.get(id);
    element.scrollTo(x, y);
  }
}|}
];

let capture = window => {
  window,
  containers: Array.to_list(containerPositions()),
};

let restoreContainers = saved =>
  switch (saved.containers) {
  | [] => ()
  | containers => scrollContainers(Array.of_list(containers))
  };

let entryId = (~revision, ~key) => revision ++ " " ++ key;

let memory: ref(list((string, saved))) = ref([]);
let storageFailed = ref(false);

let decodePosition = (x, y) =>
  switch (Js.Json.decodeNumber(x), Js.Json.decodeNumber(y)) {
  | (Some(x), Some(y)) => Some((x, y))
  | _ => None
  };

let decodeContainer = json =>
  switch (Js.Json.decodeArray(json)) {
  | Some([|id, x, y|]) =>
    switch (Js.Json.decodeString(id), decodePosition(x, y)) {
    | (Some(id), Some(position)) => Some((id, position))
    | _ => None
    }
  | _ => None
  };

let decodeEntry = json => {
  let entry = (id, x, y, containers) =>
    switch (Js.Json.decodeString(id), decodePosition(x, y)) {
    | (Some(id), Some(window)) =>
      Some((
        id,
        {
          window,
          containers,
        },
      ))
    | _ => None
    };
  switch (Js.Json.decodeArray(json)) {
  | Some([|id, x, y|]) => entry(id, x, y, [])
  | Some([|id, x, y, containers|]) =>
    switch (Js.Json.decodeArray(containers)) {
    | Some(containers) =>
      entry(
        id,
        x,
        y,
        containers |> Array.to_list |> List.filter_map(decodeContainer),
      )
    | None => None
    }
  | _ => None
  };
};

let encodeContainer = ((id, (x, y))) =>
  Js.Json.array([|
    Js.Json.string(id),
    Js.Json.number(x),
    Js.Json.number(y),
  |]);

let encodeEntry = ((id, { window: (x, y), containers })) =>
  Js.Json.array(
    Array.append(
      [|Js.Json.string(id), Js.Json.number(x), Js.Json.number(y)|],
      switch (containers) {
      | [] => [||]
      | containers => [|
          Js.Json.array(
            containers |> List.map(encodeContainer) |> Array.of_list,
          ),
        |]
      },
    ),
  );

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

let save = (id, saved) => {
  let next =
    take(limit, [(id, saved), ...List.remove_assoc(id, entries())]);
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
