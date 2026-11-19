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
  Alcotest.check search_values "malformed" [ ("a", [ "1" ]) ] (render_search "?a=1&q=%zz&b=%FF");
  Alcotest.check search_values "too long" [] (render_search ("?q=" ^ String.make 8190 'a'))

let requires_provider () =
  let _, element = capture () in
  Alcotest.check_raises "no provider" (Invalid_argument "router hooks require an ancestor Router.Provider") (fun () ->
      ignore (ReactDOM.renderToString element))

let link path =
  RouterReact.Link.make
    (RouterReact.Link.makeProps ~destination:(RouterRuntime.destination ~path) ~children:(React.string "go") ())

let at_location pathname search children =
  let initial =
    RouterRuntime.Navigation.
      { location = { pathname; search; hash = ""; key = "r1" }; matches = []; layouts = []; revision = "r1" }
  in
  ReactDOM.renderToStaticMarkup
    (RouterReact.Provider.make
       (RouterReact.Provider.makeProps ~initial ~registryFingerprint:"f" ~basePath:"/" ~metadata:React.null ~children ()))

let contains ~needle value =
  let limit = String.length value - String.length needle in
  let rec loop index =
    index <= limit && (String.equal (String.sub value index (String.length needle)) needle || loop (index + 1))
  in
  loop 0

let link_marks_current_page () =
  let current = at_location "/notes" "?b=2&a=1" (link "/notes?a=1&b=2#top") in
  Alcotest.(check bool) current true (contains ~needle:{|aria-current="page"|} current);
  List.iter
    (fun (pathname, search) ->
      let other = at_location pathname search (link "/notes?a=1&b=2") in
      Alcotest.(check bool) other false (contains ~needle:"aria-current" other))
    [ ("/notes/1", "?a=1&b=2"); ("/notes", "?a=1"); ("/", "") ]

let link_without_provider () =
  let html = ReactDOM.renderToStaticMarkup (link "/notes") in
  Alcotest.(check string) "plain anchor" {|<a href="/notes">go</a>|} html

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
      ( "Link",
        [
          Alcotest.test_case "marks the current page" `Quick link_marks_current_page;
          Alcotest.test_case "works without a provider" `Quick link_without_provider;
        ] );
    ]
