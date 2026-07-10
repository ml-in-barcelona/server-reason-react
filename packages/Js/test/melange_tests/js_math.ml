(** Ported from Melange's test suite: jscomp/test/js_math_test.ml (melange 6.0.1-54).

    Expectations are the exact values asserted by Melange's suite, which runs against the real Math object in JS. *)

open Helpers
open Js.Math

(* Melange's ApproxThreshold(0.001, expected, actual) *)
let approx expected actual =
  if Stdlib.abs_float (expected -. actual) >= 0.001 then
    Alcotest.failf "expected %.6f to be within 0.001 of %.6f" actual expected

let tests =
  [
    test "_E" (fun () -> approx 2.718 _E);
    test "_LN2" (fun () -> approx 0.693 _LN2);
    test "_LN10" (fun () -> approx 2.303 _LN10);
    test "_LOG2E" (fun () -> approx 1.443 _LOG2E);
    test "_LOG10E" (fun () -> approx 0.434 _LOG10E);
    test "_PI" (fun () -> approx 3.14159 _PI);
    test "_SQRT1_2" (fun () -> approx 0.707 _SQRT1_2);
    test "_SQRT2" (fun () -> approx 1.414 _SQRT2);
    test "abs_int" (fun () -> assert_int (abs_int (-4)) 4);
    test "abs_float" (fun () -> assert_float_exact (abs_float (-1.2)) 1.2);
    test "acos" (fun () -> approx 1.159 (acos 0.4));
    test "acosh" (fun () -> approx 0.622 (acosh 1.2));
    test "asin" (fun () -> approx 0.411 (asin 0.4));
    test "asinh" (fun () -> approx 0.390 (asinh 0.4));
    test "atan" (fun () -> approx 0.380 (atan 0.4));
    test "atanh" (fun () -> approx 0.423 (atanh 0.4));
    test "atan2" (fun () -> approx 0.588 (atan2 ~x:0.6 ~y:0.4));
    test "cbrt" (fun () -> assert_float_exact (cbrt 8.) 2.);
    test "unsafe_ceil_int" (fun () -> assert_int (unsafe_ceil_int 3.2) 4);
    test "ceil_int" (fun () -> assert_int (ceil_int 3.2) 4);
    test "ceil_float" (fun () -> assert_float_exact (ceil_float 3.2) 4.);
    test "cos" (fun () -> approx 0.921 (cos 0.4));
    test "cosh" (fun () -> approx 1.081 (cosh 0.4));
    test "exp" (fun () -> approx 1.491 (exp 0.4));
    test "expm1" (fun () -> approx 0.491 (expm1 0.4));
    test "unsafe_floor_int" (fun () -> assert_int (unsafe_floor_int 3.2) 3);
    test "floor_int" (fun () -> assert_int (floor_int 3.2) 3);
    test "floor_float" (fun () -> assert_float_exact (floor_float 3.2) 3.);
    test "fround" (fun () -> approx 3.2 (fround 3.2));
    test "hypot" (fun () -> approx 0.721 (hypot 0.4 0.6));
    test "hypotMany" (fun () -> approx 1.077 (hypotMany [| 0.4; 0.6; 0.8 |]));
    test "imul" (fun () -> assert_int (imul 4 2) 8);
    test "log" (fun () -> approx (-0.916) (log 0.4));
    test "log1p" (fun () -> approx 0.336 (log1p 0.4));
    test "log10" (fun () -> approx (-0.397) (log10 0.4));
    test "log2" (fun () -> approx (-1.321) (log2 0.4));
    test "max_int" (fun () -> assert_int (max_int 2 4) 4);
    test "maxMany_int" (fun () -> assert_int (maxMany_int [| 2; 4; 3 |]) 4);
    test "max_float" (fun () -> assert_float_exact (max_float 2.7 4.2) 4.2);
    test "maxMany_float" (fun () -> assert_float_exact (maxMany_float [| 2.7; 4.2; 3.9 |]) 4.2);
    test "min_int" (fun () -> assert_int (min_int 2 4) 2);
    test "minMany_int" (fun () -> assert_int (minMany_int [| 2; 4; 3 |]) 2);
    test "min_float" (fun () -> assert_float_exact (min_float 2.7 4.2) 2.7);
    test "minMany_float" (fun () -> assert_float_exact (minMany_float [| 2.7; 4.2; 3.9 |]) 2.7);
    test "random" (fun () ->
        let a = random () in
        assert_true "random () is in [0, 1)" (a >= 0. && a < 1.));
    test "random_int" (fun () ->
        let a = random_int 1 3 in
        assert_true "random_int 1 3 is in [1, 3)" (a >= 1 && a < 3));
    test "unsafe_round" (fun () -> assert_int (unsafe_round 3.2) 3);
    test "round" (fun () -> assert_float_exact (round 3.2) 3.);
    test "sign_int" (fun () -> assert_int (sign_int (-4)) (-1));
    test "sign_float" (fun () -> assert_float_exact (sign_float (-4.2)) (-1.));
    test "sign_float -0" (fun () ->
        let r = sign_float (-0.) in
        assert_true "sign_float -0. is -0." (r = 0. && Stdlib.Float.sign_bit r));
    test "sin" (fun () -> approx 0.389 (sin 0.4));
    test "sinh" (fun () -> approx 0.410 (sinh 0.4));
    test "sqrt" (fun () -> approx 0.632 (sqrt 0.4));
    test "tan" (fun () -> approx 0.422 (tan 0.4));
    test "tanh" (fun () -> approx 0.379 (tanh 0.4));
    test "unsafe_trunc" (fun () -> assert_int (unsafe_trunc 4.2156) 4);
    test "trunc" (fun () -> assert_float_exact (trunc 4.2156) 4.);
    (* Additional ECMA-262 semantics not covered by Melange's suite; expected
       values are node REPL output. *)
    test "Math.max(NaN, 1) is NaN (node)" (fun () -> assert_true "nan" (Stdlib.Float.is_nan (max_float Float.nan 1.)));
    test "Math.min(NaN, 1) is NaN (node)" (fun () -> assert_true "nan" (Stdlib.Float.is_nan (min_float Float.nan 1.)));
    test "Math.max(0, -0) is 0 (node)" (fun () -> assert_true "+0" (Stdlib.Float.sign_bit (max_float 0. (-0.)) = false));
    test "Math.min(0, -0) is -0 (node)" (fun () -> assert_true "-0" (Stdlib.Float.sign_bit (min_float 0. (-0.))));
    test "Math.pow(1, Infinity) is NaN (node)" (fun () ->
        assert_true "nan" (Stdlib.Float.is_nan (pow_float ~base:1. ~exp:Float.infinity)));
    test "Math.pow(2, 10) is 1024 (node)" (fun () -> assert_float_exact (pow_float ~base:2. ~exp:10.) 1024.);
    test "Math.round(-0.5) is -0 (node)" (fun () ->
        let r = round (-0.5) in
        assert_true "-0" (r = 0. && Stdlib.Float.sign_bit r));
    test "Math.round(2.5) is 3 (node)" (fun () -> assert_float_exact (round 2.5) 3.);
    test "Math.round(-2.5) is -2 (node)" (fun () -> assert_float_exact (round (-2.5)) (-2.));
    test "Math.clz32(1) is 31 (node)" (fun () -> assert_int (clz32 1) 31);
    test "Math.clz32(0) is 32 (node)" (fun () -> assert_int (clz32 0) 32);
    test "Math.imul(-5, 12) is -60 (node)" (fun () -> assert_int (imul (-5) 12) (-60));
    test "Math.imul(0xffffffff, 5) is -5 (node)" (fun () -> assert_int (imul 0xffffffff 5) (-5));
    test "Math.fround(5.5) is 5.5 (node)" (fun () -> assert_float_exact (fround 5.5) 5.5);
    test "Math.fround(5.05) is 5.050000190734863 (node)" (fun () -> assert_float_exact (fround 5.05) 5.050000190734863);
    test "Math.sign(0) is 0 (node)" (fun () -> assert_float_exact (sign_float 0.) 0.);
    test "Math.trunc(-4.2) is -4 (node)" (fun () -> assert_float_exact (trunc (-4.2)) (-4.));
  ]
