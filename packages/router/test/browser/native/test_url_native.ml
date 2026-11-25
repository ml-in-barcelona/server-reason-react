let pattern = RouterEngine.pattern "/s/:v<string>"

let encodeSegment value =
  let href =
    RouterRuntime.href (RouterEngine.destinationFromPattern ~pattern ~parameters:[ ("v", value) ] ~search:[])
  in
  String.sub href 3 (String.length href - 3)

let platform =
  {
    UrlCases.text = Fun.id;
    encodeSearch = RouterEngine.encodeSearch;
    parseSearch =
      (fun search ->
        match RouterEngine.Search.parse search with
        | Ok parsed -> Some (RouterEngine.Search.unknown parsed ~owned:[])
        | Error _ -> None);
    encodeSegment;
    decodeSegment =
      (fun segment ->
        match RouterEngine.Path.decodePathname ("/" ^ segment) with Ok [ decoded ] -> Some decoded | _ -> None);
  }

let rejects encode = match encode () with _ -> false | exception Invalid_argument _ -> true

let () =
  List.iter
    (fun (name, value) ->
      if not (rejects (fun () -> RouterEngine.encodeSearch [ ("k", [ value ]) ])) then
        failwith ("a search value with " ^ name ^ " was printed");
      if not (rejects (fun () -> RouterEngine.encodeSearch [ (value, [ "v" ]) ])) then
        failwith ("a search name with " ^ name ^ " was printed"))
    [ ("a lone byte", "\xff"); ("a truncated sequence", "\xe2\x82"); ("an encoded surrogate", "\xed\xa0\x80") ];
  UrlCases.run platform print_endline
