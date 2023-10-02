let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let assert_option x left right =
  Alcotest.check (Alcotest.option x) "should be equal" right left

let assert_array ty left right =
  Alcotest.check (Alcotest.array ty) "should be equal" right left

let assert_string_array = assert_array Alcotest.string
let assert_array_int = assert_array Alcotest.int

let assert_dict_entries type_ left right =
  Alcotest.check
    (Alcotest.array (Alcotest.pair Alcotest.string type_))
    "should be equal" right left

let assert_int_dict_entries = assert_dict_entries Alcotest.int
let assert_string_dict_entries = assert_dict_entries Alcotest.string
let assert_option_int = assert_option Alcotest.int
(* let assert_option_string = assert_option Alcotest.string *)

let assert_int left right =
  Alcotest.check Alcotest.int "should be equal" right left

let assert_float left right =
  Alcotest.check (Alcotest.float 2.) "should be equal" right left

let assert_bool left right =
  Alcotest.check Alcotest.bool "should be equal" right left

let case title (fn : unit -> unit) = Alcotest.test_case title `Quick fn

let tests =
  ( "OK",
    [
      case "new URL" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.host url) "sancho.dev");
    ] )

let () = Alcotest.run "URL" [ tests ]
