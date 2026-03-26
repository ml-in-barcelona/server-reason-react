let suites =
  [
    ("SortArray.Int", [ test "binarySearch" (fun () -> assert_int 1 (Belt.SortArray.Int.binarySearch [| 1; 3; 5 |] 3)) ]);
  ]
