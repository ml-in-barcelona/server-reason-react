let () =
  Alcotest.run "ReactDOM"
    [
      Test_renderToStaticMarkup.tests;
      Test_renderToString.tests;
      Test_reactDOMStyle.tests;
    ]

let () =
  Lwt_main.run @@ Alcotest_lwt.run "ReactDOM" [ Test_renderToLwtStream.tests ]
