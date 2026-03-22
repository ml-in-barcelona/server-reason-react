open Helpers

let return_int () =
  let v = Js.Undefined.return 42 in
  let opt = Js.Undefined.toOption v in
  assert_option Alcotest.int "return int should be Some" opt (Some 42)

let return_string () =
  let v = Js.Undefined.return "hello" in
  let opt = Js.Undefined.toOption v in
  assert_option Alcotest.string "return string should be Some" opt (Some "hello")

let return_float () =
  let v = Js.Undefined.return 3.14 in
  let opt = Js.Undefined.toOption v in
  assert_option (Alcotest.float 0.) "return float should be Some" opt (Some 3.14)

let return_date () =
  let d = Date.fromFloat 1506098258091. in
  let v = Js.Undefined.return d in
  let opt = Js.Undefined.toOption v in
  assert_option (Alcotest.float 0.) "return Js.Date.t should be Some" opt (Some 1506098258091.)

let empty_is_none () =
  let v : int Js.Undefined.t = Js.Undefined.empty in
  let opt = Js.Undefined.toOption v in
  assert_option Alcotest.int "empty should be None" opt None

let get_unsafe_int () =
  let v = Js.Undefined.return 42 in
  let result = Js.Undefined.getUnsafe v in
  assert_int result 42

let get_unsafe_date () =
  let d = Date.fromFloat 1506098258091. in
  let v = Js.Undefined.return d in
  let result = Js.Undefined.getUnsafe v in
  assert_float_exact result 1506098258091.

let from_opt_some () =
  let v = Js.Undefined.fromOpt (Some 42) in
  let opt = Js.Undefined.toOption v in
  assert_option Alcotest.int "fromOpt (Some 42) round-trip" opt (Some 42)

let from_opt_none () =
  let v = Js.Undefined.fromOpt None in
  let opt = Js.Undefined.toOption v in
  assert_option Alcotest.int "fromOpt None round-trip" opt None

let from_option_some () =
  let v = Js.Undefined.fromOption (Some "test") in
  let opt = Js.Undefined.toOption v in
  assert_option Alcotest.string "fromOption (Some \"test\") round-trip" opt (Some "test")

let from_option_none () =
  let v : string Js.Undefined.t = Js.Undefined.fromOption None in
  let opt = Js.Undefined.toOption v in
  assert_option Alcotest.string "fromOption None round-trip" opt None

let pattern_match_return_int () =
  let v = Js.Undefined.return 99 in
  match (v : int Js.Undefined.t) with
  | Some x -> assert_int x 99
  | None -> Alcotest.fail "pattern match on return int should be Some"

let pattern_match_return_float () =
  let v = Js.Undefined.return 2.718 in
  match (v : float Js.Undefined.t) with
  | Some x -> assert_float_exact x 2.718
  | None -> Alcotest.fail "pattern match on return float should be Some"

let pattern_match_return_date () =
  let d = Date.fromFloat 0. in
  let v = Js.Undefined.return d in
  match (v : Date.t Js.Undefined.t) with
  | Some x -> assert_float_exact x 0.
  | None -> Alcotest.fail "pattern match on return Js.Date.t should be Some"

let pattern_match_empty () =
  let v : int Js.Undefined.t = Js.Undefined.empty in
  match v with Some _ -> Alcotest.fail "pattern match on empty should be None" | None -> ()

let tests =
  [
    test "return with int" return_int;
    test "return with string" return_string;
    test "return with float" return_float;
    test "return with Js.Date.t" return_date;
    test "empty is None" empty_is_none;
    test "getUnsafe on return int" get_unsafe_int;
    test "getUnsafe on return Js.Date.t" get_unsafe_date;
    test "fromOpt Some round-trip" from_opt_some;
    test "fromOpt None round-trip" from_opt_none;
    test "fromOption Some round-trip" from_option_some;
    test "fromOption None round-trip" from_option_none;
    test "pattern match on return int" pattern_match_return_int;
    test "pattern match on return float" pattern_match_return_float;
    test "pattern match on return Js.Date.t" pattern_match_return_date;
    test "pattern match on empty" pattern_match_empty;
  ]
