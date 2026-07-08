let force_allocations () =
  for _ = 1 to 10 do
    ignore (Sys.opaque_identity (String.make 1024 'x'))
  done;
  ignore (Sys.opaque_identity (List.init 256 (fun i -> string_of_int i)))

let suites =
  [
    ( "HashMap.Int",
      [
        test "smoke" (fun () ->
            let values = Belt.HashMap.Int.make ~hintSize:4 in
            Belt.HashMap.Int.set values 1 "one";
            assert_int 1 (Belt.HashMap.Int.size values);
            assert_array_unordered
              (Alcotest.pair Alcotest.int Alcotest.string)
              [| (1, "one") |]
              (Belt.HashMap.Int.toArray values));
        test "get after allocations" (fun () ->
            let h = Belt.HashMap.Int.make ~hintSize:4 in
            Belt.HashMap.Int.set h 42 "answer";
            force_allocations ();
            assert_option Alcotest.string (Some "answer") (Belt.HashMap.Int.get h 42));
        test "50 keys with interleaved allocations" (fun () ->
            let h = Belt.HashMap.Int.make ~hintSize:4 in
            for i = 1 to 50 do
              Belt.HashMap.Int.set h i (string_of_int i);
              force_allocations ()
            done;
            assert_int 50 (Belt.HashMap.Int.size h);
            for i = 1 to 50 do
              assert_option Alcotest.string (Some (string_of_int i)) (Belt.HashMap.Int.get h i)
            done);
        test "setting same key twice keeps size 1" (fun () ->
            let h = Belt.HashMap.Int.make ~hintSize:4 in
            Belt.HashMap.Int.set h 42 "first";
            force_allocations ();
            Belt.HashMap.Int.set h 42 "second";
            assert_int 1 (Belt.HashMap.Int.size h);
            assert_option Alcotest.string (Some "second") (Belt.HashMap.Int.get h 42));
      ] );
  ]
