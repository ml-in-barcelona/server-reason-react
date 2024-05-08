let () = Alcotest.run "Json" [ Test_json_encode.tests; Test_json_decode.tests ]
