module ULLong = Unsigned.ULLong

let string_to_int64 input =
  let len = String.length input in
  let num_bytes = min len 8 in
  let value = ref Int64.zero in
  for i = 0 to num_bytes - 1 do
    value :=
      Int64.logor
        (Int64.shift_left !value 8)
        (Int64.of_int (Char.code input.[i]))
  done;
  !value

let case title fn : unit Alcotest.test_case = (title, `Quick, fn)
let check_int64 = Alcotest.(check int64)

let data =
  [
    ("", 0xef46db3751d8e999L);
    ("a", 0xd24ec4f1a98c6e5bL);
    ("abc", 0x44bc2cf5ad770999L);
    ("message digest", 0xe0b153045b0d3434L);
    ("abcdefghijklmnopqrstuvwxyz", 0x7a51fd67f5839c21L);
    ( "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
      0x1f16c2b8d8c7e2e4L );
    ( "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
      0x712e53e204e1c795L );
    ("The quick brown fox jumps over the lazy dog", 0x0eab5433846c219fL);
    ("The quick brown fox jumps over the lazy dog.", 0x11f24a3aa98f8eb3L);
    ( "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod \
       tempor incididunt ut labore et dolore magna aliqua.",
      0xeccf9cd242dbab10L );
  ]

let test_cases =
  List.map
    (fun (input, expected) ->
      case (Printf.sprintf "%S" input) (fun () ->
          check_int64 input expected (XXH64.hash input)))
    data

let () =
  Alcotest.run "XXH64"
    [
      ( "Int64",
        [
          case "Basic int64 -> uint64" (fun () ->
              check_int64 "Basic int64 -> uint64" 0x4849204C4F4E47L
                (ULLong.of_int64 0x4849204C4F4E47L |> ULLong.to_int64));
          case "Empty string" (fun () ->
              check_int64 "Empty string" Int64.zero (string_to_int64 ""));
          case "Single byte" (fun () ->
              check_int64 "Single byte" 0x41L (string_to_int64 "A"));
          case "Multiple bytes" (fun () ->
              check_int64 "Multiple bytes" 0x4849204C4F4E47L
                (string_to_int64 "HI LONG"));
          (* case "Longer than 8 bytes" (fun () ->
              check_int64 "Longer than 8 bytes"
                (Int64.of_string "0x4C4F4E47535452494EL")
                (string_to_int64 "LONGSTRING")); *)
          (* case "Non-ASCII characters" (fun () ->
              check_int64 "Non-ASCII characters"
                (Int64.of_string "0xE282AC21E282ACL")
                (string_to_int64 "⊪!⊪")); *)
        ] );
      ("hash", test_cases);
    ]
