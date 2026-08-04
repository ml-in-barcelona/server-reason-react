type destination = RouterTypes.destination;

module Status = RouterTypes.Status;
module Loader = RouterTypes.Loader;
module Error = RouterTypes.Error;
module Metadata = RouterTypes.Metadata;
module Headers = RouterTypes.Headers;
module Navigation = RouterTypes.Navigation;
module Search = RouterTypes.Search;
module NavigationResponse = RouterTypes.NavigationResponse;
module Link = RouterTypes.Link;

let encode = Js.Global.encodeURIComponent;
let encodeSegment = value => {
  if (value == "" || value == "." || value == "..") {
    invalid_arg("route parameters must be non-empty path segments");
  };
  encode(value);
};
let destination: (~path: string) => destination = (~path) =>
  RouterTypes.makeDestination(path);

let destinationFromPattern = (~pattern, ~parameters, ~search) => {
  let parameter = name =>
    switch (List.assoc_opt(name, parameters)) {
    | Some(value) => encodeSegment(value)
    | None => invalid_arg("missing generated route parameter " ++ name)
    };
  let length = String.length(pattern);
  let buffer = Buffer.create(length);
  let rec copy = index =>
    if (index >= length) {
      ();
    } else if (pattern.[index] != ':') {
      Buffer.add_char(buffer, pattern.[index]);
      copy(index + 1);
    } else {
      switch (String.index_from_opt(pattern, index + 1, '<')) {
      | None => invalid_arg("generated route parameter has no type")
      | Some(opening) =>
        switch (String.index_from_opt(pattern, opening + 1, '>')) {
        | None =>
          invalid_arg("generated route parameter type is unterminated")
        | Some(closing) =>
          let name = String.sub(pattern, index + 1, opening - index - 1);
          Buffer.add_string(buffer, parameter(name));
          copy(closing + 1);
        }
      };
    };
  copy(0);
  let path = Buffer.contents(buffer);
  let search =
    search
    |> List.sort(((left, _), (right, _)) => String.compare(left, right))
    |> List.concat_map(((name, values)) =>
         List.map(value => encode(name) ++ "=" ++ encode(value), values)
       )
    |> String.concat("&");
  let finalPath: string = search == "" ? path : path ++ "?" ++ search;
  destination(~path=finalPath);
};

let href = RouterTypes.destinationHref;
