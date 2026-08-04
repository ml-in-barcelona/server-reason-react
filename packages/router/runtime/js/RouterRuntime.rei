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

let destination: (~path: string) => destination;

let destinationFromPattern:
  (
    ~pattern: string,
    ~parameters: list((string, string)),
    ~search: list((string, list(string)))
  ) =>
  destination;

let href: destination => string;
