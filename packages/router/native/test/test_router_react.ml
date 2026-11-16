let committed search =
  RouterRuntime.Navigation.
    {
      location = { pathname = "/"; search; hash = ""; key = "r1" };
      matches = [ { routeId = "/"; parameters = [] } ];
      layouts = [];
      revision = "r1";
    }

let capture () =
  let values = ref None in
  let element =
    React.Upper_case_component
      ( "Capture",
        fun () ->
          values := Some (fst (RouterReact.useSearch ()));
          React.null )
  in
  (values, element)

let render_search search =
  let values, element = capture () in
  let _ =
    ReactDOM.renderToString
      (RouterReact.Provider.make
         (RouterReact.Provider.makeProps ~initial:(committed search) ~registryFingerprint:"f" ~basePath:"/"
            ~metadata:React.null ~children:element ()))
  in
  match !values with Some values -> values | None -> Alcotest.fail "component did not render"

let search_values = Alcotest.(list (pair string (list string)))

let matches_client_parsing () =
  Alcotest.check search_values "values"
    [ ("text", [ "a,b" ]); ("tag", [ "a"; "b" ]); ("flag", [ "" ]) ]
    (render_search "?text=a,b&tag=a&tag=b&flag")

let empty_search () = Alcotest.check search_values "values" [] (render_search "")

let invalid_search () =
  Alcotest.check search_values "malformed" [] (render_search "?q=%zz");
  Alcotest.check search_values "too long" [] (render_search ("?q=" ^ String.make 8190 'a'))

let requires_provider () =
  let _, element = capture () in
  Alcotest.check_raises "no provider" (Invalid_argument "router hooks require an ancestor Router.Provider") (fun () ->
      ignore (ReactDOM.renderToString element))

let () =
  Alcotest.run "router react"
    [
      ( "useSearch",
        [
          Alcotest.test_case "matches client parsing" `Quick matches_client_parsing;
          Alcotest.test_case "empty search" `Quick empty_search;
          Alcotest.test_case "invalid search" `Quick invalid_search;
          Alcotest.test_case "requires provider" `Quick requires_provider;
        ] );
    ]
