open Helpers
open Js.Int

let throws fn = match fn () with exception _ -> () | _ -> Alcotest.fail "expected an exception"

let tests =
  [
    test "toExponential without digits" (fun () -> assert_string (Js.Int.toExponential 123456) "1.23456e+5");
    test "toExponentialWithPrecision - digits:2" (fun () -> assert_string (toExponential 123456 ~digits:2) "1.23e+5");
    test "toExponentialWithPrecision - digits:4" (fun () -> assert_string (toExponential 123456 ~digits:4) "1.2346e+5");
    test "toExponentialWithPrecision - digits:20" (fun () ->
        assert_string (toExponential 0 ~digits:20) "0.00000000000000000000e+0");
    test "toExponentialWithPrecision - digits:101" (fun () -> throws (fun () -> ignore @@ toExponential 0 ~digits:101));
    test "toExponentialWithPrecision - digits:-1" (fun () -> throws (fun () -> ignore @@ toExponential 0 ~digits:(-1)));
    test "toPrecision" (fun () -> assert_string (toPrecision 123456) "123456");
    test "toPrecisionWithPrecision - digits:2" (fun () -> assert_string (toPrecision 123456 ~digits:2) "1.2e+5");
    test "toPrecisionWithPrecision - digits:4" (fun () -> assert_string (toPrecision 123456 ~digits:4) "1.235e+5");
    test "toPrecisionWithPrecision - digits:20" (fun () ->
        assert_string (toPrecision 0 ~digits:20) "0.0000000000000000000");
    test "toPrecisionWithPrecision - digits:101" (fun () -> throws (fun () -> ignore @@ toPrecision 0 ~digits:101));
    test "toPrecisionWithPrecision - digits:-1" (fun () -> throws (fun () -> ignore @@ toPrecision 0 ~digits:(-1)));
    test "toString" (fun () -> assert_string (toString 123) "123");
    test "toStringWithRadix - radix:2" (fun () -> assert_string (toString 123456 ~radix:2) "11110001001000000");
    test "toStringWithRadix - radix:16" (fun () -> assert_string (toString 123456 ~radix:16) "1e240");
    test "toStringWithRadix - radix:36" (fun () -> assert_string (toString 123456 ~radix:36) "2n9c");
    test "toStringWithRadix - radix:37" (fun () -> throws (fun () -> ignore @@ toString 0 ~radix:37));
    test "toStringWithRadix - radix:1" (fun () -> throws (fun () -> ignore @@ toString 0 ~radix:1));
    test "toStringWithRadix - radix:-1" (fun () -> throws (fun () -> ignore @@ toString 0 ~radix:(-1)));
  ]
