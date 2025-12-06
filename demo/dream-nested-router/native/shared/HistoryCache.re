/**
 * HistoryCache is a module that caches the pages.
 * It's used to avoid fetching the same page again when navigating back and forward.
 * For FullPage, we cache the whole page element.
 * For SubRoute, we cache only the sub-route element.
 */

type page =
  | FullPage(React.element)
  | SubRoute(React.element);

module Make = (Config: {
                 type key;
               }) => {
  type t = {
    cache: Hashtbl.t(Config.key, page),
    keyQueue: Queue.t(Config.key),
    maxSize: int,
  };

  let create = (~maxSize=10, ()) => {
    cache: Hashtbl.create(maxSize),
    keyQueue: Queue.create(),
    maxSize,
  };

  let set = (t, ~key, ~page) => {
    if (!Hashtbl.mem(t.cache, key)) {
      if (Queue.length(t.keyQueue) >= t.maxSize) {
        let oldestKey = Queue.take(t.keyQueue);
        Hashtbl.remove(t.cache, oldestKey);
      };

      Queue.add(key, t.keyQueue);
    };

    Hashtbl.replace(t.cache, key, page);
  };

  let get = (t, ~key) => {
    Hashtbl.find_opt(t.cache, key);
  };
};
