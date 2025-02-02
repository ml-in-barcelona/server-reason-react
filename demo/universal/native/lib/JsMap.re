[@platform js]
include {
          type t('k, 'v);

          [@mel.new] external make: unit => t('k, 'v) = "Map";

          [@mel.send] [@mel.return nullable]
          external get: (t('k, 'v), 'k) => option('v) = "get";

          [@mel.send] external set: (t('k, 'v), 'k, 'v) => unit = "set";

          [@mel.send] external delete: (t('k, 'v), 'k) => unit = "delete";

          [@mel.send] external clear: t('k, 'v) => unit = "clear";

          [@mel.send] external size: t('k, 'v) => int = "size";

          [@mel.send] external has: (t('k, 'v), 'k) => bool = "has";

          [@mel.send] external values: t('k, 'v) => array('v) = "values";

          [@mel.send] external keys: t('k, 'v) => array('k) = "keys";

          [@mel.send]
          external entries: t('k, 'v) => array(('k, 'v)) = "entries";

          [@mel.send]
          external forEach: (t('k, 'v), ('k, 'v) => unit) => unit = "forEach";
        };

[@platform native]
include {
          type t('k, 'v) = {mutable entries: list(('k, 'v))};

          let make = () => {entries: []};

          let set = (map, k, v) => {
            let rec update = entries =>
              switch (entries) {
              | [] => [(k, v)]
              | [(k', _), ...rest] when k == k' => [(k, v), ...rest]
              | [pair, ...rest] => [pair, ...update(rest)]
              };
            map.entries = update(map.entries);
            map;
          };

          let get = (map, k) =>
            map.entries
            |> List.find_opt(((k', _)) => k == k')
            |> Option.map(((_, v)) => v);

          let delete = (map, k) => {
            map.entries = List.filter(((k', _)) => k != k', map.entries);
            map;
          };

          let clear = map => {
            map.entries = [];
            map;
          };

          let size = map => List.length(map.entries);

          let has = (map, k) =>
            List.exists(((k', _)) => k == k', map.entries);

          let values = map => List.map(((_, v)) => v, map.entries);

          let keys = map => List.map(((k, _)) => k, map.entries);

          let entries = map => map.entries;

          let forEach = (map, f) =>
            List.iter(((k, v)) => f(v, k, map), map.entries);
        };
