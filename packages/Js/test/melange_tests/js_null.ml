(** Ported from Melange's test suite: jscomp/test/js_null_test.ml (melange 6.0.1-54). *)

open Helpers
open Js.Null

let ok cond = assert_true "expected true" cond

let tests =
  [
    test "toOption - empty" (fun () -> ok (toOption empty = None));
    test "toOption - 'a" (fun () -> ok (toOption (return ()) = Some ()));
    test "return" (fun () ->
        assert_option Alcotest.string "should be equal" (toOption (return "something")) (Some "something"));
    test "test - empty" (fun () -> ok (empty = Js.null));
    test "test - 'a" (fun () -> ok (return () <> empty));
    test "bind - empty" (fun () -> ok (bind empty ~f:(fun v -> v) = empty));
    test "bind - 'a" (fun () -> ok (map (return 2) ~f:(fun n -> n * 2) = return 4));
    test "iter - empty" (fun () ->
        let hit = ref false in
        iter empty ~f:(fun _ -> hit := true);
        assert_bool !hit false);
    test "iter - 'a" (fun () ->
        let hit = ref 0 in
        iter (return 2) ~f:(fun v -> hit := v);
        assert_int !hit 2);
    test "fromOption - None" (fun () -> ok (fromOption None = empty));
    test "fromOption - Some" (fun () -> ok (fromOption (Some 2) = return 2));
    (* Extra: melange raises a JS Error with this message (js_null.ml getExn). *)
    test "getExn raises Js.Exn.Error" (fun () ->
        (match getExn empty with _ -> Alcotest.fail "expected raise" | exception Js.Exn.Error "Js.Null.getExn" -> ());
        assert_int (getExn (return 2)) 2);
  ]
