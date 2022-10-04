open Alcotest

let () =
  run "Tests"
    [ RenderToStaticMarkup.tests
    ; RenderToString.tests
    ; CloneElement.tests
    ; ReactDOMStyle.tests
    ]
