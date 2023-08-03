let () =
  Alcotest_lwt.run "ReactDOM"
    [
      Test_renderToLwtStream.tests;
      Test_renderToStaticMarkup.tests;
      Test_renderToString.tests;
      Test_reactDOMStyle.tests;
    ]
  |> Lwt_main.run
