let () =
  Alcotest.run "Html"
    (List.flatten
       [
         Test_node_manipulation.tests;
       ])
