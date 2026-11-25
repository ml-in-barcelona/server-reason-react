type pattern = RouterPattern.t

let encode = Js.Global.encodeURIComponent

let encodeSegment value =
  if not (RouterPattern.validSegment value) then invalid_arg "route parameters must be valid non-empty path segments";
  encode value

let pattern path =
  match RouterPattern.parseTemplate path with
  | Ok pattern -> pattern
  | Error _ -> invalid_arg ("invalid generated route pattern " ^ path)

let encodeSearch search =
  search
  |> List.sort (fun (left, _) (right, _) -> String.compare left right)
  |> List.concat_map (fun (name, values) -> List.map (fun value -> encode name ^ "=" ^ encode value) values)
  |> String.concat "&"

let destinationFromPattern ~pattern ~parameters ~search =
  RouterTypes.renderDestination ~pattern ~parameters ~search ~encodeParameter:encodeSegment ~encodeSearch

let withHash = RouterTypes.destinationWithHash ~encode
