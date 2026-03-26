let suites =
  [
    ( "SortArray.String",
      [ test "binarySearch" (fun () -> assert_int 1 (Belt.SortArray.String.binarySearch [| "a"; "c"; "e" |] "c")) ] );
  ]
