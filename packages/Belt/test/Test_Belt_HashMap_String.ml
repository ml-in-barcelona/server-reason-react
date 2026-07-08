let force_allocations () =
  for _ = 1 to 10 do
    ignore (Sys.opaque_identity (String.make 1024 'x'))
  done;
  ignore (Sys.opaque_identity (List.init 256 (fun i -> string_of_int i)))

let suites =
  [
    ( "HashMap.String",
      [
        test "smoke" (fun () ->
            let values = Belt.HashMap.String.make ~hintSize:4 in
            Belt.HashMap.String.set values "one" 1;
            assert_int 1 (Belt.HashMap.String.size values);
            assert_array_unordered
              (Alcotest.pair Alcotest.string Alcotest.int)
              [| ("one", 1) |]
              (Belt.HashMap.String.toArray values));
        test "get after allocations" (fun () ->
            let h = Belt.HashMap.String.make ~hintSize:4 in
            Belt.HashMap.String.set h "hello" 1;
            force_allocations ();
            assert_option Alcotest.int (Some 1) (Belt.HashMap.String.get h "hello"));
        test "50 keys with interleaved allocations" (fun () ->
            let h = Belt.HashMap.String.make ~hintSize:4 in
            for i = 1 to 50 do
              Belt.HashMap.String.set h ("key-" ^ string_of_int i) i;
              force_allocations ()
            done;
            assert_int 50 (Belt.HashMap.String.size h);
            for i = 1 to 50 do
              assert_option Alcotest.int (Some i) (Belt.HashMap.String.get h ("key-" ^ string_of_int i))
            done);
        test "setting same key twice keeps size 1" (fun () ->
            let h = Belt.HashMap.String.make ~hintSize:4 in
            Belt.HashMap.String.set h "dup" 1;
            force_allocations ();
            Belt.HashMap.String.set h "dup" 2;
            assert_int 1 (Belt.HashMap.String.size h);
            assert_option Alcotest.int (Some 2) (Belt.HashMap.String.get h "dup"));
      ] );
  ]
