open Alcotest

let () =
  run "Tests"
    [ Test_renderToStaticMarkup.tests
    ; Test_renderToString.tests
    ; Test_cloneElement.tests
    ; Test_reactDOMStyle.tests
    ]
