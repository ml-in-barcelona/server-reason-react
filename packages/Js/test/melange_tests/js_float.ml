(** Ported from Melange's test suite: jscomp/test/js_float_test.ml (melange 6.0.1-54).

    Melange's ThrowAny cases map to [throws]: natively toExponential/toFixed/toPrecision/toString raise on out-of-range
    digits/radix (see Js_float.mli), matching JS RangeError behaviour. *)

open Helpers
open Js.Float

let throws fn = match fn () with exception _ -> () | _ -> Alcotest.fail "expected an exception"
let ok cond = assert_true "expected true" cond

let tests =
  [
    test "_NaN <> _NaN" (fun () -> assert_bool (_NaN = _NaN) false);
    test "isNaN - _NaN" (fun () -> assert_bool (isNaN _NaN) true);
    test "isNaN - 0." (fun () -> assert_bool (isNaN 0.) false);
    test "isFinite - infinity" (fun () -> assert_bool (isFinite infinity) false);
    test "isFinite - neg_infinity" (fun () -> assert_bool (isFinite neg_infinity) false);
    test "isFinite - _NaN" (fun () -> assert_bool (isFinite _NaN) false);
    test "isFinite - 0." (fun () -> assert_bool (isFinite 0.) true);
    (* DIVERGENCE: Js.Float.toExponential (no ~digits): native returns "123.456", JS returns "1.23456e+2" (node) *)
    test "toExponential - large number" (fun () -> assert_string (toExponential 1.2e21) "1.2e+21");
    test "toExponentialWithPrecision - digits:2" (fun () -> assert_string (toExponential 123.456 ~digits:2) "1.23e+2");
    test "toExponentialWithPrecision - digits:4" (fun () -> assert_string (toExponential 123.456 ~digits:4) "1.2346e+2");
    test "toExponentialWithPrecision - digits:20" (fun () ->
        assert_string (toExponential 0. ~digits:20) "0.00000000000000000000e+0");
    test "toExponentialWithPrecision - digits:101" (fun () -> throws (fun () -> ignore @@ toExponential 0. ~digits:101));
    test "toExponentialWithPrecision - digits:-1" (fun () -> throws (fun () -> ignore @@ toExponential 0. ~digits:(-1)));
    test "toFixed" (fun () -> assert_string (toFixed 123.456) "123");
    (* DIVERGENCE: Js.Float.toFixed 1.2e21: native returns "1200000000000000000000", JS returns "1.2e+21" (node) *)
    test "toFixedWithPrecision - digits:2" (fun () -> assert_string (toFixed 123.456 ~digits:2) "123.46");
    test "toFixedWithPrecision - digits:4" (fun () -> assert_string (toFixed 123.456 ~digits:4) "123.4560");
    test "toFixedWithPrecision - digits:20" (fun () -> assert_string (toFixed 0. ~digits:20) "0.00000000000000000000");
    test "toFixedWithPrecision - digits:101" (fun () -> throws (fun () -> ignore @@ toFixed 0. ~digits:101));
    test "toFixedWithPrecision - digits:-1" (fun () -> throws (fun () -> ignore @@ toFixed 0. ~digits:(-1)));
    test "toPrecision" (fun () -> assert_string (toPrecision 123.456) "123.456");
    test "toPrecision - large number" (fun () -> assert_string (toPrecision 1.2e21) "1.2e+21");
    test "toPrecisionWithPrecision - digits:2" (fun () -> assert_string (toPrecision 123.456 ~digits:2) "1.2e+2");
    test "toPrecisionWithPrecision - digits:4" (fun () -> assert_string (toPrecision 123.456 ~digits:4) "123.5");
    test "toPrecisionWithPrecision - digits:20" (fun () ->
        assert_string (toPrecision 0. ~digits:20) "0.0000000000000000000");
    test "toPrecisionWithPrecision - digits:101" (fun () -> throws (fun () -> ignore @@ toPrecision 0. ~digits:101));
    test "toPrecisionWithPrecision - digits:-1" (fun () -> throws (fun () -> ignore @@ toPrecision 0. ~digits:(-1)));
    test "toString" (fun () -> assert_string (toString 1.23) "1.23");
    test "toString - large number" (fun () -> assert_string (toString 1.2e21) "1.2e+21");
    test "toStringWithRadix - radix:2" (fun () ->
        assert_string (toString 123.456 ~radix:2) "1111011.0111010010111100011010100111111011111001110111");
    test "toStringWithRadix - radix:16" (fun () -> assert_string (toString 123.456 ~radix:16) "7b.74bc6a7ef9dc");
    test "toStringWithRadix - radix:36" (fun () -> assert_string (toString 123. ~radix:36) "3f");
    test "toStringWithRadix - radix:37" (fun () -> throws (fun () -> ignore @@ toString 0. ~radix:37));
    test "toStringWithRadix - radix:1" (fun () -> throws (fun () -> ignore @@ toString 0. ~radix:1));
    test "toStringWithRadix - radix:-1" (fun () -> throws (fun () -> ignore @@ toString 0. ~radix:(-1)));
    test "fromString - 123" (fun () -> assert_float_exact (fromString "123") 123.);
    test "fromString - 12.3" (fun () -> assert_float_exact (fromString "12.3") 12.3);
    test "fromString - empty string" (fun () -> assert_float_exact (fromString "") 0.);
    test "fromString - 0x11" (fun () -> assert_float_exact (fromString "0x11") 17.);
    test "fromString - 0b11" (fun () -> assert_float_exact (fromString "0b11") 3.);
    test "fromString - 0o11" (fun () -> assert_float_exact (fromString "0o11") 9.);
    test "fromString - invalid string" (fun () -> ok (fromString "foo" |> isNaN));
  ]
