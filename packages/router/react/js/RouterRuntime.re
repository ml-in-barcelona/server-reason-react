type destination = RouterTypes.destination;
type pattern = RouterPattern.t;

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

let pattern = path =>
  switch (RouterPattern.parse(path)) {
  | Ok(pattern) => pattern
  | Error(_) => invalid_arg("invalid generated route pattern " ++ path)
  };

let destinationFromPattern = (~pattern, ~parameters, ~search) => {
  let parameter = name => List.assoc_opt(name, parameters);
  let path =
    switch (RouterPattern.render(pattern, ~parameter, ~encode=encodeSegment)) {
    | Ok(path) => path
    | Error(InvalidPattern(message)) => invalid_arg(message)
    };
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
