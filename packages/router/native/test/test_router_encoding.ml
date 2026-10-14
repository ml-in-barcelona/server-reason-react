let table =
  [
    ("abc", "abc");
    ("a b", "a%20b");
    ("/", "%2F");
    ("?", "%3F");
    ("#", "%23");
    ("&", "%26");
    ("=", "%3D");
    ("+", "%2B");
    ("%", "%25");
    ("caf\xc3\xa9", "caf%C3%A9");
    ("M\xc3\xbcnchen", "M%C3%BCnchen");
    ("\xf0\x9f\x98\x80", "%F0%9F%98%80");
    ("a-b_c.d~e!*'()", "a-b_c.d~e!*'()");
  ]

let pattern = RouterRuntime.pattern "/:v<string>"

let case (input, expected) =
  Alcotest.test_case (String.escaped input) `Quick (fun () ->
      Alcotest.(check string) "search" ("k=" ^ expected) (RouterRuntime.encodeSearch [ ("k", [ input ]) ]);
      Alcotest.(check string)
        "destination search" ("/x?k=" ^ expected)
        (RouterRuntime.href
           (RouterRuntime.destinationFromPattern ~pattern ~parameters:[ ("v", "x") ] ~search:[ ("k", [ input ]) ]));
      if not (String.contains input '/') then
        Alcotest.(check string)
          "path" ("/" ^ expected)
          (RouterRuntime.href (RouterRuntime.destinationFromPattern ~pattern ~parameters:[ ("v", input) ] ~search:[])))

let sorted () =
  Alcotest.(check string) "sorted" "a=2&a=3&b=1" (RouterRuntime.encodeSearch [ ("b", [ "1" ]); ("a", [ "2"; "3" ]) ])

let link_attributes () =
  let html =
    ReactDOM.renderToString
      (RouterReact.link ~destination:(RouterRuntime.destination ~path:"/a") ~id:"i" ~title:"t" ~rel:"nofollow"
         ~ariaLabel:"l"
         ~onClick:(fun _ -> ())
         ~onMouseEnter:(fun _ -> ())
         ~children:(React.string "x") ())
  in
  Alcotest.(check string) "html" {|<a href="/a" id="i" title="t" rel="nofollow" aria-label="l">x</a>|} html

let () =
  Alcotest.run "router encoding"
    [
      ("table", List.map case table @ [ Alcotest.test_case "sorted by name" `Quick sorted ]);
      ("link", [ Alcotest.test_case "native link attributes" `Quick link_attributes ]);
    ]
