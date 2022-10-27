open Alcotest

let () =
  run "Tests"
    [ Test_renderToStaticMarkup.tests
    ; Test_renderToString.tests
    ; Test_cloneElement.tests
    ; Test_reactDOMStyle.tests
    ; Test_emotion_hash.tests
    ; Test_emotion_styles.tests
    ]
