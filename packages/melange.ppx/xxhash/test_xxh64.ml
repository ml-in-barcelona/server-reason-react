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

let string_to_uint64 input =
  let len = String.length input in
  let num_bytes = min len 8 in
  let value = ref ULLong.zero in
  for i = 0 to num_bytes - 1 do
    value :=
      ULLong.logor
        (ULLong.shift_left !value 8)
        (ULLong.of_int (Char.code input.[i]))
  done;
  !value

let case title fn = (title, `Quick, fn)
let ullong = Alcotest.testable ULLong.pp ULLong.equal
let check_int64 = Alcotest.(check int64)
let check_ullong = Alcotest.(check ullong)

let () =
  Alcotest.run "string_to_int64 tests"
    [
      ( "xxh64",
        [
          case "xxh64" (fun () ->
              let input =
                {|<svg xmlns="http://www.w3.org/2000/svg" height="512" width="512"><g fill-rule="evenodd" clip-path="url(#a)"><path fill="#f00" d="M0 0h192v512h-192z"/><path d="M192 340.06h576v171.94h-576z"/><path fill="#fff" d="M192 172.7h576v169.65h-576z"/><path fill="#00732f" d="M192 0h576v172.7h-576z"/></g></svg>|}
              in
              let expected = "DWDWZCEH" in
              (Alcotest.check Alcotest.string)
                "xxh64" expected (input |> XXH64.full));
        ] );
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
      ( "ULLong",
        [
          case "Empty string" (fun () ->
              check_ullong "Empty string" ULLong.zero (string_to_uint64 ""));
          case "Single byte" (fun () ->
              check_ullong "Single byte" (ULLong.of_int64 0x41L)
                (string_to_uint64 "A"));
          case "Multiple bytes" (fun () ->
              check_ullong "Multiple bytes"
                (ULLong.of_int64 0x4849204C4F4E47L)
                (string_to_uint64 "HI LONG"));
          (* case "Longer than 8 bytes" (fun () ->
              check_ullong "Longer than 8 bytes"
                (ULLong.of_string "0x4C4F4E47535452494EL")
                (string_to_uint64 "LONGSTRING")); *)
          (* case "Non-ASCII characters" (fun () ->
              check_int64 "Non-ASCII characters"
                (Int64.of_string "0xE282AC21E282ACL")
                (string_to_int64 "⊪!⊪")); *)
        ] );
    ]
