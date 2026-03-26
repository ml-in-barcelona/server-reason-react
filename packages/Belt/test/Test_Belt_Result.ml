let _result_alias_one : (string, string) result = Belt.Result.map (Ok "Test") (fun r -> "Value: " ^ r)

let _result_alias_two : string =
  Belt.Result.getWithDefault (Belt.Result.map (Error "error") (fun r -> "Value: " ^ r)) "success"

let suites =
  [
    ( "Result",
      [
        test "alias compatibility" (fun () ->
            (match Belt.Result.map (Ok "Test") (fun r -> "Value: " ^ r) with
            | Ok value -> assert_string "Value: Test" value
            | Error _ -> Alcotest.fail "Expected Ok");
            assert_string "success"
              (Belt.Result.getWithDefault (Belt.Result.map (Error "error") (fun r -> "Value: " ^ r)) "success"));
      ] );
  ]
