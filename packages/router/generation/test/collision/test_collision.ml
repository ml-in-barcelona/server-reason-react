let render pathname =
  let search = match RouterServer.Search.parse "" with Ok search -> search | Error _ -> assert false in
  match RouterServer.EndpointRegistry.find RouterRegistry.registry ~pathname with
  | Ok (Some matched) -> (
      match RouterServer.EndpointRegistry.decode matched ~search with
      | Error _ -> Alcotest.fail ("expected decoded endpoint for " ^ pathname)
      | Ok prepared -> (
          match Lwt_main.run (RouterServer.Execution.run (RouterServer.Endpoint.execution prepared)) with
          | RouterRuntime.Loader.Data plan ->
              let resolved =
                Lwt_main.run
                  (RouterServer.Plan.resolve plan ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError))
              in
              let html, _ =
                Lwt_main.run (ReactServerDOM.render_html ~skipRoot:true (RouterServer.Plan.resolvedElement resolved))
              in
              html
          | _ -> Alcotest.fail ("expected a page plan for " ^ pathname)))
  | Ok None | Error _ -> Alcotest.fail ("expected a match for " ^ pathname)

let contains ~sub value =
  let rec search index =
    index + String.length sub <= String.length value
    && (String.equal (String.sub value index (String.length sub)) sub || search (index + 1))
  in
  search 0

let check_contains label ~sub value =
  if not (contains ~sub value) then Alcotest.failf "%s: %S not in %S" label sub value

let test_helper_names () =
  let href = Router.Note.href ~id:1 ~searchValues:2 ~tryDestination:3 ~pattern:"p" ~input:"i" ~value:4 () in
  Alcotest.(check string) "href" "/n/1/2/3/p/i/4" href;
  check_contains "page" ~sub:"1,2,3,p,i,4" (render href)

let test_default_is_not_captured () =
  Alcotest.(check int) "client default" max_int (Router.Page.search ()).limit;
  check_contains "server default" ~sub:("5:" ^ string_of_int max_int) (render "/p/5")

let test_route_named_like_a_module () = Alcotest.(check string) "href" "/stdlib" (Router.Stdlib.href ())

let () =
  Alcotest.run "router generated names"
    [
      ( "collisions",
        [
          Alcotest.test_case "helper names as path parameters" `Quick test_helper_names;
          Alcotest.test_case "search default" `Quick test_default_is_not_captured;
          Alcotest.test_case "route named like a module" `Quick test_route_named_like_a_module;
        ] );
    ]
