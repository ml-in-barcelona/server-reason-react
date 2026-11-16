let unreserved = function
  | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '-' | '_' | '.' | '!' | '~' | '*' | '\'' | '(' | ')' -> true
  | _ -> false

let encode value =
  let buffer = Buffer.create (String.length value) in
  String.iter
    (fun character ->
      if unreserved character then Buffer.add_char buffer character
      else Buffer.add_string buffer (Printf.sprintf "%%%02X" (Char.code character)))
    value;
  Buffer.contents buffer

let native search =
  match RouterQuery.parse search with
  | Ok values -> Ok values
  | Error (RouterQuery.MalformedEscape raw) -> Error ("malformed " ^ raw)
  | Error RouterQuery.QueryTooLong -> Error "too long"

let shared search =
  match
    RouterSearchParse.parse ~text:Fun.id ~slice:(fun value start stop -> String.sub value start (stop - start)) search
  with
  | Ok values -> Ok values
  | Error (RouterSearchParse.MalformedEscape raw) -> Error ("malformed " ^ raw)
  | Error RouterSearchParse.QueryTooLong -> Error "too long"

let check name parse =
  match SearchParseCases.failures ~parse ~encode with
  | [] -> ()
  | failures -> failwith (name ^ " differs from the case table: " ^ String.concat ", " failures)

let () =
  check "native RouterQuery.parse" native;
  check "shared RouterSearchParse on native" shared
