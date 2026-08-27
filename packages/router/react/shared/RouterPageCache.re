module Navigation = RouterRuntime.Navigation;

type page = {
  canonicalUrl: string,
  revision: string,
  matches: list(Navigation.matched),
  layouts: list(Navigation.layout),
  metadata: React.element,
  element: React.element,
};

type t = {
  capacity: int,
  mutable entries: list((string, page)),
};

let make = (~capacity, ()) => {
  capacity,
  entries: [],
};

let find = (cache, key) =>
  switch (List.assoc_opt(key, cache.entries)) {
  | None => None
  | Some(page) =>
    cache.entries = [(key, page), ...List.remove_assoc(key, cache.entries)];
    Some(page);
  };

let set = (cache, key, page) =>
  if (cache.capacity > 0) {
    let entries = [(key, page), ...List.remove_assoc(key, cache.entries)];
    let rec take = (remaining, entries) =>
      if (remaining <= 0) {
        [];
      } else {
        switch (entries) {
        | [] => []
        | [entry, ...entries] => [entry, ...take(remaining - 1, entries)]
        };
      };
    cache.entries = take(cache.capacity, entries);
  };

let length = cache => List.length(cache.entries);
