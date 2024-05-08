type t = Yojson.Basic.t

module Decode = Json_decode
module Encode = Json_encode

exception ParseError of string

let stringify = Yojson.Basic.to_string
let parse s = try Some (Yojson.Basic.from_string s) with _ -> None

let parseOrRaise value =
  try Yojson.Basic.from_string value
  with Yojson.Json_error msg -> raise @@ ParseError msg
