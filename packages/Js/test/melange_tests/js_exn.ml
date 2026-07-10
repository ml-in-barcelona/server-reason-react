(** Tests for Js.Exn accessors. Expected values follow JS Error semantics: [new Error("msg").message] is ["msg"],
    [.name] is the constructor name (node REPL output). Melange's [asJsExn] returns [None] for non-JS exceptions. *)

open Helpers

let ok cond = assert_true "expected true" cond
let get = function None -> Alcotest.fail "expected Some" | Some x -> x

let tests =
  [
    test "asJsExn returns Some for JS-style exceptions" (fun () ->
        let e = try Js.Exn.raiseError "boom" with e -> e in
        let t = get (Js.Exn.asJsExn e) in
        assert_option Alcotest.string "should be equal" (Js.Exn.message t) (Some "boom");
        assert_option Alcotest.string "should be equal" (Js.Exn.name t) (Some "Error"));
    test "error names match JS constructor names (node)" (fun () ->
        let name_of raise_fn = (try raise_fn "x" with e -> e) |> Js.Exn.asJsExn |> get |> Js.Exn.name in
        assert_option Alcotest.string "should be equal" (name_of Js.Exn.raiseEvalError) (Some "EvalError");
        assert_option Alcotest.string "should be equal" (name_of Js.Exn.raiseRangeError) (Some "RangeError");
        assert_option Alcotest.string "should be equal" (name_of Js.Exn.raiseReferenceError) (Some "ReferenceError");
        assert_option Alcotest.string "should be equal" (name_of Js.Exn.raiseSyntaxError) (Some "SyntaxError");
        assert_option Alcotest.string "should be equal" (name_of Js.Exn.raiseTypeError) (Some "TypeError");
        assert_option Alcotest.string "should be equal" (name_of Js.Exn.raiseUriError) (Some "URIError"));
    test "asJsExn returns None for OCaml exceptions" (fun () -> ok (Js.Exn.asJsExn Stdlib.Not_found = None));
    test "stack and fileName are None natively" (fun () ->
        let t = get (Js.Exn.asJsExn (try Js.Exn.raiseError "boom" with e -> e)) in
        ok (Js.Exn.stack t = None);
        ok (Js.Exn.fileName t = None));
  ]
