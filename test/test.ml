let () =
  Alcotest.run "Tests"
    [
      Test_renderToStaticMarkup.tests;
      Test_renderToString.tests;
      Test_cloneElement.tests;
      Test_react.tests;
      Test_reactDOMStyle.tests;
      Test_css_styles.tests;
      Test_css_autoprefixer.tests;
      Test_css_hash.tests;
    ]
