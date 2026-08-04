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

let destinationFromPattern ~pattern ~parameters ~search =
  let parameter name =
    match List.assoc_opt name parameters with
    | Some value -> value
    | None -> invalid_arg ("missing generated route parameter " ^ name)
  in
  let length = String.length pattern in
  let buffer = Buffer.create length in
  let rec copy index =
    if index >= length then ()
    else if pattern.[index] <> ':' then (
      Buffer.add_char buffer pattern.[index];
      copy (index + 1))
    else
      match String.index_from_opt pattern (index + 1) '<' with
      | None -> invalid_arg "generated route parameter has no type"
      | Some opening -> (
          match String.index_from_opt pattern (opening + 1) '>' with
          | None -> invalid_arg "generated route parameter type is unterminated"
          | Some closing ->
              let name = String.sub pattern (index + 1) (opening - index - 1) in
              Buffer.add_string buffer (parameter name |> encodeSegment);
              copy (closing + 1))
  in
  copy 0;
  let path = Buffer.contents buffer in
  let search =
    search
    |> List.sort (fun (left, _) (right, _) -> String.compare left right)
    |> List.concat_map (fun (name, values) -> List.map (fun value -> encode name ^ "=" ^ encode value) values)
    |> String.concat "&"
  in
  destination ~path:(if search = "" then path else path ^ "?" ^ search)

let href = RouterTypes.destinationHref
