let () =
  Lwt_main.run
    (Alcotest_lwt.run "ReactDOM"
       (List.flatten
          [
            Test_renderToStream.tests;
            Test_renderToStaticMarkup.tests;
            Test_renderToString.tests;
            Test_reactDOMStyle.tests;
            Test_ReactServerDOM.tests;
          ]))
