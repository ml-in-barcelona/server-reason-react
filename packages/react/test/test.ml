let () =
  Alcotest.run "React"
    [
      Test_cloneElement.tests; Test_react.tests; Test_static_list.tests; Test_reasonReactRouter.tests; Test_cache.tests;
    ]
