let () =
  Alcotest.run "ReactDOM"
    [
      Test_renderToStaticMarkup.tests;
      Test_renderToString.tests;
      Test_reactDOMStyle.tests;
    ]
