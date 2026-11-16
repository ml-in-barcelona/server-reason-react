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
      "/:lang?<string>";
      "/docs/:rest?<string...>";
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
  let templates_valid = [ "/:lang?<string>"; "/docs/:rest?<string...>"; "/help/:lang?<string>/topics/:id<int>"; "/notes" ] in
  List.iter
    (fun path ->
      match RouterPattern.parseTemplate path with
      | Ok pattern -> if RouterPattern.toString pattern <> path then failwith ("printed " ^ RouterPattern.toString pattern)
      | Error _ -> failwith ("rejected template " ^ path))
    templates_valid;
  let templates_invalid =
    [ "/:lang<string>?"; "/:?<string>"; "/:lang??<string>"; "/:rest<string...>?"; "/:rest?<string...>/raw"; "/:rest<string...?>"; "/x?" ]
  in
  List.iter
    (fun path ->
      match RouterPattern.parseTemplate path with Ok _ -> failwith ("accepted template " ^ path) | Error _ -> ())
    templates_invalid;
  let template path =
    match RouterPattern.parseTemplate path with Ok pattern -> pattern | Error _ -> failwith ("rejected " ^ path)
  in
  let shapes path = template path |> RouterPattern.shapes |> List.map RouterPattern.toString |> String.concat " " in
  if shapes "/help/:lang?<string>/topics/:id<int>" <> "/help/:lang<string>/topics/:id<int> /help/topics/:id<int>" then
    failwith (shapes "/help/:lang?<string>/topics/:id<int>");
  if shapes "/docs/:rest?<string...>" <> "/docs/:rest<string...> /docs" then failwith (shapes "/docs/:rest?<string...>");
  if shapes "/:a?<string>/:b?<string>" <> "/:a<string>/:b<string> /:a<string> /:b<string> /" then
    failwith (shapes "/:a?<string>/:b?<string>");
  if RouterPattern.optional (template "/help/:lang?<string>/topics/:id<int>") <> [ "lang" ] then failwith "optional names";
  let render path parameters =
    match
      RouterPattern.render (template path)
        ~parameter:(fun name -> List.assoc_opt name parameters)
        ~encodeStatic:RouterPattern.encodeStaticSegment ~encodeParameter:encode
    with
    | Ok rendered -> rendered
    | Error _ -> "error"
  in
  let expect expected actual = if expected <> actual then failwith (expected ^ " <> " ^ actual) in
  expect "/help/topics/3" (render "/help/:lang?<string>/topics/:id<int>" [ ("id", "3") ]);
  expect "/help/fr/topics/3" (render "/help/:lang?<string>/topics/:id<int>" [ ("lang", "fr"); ("id", "3") ]);
  expect "error" (render "/help/:lang?<string>/topics/:id<int>" [ ("lang", "fr") ]);
  expect "/docs" (render "/docs/:rest?<string...>" []);
  expect "/" (render "/:lang?<string>" []);
  expect "/docs/a/b" (render "/docs/:rest?<string...>" [ ("rest", "a/b") ]);
  let matches path pathname =
    let pattern =
      match RouterPattern.parse path with Ok pattern -> pattern | Error _ -> failwith ("invalid pattern " ^ path)
    in
    RouterPattern.matchesPath pattern pathname
  in
  let check path pathname expected =
    if matches path pathname <> expected then
      failwith (Printf.sprintf "matchesPath %s %s should be %b" path pathname expected)
  in
  check "/" "/" true;
  check "/" "/a" false;
  check "/app/notes" "/app/notes" true;
  check "/app/notes" "/app/notes/" false;
  check "/app/notes" "/app/note" false;
  check "/app/notes" "/app/%6Eotes" true;
  check "/app/notes/caf\xC3\xA9" "/app/notes/caf%C3%A9" true;
  check "/app/notes/caf\xC3\xA9" "/app/notes/caf%c3%a9" true;
  check "/app/notes/caf\xC3\xA9" "/app/notes/cafe" false;
  check "/app/notes/:id<int>" "/app/notes/abc" true;
  check "/app/notes/:id<int>" "/app/notes" false;
  check "/app/notes/:id<int>" "/app/notes/1/edit" false;
  check "/app/notes/:id<int>" "/app/notes//" false;
  check "/app/notes/:id<int>" "/app/notes/%ZZ" false;
  check "/assets/:parts<string...>" "/assets/a/b/c" true;
  check "/assets/:parts<string...>" "/assets/a" true;
  check "/assets/:parts<string...>" "/assets" false;
  check "/assets/:parts<string...>" "/assets/a//b" false;
  check "/a+b" "/a+b" true;
  let within basePath path pathname expected =
    let pattern = match RouterPattern.parse path with Ok pattern -> pattern | Error _ -> failwith path in
    if RouterPattern.matchesPath ~basePath pattern pathname <> expected then
      failwith (Printf.sprintf "matchesPath ~basePath:%s %s %s should be %b" basePath path pathname expected)
  in
  within "/a%20b" "/notes/:id<int>" "/a%20b/notes/1" true;
  within "/a%20b" "/notes/:id<int>" "/a b/notes/1" true;
  within "/a%20b" "/" "/a%20b" true;
  within "/a%20b" "/notes/:id<int>" "/a%20bc/notes/1" false;
  within "/a%20b" "/notes/:id<int>" "/notes/1" false;
  within "/m%C3%BCnchen" "/docs" "/m%c3%bcnchen/docs" true;
  within "/" "/docs" "/docs" true;
  print_endline "matchesPath passed";
  print_endline "static path grammar and UTF-8 href rendering passed"
