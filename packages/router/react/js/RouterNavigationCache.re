module Navigation = RouterTypes.Navigation;

type layer('bytes) = {
  graftAt: option(string),
  bytes: 'bytes,
};

type entry('bytes) = {
  scope: string,
  pathname: string,
  search: string,
  layers: list(layer('bytes)),
  storedAt: float,
  mutable prefetched: bool,
};

type invalidation =
  | All
  | Prefix(string);

type t('bytes) = {
  capacity: int,
  maxAge: float,
  mutable entries: list(entry('bytes)),
  mutable generation: int,
  mutable invalidations: list((int, invalidation)),
};

let make = (~capacity, ~maxAge) => {
  capacity,
  maxAge,
  entries: [],
  generation: 0,
  invalidations: [],
};

let generation = cache => cache.generation;

let storable = (~httpStatus, ~status) =>
  httpStatus >= 200 && httpStatus < 300 && status >= 200 && status < 300;

let scope = (~protocolVersion, ~registryFingerprint) =>
  string_of_int(protocolVersion) ++ "." ++ registryFingerprint;

let same = (~scope, ~pathname, ~search, entry) =>
  String.equal(entry.scope, scope)
  && String.equal(entry.pathname, pathname)
  && String.equal(entry.search, search);

let rec take = (count, values) =>
  switch (values) {
  | [value, ...values] when count > 0 => [value, ...take(count - 1, values)]
  | _ => []
  };

let prefetchWindow = 30000.0;

let fresh = (cache, ~now, entry) =>
  now
  -. entry.storedAt < cache.maxAge
  || entry.prefetched
  && now
  -. entry.storedAt < prefetchWindow;

let readable = (cache, ~action, ~revalidate, ~now, entry) =>
  !revalidate
  && (
    switch (action) {
    | Navigation.Pop => true
    | Navigation.Push
    | Navigation.Replace => fresh(cache, ~now, entry)
    }
  );

let read = (cache, ~scope, ~pathname, ~search, ~action, ~revalidate, ~now) =>
  switch (List.find_opt(same(~scope, ~pathname, ~search), cache.entries)) {
  | Some(entry) when readable(cache, ~action, ~revalidate, ~now, entry) =>
    switch (action) {
    | Navigation.Push
    | Navigation.Replace => entry.prefetched = false
    | Navigation.Pop => ()
    };
    cache.entries = [
      entry,
      ...List.filter(other => other !== entry, cache.entries),
    ];
    Some(entry);
  | Some(_)
  | None => None
  };

let hasFresh = (cache, ~scope, ~pathname, ~search, ~now) =>
  List.exists(
    entry =>
      same(~scope, ~pathname, ~search, entry) && fresh(cache, ~now, entry),
    cache.entries,
  );

let underPrefix = (~prefix, pathname) =>
  String.equal(prefix, "/")
  || String.equal(pathname, prefix)
  || String.starts_with(
       ~prefix=String.ends_with(~suffix="/", prefix) ? prefix : prefix ++ "/",
       pathname,
     );

let matches = (invalidation, pathname) =>
  switch (invalidation) {
  | All => true
  | Prefix(prefix) => underPrefix(~prefix, pathname)
  };

let invalidatedSince = (cache, ~startedIn, pathname) =>
  cache.generation
  - startedIn > List.length(cache.invalidations)
  || List.exists(
       ((generation, invalidation)) =>
         generation > startedIn && matches(invalidation, pathname),
       cache.invalidations,
     );

let store =
    (
      cache,
      ~scope,
      ~pathname,
      ~search,
      ~now,
      ~startedIn,
      ~prefetched=false,
      layers,
    ) =>
  if (cache.capacity > 0 && !invalidatedSince(cache, ~startedIn, pathname)) {
    let entry = {
      scope,
      pathname,
      search,
      layers,
      storedAt: now,
      prefetched,
    };
    cache.entries =
      take(
        cache.capacity,
        [
          entry,
          ...List.filter(
               other => !same(~scope, ~pathname, ~search, other),
               cache.entries,
             ),
        ],
      );
  };

let compose = (layers, ~graftAt, ~layouts, bytes) => {
  let rec ancestors = layouts =>
    switch (layouts) {
    | [] => []
    | [layout, ..._] when String.equal(layout, graftAt) => []
    | [layout, ...layouts] => [layout, ...ancestors(layouts)]
    };
  let ancestors = ancestors(layouts);
  List.filter(
    layer =>
      switch (layer.graftAt) {
      | None => true
      | Some(owner) => List.mem(owner, ancestors)
      },
    layers,
  )
  @ [
    {
      graftAt: Some(graftAt),
      bytes,
    },
  ];
};

let invalidate = (cache, invalidation) => {
  cache.generation = cache.generation + 1;
  cache.invalidations =
    take(64, [(cache.generation, invalidation), ...cache.invalidations]);
  cache.entries =
    List.filter(
      entry => !matches(invalidation, entry.pathname),
      cache.entries,
    );
};

let sendsPatchBase = (cache, ~revalidate, ~composable) =>
  !revalidate && (cache.capacity == 0 || composable);

let length = cache => List.length(cache.entries);
