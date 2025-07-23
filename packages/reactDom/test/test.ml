let () =
  Lwt_main.run
    (Alcotest_lwt.run "ReactDOM"
       (List.flatten
          [
            Test_RSC_html.tests;
            Test_renderToStream.tests;
            Test_renderToStaticMarkup.tests;
            Test_renderToString.tests;
            Test_reactDOMStyle.tests;
            Test_RSC_model.tests;
            Test_html_shell_generation.tests;
            Test_RSC_decoders.tests;
          ]))
