type destination = RouterTypes.destination
type pattern = RouterPattern.t

module Status = RouterTypes.Status
module Loader = RouterTypes.Loader
module Error = RouterTypes.Error
module Metadata = RouterTypes.Metadata
module Headers = RouterTypes.Headers
module Navigation = RouterTypes.Navigation
module Search = RouterTypes.Search
module CatchAll = RouterTypes.CatchAll
module NavigationResponse = RouterTypes.NavigationResponse
module Link = RouterTypes.Link

let encode = RouterPattern.encodeStaticSegment

let encodeSegment value =
  if
    value = "" || value = "." || value = ".." || String.contains value '/'
    || (not (RouterUtf8.valid value))
    || not (String.for_all (fun character -> Char.code character >= 0x20 && Char.code character <> 0x7f) value)
  then invalid_arg "route parameters must be valid non-empty path segments";
  encode value

let destination ~path = RouterTypes.makeDestination path

let pattern path =
  match RouterPattern.parse path with
  | Ok pattern -> pattern
  | Error _ -> invalid_arg ("invalid generated route pattern " ^ path)

let destinationFromPattern ~pattern ~parameters ~search =
  let parameter name = List.assoc_opt name parameters in
  let path =
    match
      RouterPattern.render pattern ~parameter ~encodeStatic:RouterPattern.encodeStaticSegment
        ~encodeParameter:encodeSegment
    with
    | Ok path -> path
    | Error (InvalidPattern message) -> invalid_arg message
  in
  let search =
    search
    |> List.sort (fun (left, _) (right, _) -> String.compare left right)
    |> List.concat_map (fun (name, values) -> List.map (fun value -> encode name ^ "=" ^ encode value) values)
    |> String.concat "&"
  in
  destination ~path:(if search = "" then path else path ^ "?" ^ search)

let href = RouterTypes.destinationHref
