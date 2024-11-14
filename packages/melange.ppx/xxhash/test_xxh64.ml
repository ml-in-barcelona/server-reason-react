let check_int64 = Alcotest.(check int64)

let data =
  [
    ("", 0xef46db3751d8e999L);
    ("a", 0xd24ec4f1a98c6e5bL);
    ("as", 0x1c330fb2d66be179L);
    ("asd", 0x631c37ce72a97393L);
    ("asdf", 0x415872f599cea71eL);
    ("abc", 0x44bc2cf5ad770999L);
    ("abc", 0x44bc2cf5ad770999L);
    ("abcd", 0xde0327b0d25d92ccL);
    ("abcde", 0x07e3670c0c8dc7ebL);
    ("abcdef", 0xfa8afd82c423144dL);
    ("abcdefg", 0x1860940e2902822dL);
    ("abcdefgh", 0x3ad351775b4634b7L);
    ("abcdefghi", 0x27f1a34fdbb95e13L);
    ("abcdefghij", 0xd6287a1de5498bb2L);
    ("abcdefghijklmnopqrstuvwxyz012345", 0xbf2cd639b4143b80L);
    ("abcdefghijklmnopqrstuvwxyz0123456789", 0x64f23ecf1609b766L);
    (* Exactly 63 characters, which exercises all code paths *)
    ("Call me Ishmael. Some years ago--never mind how long precisely-", 0x02a2e85470d6fd96L);
    ( "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore \
       magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo \
       consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla \
       pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est \
       laborum.",
      0xc5a8b11443765630L );
  ]

let hash_test_cases =
  List.map
    (fun (input, expected) ->
      let test () = check_int64 input expected (XXH64.hash input) in
      (Printf.sprintf "%S" input, `Quick, test))
    data

let data = [ ("I want an unsigned 64-bit seed!", "d4cb0a70a2b8c7c1") ]

let hex_test_cases =
  List.map
    (fun (input, expected) ->
      let test () =
        let output = input |> XXH64.hash |> XXH64.to_hex in
        Alcotest.(check string) input expected output
      in
      (Printf.sprintf "%S" input, `Quick, test))
    data

let () = Alcotest.run "XXH64" [ ("hash", hash_test_cases); ("hash · to_hex", hex_test_cases) ]
