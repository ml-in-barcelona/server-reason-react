let hex = "0123456789ABCDEF"

let encode value =
  let unescaped = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '_' | '.' | '!' | '~' | '*' | '\'' | '(' | ')' -> true
    | _ -> false
  in
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

let () =
  let invalid = [ "/query?value"; "/fragment#value"; "/literal%20escape"; "/malformed%escape"; "/."; "/.." ] in
  List.iter
    (fun path -> match RouterPattern.parse path with Ok _ -> failwith ("accepted " ^ path) | Error _ -> ())
    invalid;
  let pattern =
    match RouterPattern.parse "/café/東京" with Ok pattern -> pattern | Error _ -> failwith "rejected UTF-8 path"
  in
  let rendered =
    match RouterPattern.render pattern ~parameter:(fun _ -> None) ~encode with
    | Ok rendered -> rendered
    | Error _ -> failwith "failed to render UTF-8 path"
  in
  if rendered <> "/caf%C3%A9/%E6%9D%B1%E4%BA%AC" then failwith rendered;
  print_endline "static path grammar and UTF-8 href rendering passed"
