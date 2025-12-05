/**
 * HistoryCache is a module that caches the pages.
 * It's used to avoid fetching the same page again when navigating back and forward.
 * For FullPage, we cache the whole page element.
 * For SubRoute, we cache only the sub-route element.
 */

type cacheKey = {
  path: string,
  dynamicParams: DynamicParams.t,
};

type page =
  | FullPage(React.element)
  | SubRoute(React.element);

let maxCacheSize = 10;
let cache: Hashtbl.t(string, page) = Hashtbl.create(maxCacheSize);
let keyQueue: Queue.t(string) = Queue.create();

let createCacheKey = (path, dynamicParams) =>
  path
  ++ "|"
  ++ (dynamicParams |> DynamicParams.to_json |> Melange_json.to_string);

let set = (path, dynamicParams, page) => {
  let key = createCacheKey(path, dynamicParams);

  if (!Hashtbl.mem(cache, key)) {
    if (Queue.length(keyQueue) >= maxCacheSize) {
      let oldestKey = Queue.take(keyQueue);
      Hashtbl.remove(cache, oldestKey);
    };

    Queue.add(key, keyQueue);
  };

  Hashtbl.replace(cache, key, page);
};

let get = (path, dynamicParams) => {
  Hashtbl.find_opt(cache, createCacheKey(path, dynamicParams));
};
