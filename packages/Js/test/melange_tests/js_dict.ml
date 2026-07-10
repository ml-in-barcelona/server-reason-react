(** Ported from Melange's test suite: jscomp/test/js_dict_test.ml (melange 6.0.1-54).

    The [%obj] literal used to build the sample dict is replaced with [Js.Dict.fromList]. Order-dependent assertions on
    [keys]/[entries]/[values] are compared order-insensitively: native iteration order is Hashtbl bucket order, not
    insertion order. *)

open Helpers
open Js.Dict

let obj () = fromList [ ("foo", 43); ("bar", 86) ]

(* order-insensitive: native iteration order is Hashtbl bucket order *)
let sorted a =
  let a = Stdlib.Array.copy a in
  Stdlib.Array.sort compare a;
  a

let assert_string_array left right = Alcotest.(check (array string)) "should be equal" right left
let assert_int_entries left right = Alcotest.(check (array (pair string int))) "should be equal" right left
let assert_string_entries left right = Alcotest.(check (array (pair string string))) "should be equal" right left
let assert_int_array left right = Alcotest.(check (array int)) "should be equal" right left

let tests =
  [
    test "empty" (fun () -> assert_string_array (keys (empty ())) [||]);
    test "get" (fun () -> assert_option Alcotest.int "should be equal" (get (obj ()) "foo") (Some 43));
    test "get - property not in object" (fun () ->
        assert_option Alcotest.int "should be equal" (get (obj ()) "baz") None);
    test "unsafe_get" (fun () -> assert_int (unsafeGet (obj ()) "foo") 43);
    test "set" (fun () ->
        let o = obj () in
        set o "foo" 36;
        assert_option Alcotest.int "should be equal" (get o "foo") (Some 36));
    test "keys" (fun () -> assert_string_array (sorted (keys (obj ()))) [| "bar"; "foo" |]);
    test "entries" (fun () -> assert_int_entries (sorted (entries (obj ()))) [| ("bar", 86); ("foo", 43) |]);
    test "values" (fun () -> assert_int_array (sorted (values (obj ()))) [| 43; 86 |]);
    test "fromList - []" (fun () -> assert_int_entries (entries (fromList [])) (entries (empty ())));
    test "fromList" (fun () ->
        assert_int_entries (sorted (entries (fromList [ ("x", 23); ("y", 46) ]))) [| ("x", 23); ("y", 46) |]);
    test "fromArray - []" (fun () -> assert_int_entries (entries (fromArray [||])) (entries (empty ())));
    test "fromArray" (fun () ->
        assert_int_entries (sorted (entries (fromArray [| ("x", 23); ("y", 46) |]))) [| ("x", 23); ("y", 46) |]);
    test "map" (fun () ->
        assert_string_entries (sorted (entries (map ~f:string_of_int (obj ())))) [| ("bar", "86"); ("foo", "43") |]);
  ]
