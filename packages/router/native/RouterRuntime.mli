type destination = RouterTypes.destination

module Status = RouterTypes.Status
module Loader = RouterTypes.Loader
module Error = RouterTypes.Error
module Metadata = RouterTypes.Metadata
module Headers = RouterTypes.Headers
module Navigation = RouterTypes.Navigation
module Search = RouterTypes.Search
module NavigationResponse = RouterTypes.NavigationResponse
module Link = RouterTypes.Link

val destination : path:string -> destination

val destinationFromPattern :
  pattern:string -> parameters:(string * string) list -> search:(string * string list) list -> destination

val href : destination -> string
