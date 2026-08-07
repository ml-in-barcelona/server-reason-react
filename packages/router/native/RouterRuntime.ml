type destination = RouterTypes.destination
type pattern = RouterPattern.t

module Status = RouterTypes.Status
module Loader = RouterTypes.Loader
module Error = RouterTypes.Error
module Metadata = RouterTypes.Metadata
module Headers = RouterTypes.Headers
module Navigation = RouterTypes.Navigation
module Search = RouterTypes.Search
module NavigationResponse = RouterTypes.NavigationResponse
module Link = RouterTypes.Link

let hex = "0123456789ABCDEF"

let unescaped = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '_' | '.' | '!' | '~' | '*' | '\'' | '(' | ')' -> true
  | _ -> false

let encode value =
  let buffer = Buffer.create (String.length value) in
  String.iter
    (fun character ->
      if unescaped character then Buffer.add_char buffer character
      else
        let code = Char.code character in
        Buffer.add_char buffer '%';
        Buffer.add_char buffer hex.[code lsr 4];
        Buffer.add_char buffer hex.[code land 0x0f])
    value;
  Buffer.contents buffer

let encodeSegment value =
  if value = "" || value = "." || value = ".." then invalid_arg "route parameters must be non-empty path segments";
  encode value

let destination ~path = RouterTypes.makeDestination path

let pattern path =
  match RouterPattern.parse path with
  | Ok pattern -> pattern
  | Error _ -> invalid_arg ("invalid generated route pattern " ^ path)

let destinationFromPattern ~pattern ~parameters ~search =
  let parameter name = List.assoc_opt name parameters in
  let path =
    match RouterPattern.render pattern ~parameter ~encode:encodeSegment with
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
