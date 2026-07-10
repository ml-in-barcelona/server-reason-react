(** Ported from Melange's test suite: jscomp/test/js_re_test.ml (melange 6.0.1-54).

    Natively [Js.Nullable.return x] is [Some x] and [Js.Nullable.undefined] is [None], so captures compare directly as
    options. *)

open Helpers

let assert_option_string left right = assert_option Alcotest.string "should be equal" left right

let tests =
  [
    test "captures" (fun () ->
        let re = [%re "/(\\d+)-(?:(\\d+))?/g"] in
        let str = "3-" in
        match re |> Js.Re.exec ~str with
        | Some result ->
            let defined = (Js.Re.captures result).(1) in
            let undefined = (Js.Re.captures result).(2) in
            assert_option_string defined (Some "3");
            assert_option_string undefined None
        | None -> Alcotest.fail "expected match");
    test "fromString" (fun () ->
        (* From the example in js_re.mli *)
        let contentOf tag xmlString =
          match Js.Re.fromString ("<" ^ tag ^ ">(.*?)<\\/" ^ tag ^ ">") |> Js.Re.exec ~str:xmlString with
          | Some result -> (Js.Re.captures result).(1)
          | None -> None
        in
        assert_option_string (contentOf "div" "<div>Hi</div>") (Some "Hi"));
    test "exec_literal" (fun () ->
        match [%re "/[^.]+/"] |> Js.Re.exec ~str:"http://xxx.domain.com" with
        | Some res -> assert_option_string (Js.Re.captures res).(0) (Some "http://xxx")
        | None -> Alcotest.fail "regex should match");
    test "exec_no_match" (fun () ->
        match [%re "/https:\\/\\/(.*)/"] |> Js.Re.exec ~str:"http://xxx.domain.com" with
        | Some _ -> Alcotest.fail "regex should not match"
        | None -> ());
    test "test_str" (fun () ->
        let res = "foo" |> Js.Re.fromString |> Js.Re.test ~str:"#foo#" in
        assert_bool res true);
    test "fromStringWithFlags" (fun () ->
        let res = Js.Re.fromStringWithFlags "foo" ~flags:"g" in
        assert_bool (Js.Re.global res) true);
    test "result_index" (fun () ->
        match "zbar" |> Js.Re.fromString |> Js.Re.exec ~str:"foobarbazbar" with
        | Some res -> assert_int (Js.Re.index res) 8
        | None -> Alcotest.fail "expected match");
    test "result_input" (fun () ->
        let input = "foobar" in
        match [%re "/foo/g"] |> Js.Re.exec ~str:input with
        | Some res -> assert_string (Js.Re.input res) input
        | None -> Alcotest.fail "expected match");
    (* es2015 *)
    test "t_flags" (fun () -> assert_string (Js.Re.flags [%re "/./ig"]) "gi");
    test "t_global" (fun () -> assert_bool (Js.Re.global [%re "/./ig"]) true);
    test "t_ignoreCase" (fun () -> assert_bool (Js.Re.ignoreCase [%re "/./ig"]) true);
    test "t_lastIndex" (fun () ->
        let re = [%re "/na/g"] in
        let _ = re |> Js.Re.exec ~str:"banana" in
        assert_int (Js.Re.lastIndex re) 4);
    test "t_setLastIndex" (fun () ->
        let re = [%re "/na/g"] in
        let before = Js.Re.lastIndex re in
        let () = Js.Re.setLastIndex re 42 in
        let after = Js.Re.lastIndex re in
        assert_int before 0;
        assert_int after 42);
    test "t_multiline" (fun () -> assert_bool (Js.Re.multiline [%re "/./ig"]) false);
    test "t_source" (fun () -> assert_string (Js.Re.source [%re "/f.+o/ig"]) "f.+o");
    (* es2015 *)
    test "t_sticky" (fun () -> assert_bool (Js.Re.sticky [%re "/./yg"]) true);
    test "t_unicode" (fun () -> assert_bool (Js.Re.unicode [%re "/./yg"]) false);
  ]
