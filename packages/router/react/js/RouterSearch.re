let valuesFromString = search =>
  Webapi.Url.URLSearchParams.make(search)
  |> Webapi.Url.URLSearchParams.entries
  |> Js.Array.from
  |> Array.fold_left(
       (values, (name, value)) =>
         switch (List.assoc_opt(name, values)) {
         | None => [(name, [value]), ...values]
         | Some(current) => [
             (name, current @ [value]),
             ...List.remove_assoc(name, values),
           ]
         },
       [],
     )
  |> List.rev;

let toString = values => {
  let encoded = RouterRuntime.encodeSearch(values);
  String.equal(encoded, "") ? "" : "?" ++ encoded;
};

/* The address bar may hold another spelling of the same values (`+` for a
   space, another order), so both sides go through the same encoder. */
let unchanged = (~current, ~next) =>
  String.equal(toString(valuesFromString(current)), toString(next));
