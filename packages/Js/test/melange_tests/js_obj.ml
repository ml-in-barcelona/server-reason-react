(** Ported from Melange's test suite: jscomp/test/js_obj_test.ml (melange 6.0.1-54).

    [%mel.obj] literals and [##] method application are supported natively via melange.ppx, so most cases are portable.
    The Mt.Eq assertions comparing whole objects structurally are rewritten as field/keys assertions: OCaml structural
    equality is not defined on objects. *)

open Helpers
open Js.Obj

type x = < say : int -> int >

let f (u : x) = u#say 32
let f_js u = u##say 32

let tests =
  [
    test "caml_obj" (fun () ->
        assert_int
          (f
             (object
                method say x = 1 + x
             end))
          33);
    test "js_obj" (fun () -> assert_int (f_js [%mel.obj { say = (fun x -> x + 2) }]) 34);
    test "js_obj2" (fun () -> assert_int ([%mel.obj { say = (fun x -> x + 2) }]##say 32) 34);
    test "empty" (fun () -> assert_int (empty () |> keys |> Stdlib.Array.length) 0);
    test "assign" (fun () ->
        (* Melange asserts Eq([%obj { a = 1 }], assign (empty ()) [%obj { a = 1 }]); whole-object equality is not
           expressible natively, so we assert the assigned key set instead. *)
        Alcotest.(check (array string)) "should be equal" [| "a" |] (keys (assign (empty ()) [%mel.obj { a = 1 }])));
    test "merge" (fun () ->
        (* Native merge takes an extra unit argument. *)
        let original = [%mel.obj { a = 1 }] in
        let merged = merge () original [%mel.obj { a = 2 }] in
        Alcotest.(check (array string)) "should be equal" [| "a" |] (keys merged);
        assert_int merged##a 2);
    test "merge-preserves-original" (fun () ->
        let original = [%mel.obj { a = 1 }] in
        let _merged = merge () original [%mel.obj { a = 2 }] in
        assert_int original##a 1);
  ]
