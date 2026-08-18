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
  let valid =
    [
      "";
      "/";
      "/notes";
      "/:_id<int>";
      "/:userId<string>";
      "/:enabled<bool>";
      "/:id'<Foo.t>";
      "/:id<Foo.t>";
      "/:id<Foo.Bar_2.t>";
      "/:parts<string...>";
      "/assets/:parts<string...>";
      "/:id<Foo.t>/:parts<string...>";
    ]
  in
  List.iter
    (fun path -> match RouterPattern.parse path with Ok _ -> () | Error _ -> failwith ("rejected " ^ path))
    valid;
  let invalid =
    [
      "notes";
      "/notes/";
      "/notes//edit";
      "/query?value";
      "/fragment#value";
      "/literal%20escape";
      "/malformed%escape";
      "/.";
      "/..";
      "/:<int>";
      "/:Id<int>";
      "/:1id<int>";
      "/:user-id<int>";
      "/:id";
      "/:id<>";
      "/:id<int";
      "/:id<int>>";
      "/:id<<int>";
      "/:id<t>";
      "/:id<float>";
      "/:id<Bool>";
      "/:id<bool.t>";
      "/:id<foo.t>";
      "/:id<1Foo.t>";
      "/:id<Foo..t>";
      "/:id<Foo.value>";
      "/file-:id<int>";
      "/:id<int>?";
      "/:id<int>*";
      "/:parts<string...>/tail";
      "/:parts<string...>/:id<int>";
      "/:parts<int...>";
      "/:parts<Foo.t...>";
      "/:parts<string..>";
      "/:parts<string....>";
      "/:parts<...>";
      "/:<string...>";
    ]
  in
  List.iter
    (fun path -> match RouterPattern.parse path with Ok _ -> failwith ("accepted " ^ path) | Error _ -> ())
    invalid;
  let pattern =
    match RouterPattern.parse "/café/東京" with Ok pattern -> pattern | Error _ -> failwith "rejected UTF-8 path"
  in
  let rendered =
    match
      RouterPattern.render pattern ~parameter:(fun _ -> None) ~encodeStatic:RouterPattern.encodeStaticSegment
        ~encodeParameter:encode
    with
    | Ok rendered -> rendered
    | Error _ -> failwith "failed to render UTF-8 path"
  in
  if rendered <> "/caf%C3%A9/%E6%9D%B1%E4%BA%AC" then failwith rendered;
  let catch_all =
    match RouterPattern.parse "/assets/:parts<string...>" with
    | Ok pattern -> pattern
    | Error _ -> failwith "rejected catch-all path"
  in
  (match
     RouterPattern.render catch_all
       ~parameter:(fun _ -> Some "café/a+b")
       ~encodeStatic:RouterPattern.encodeStaticSegment ~encodeParameter:encode
   with
  | Ok "/assets/caf%C3%A9/a%2Bb" -> ()
  | Ok rendered -> failwith rendered
  | Error _ -> failwith "failed to render catch-all");
  print_endline "static path grammar and UTF-8 href rendering passed"
