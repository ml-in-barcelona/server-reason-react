let () =
  Alcotest_lwt.run "ReactDOM"
    [
      Test_renderToLwtStream.tests;
      Test_renderToStaticMarkup.tests;
      Test_renderToString.tests;
      Test_reactDOMStyle.tests;
      Test_ReactServer.tests;
    ]
  |> Lwt_main.run
