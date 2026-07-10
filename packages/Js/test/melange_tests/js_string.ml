(** Ported from Melange's test suite: jscomp/test/js_string_test.ml (melange 6.0.1-54).

    Skipped: the [make] test ([Js.String.make] raises natively, alert not_implemented). [toLocaleLowerCase] and
    [toLocaleUpperCase] are aliased to the non-locale versions natively (documented divergence), but Melange's
    expectations are ASCII-only so they hold anyway. *)

open Helpers

let ok cond = assert_true "expected true" cond
let assert_str_opt_array actual expected = Alcotest.(check (array (option string))) "should be equal" expected actual
let assert_match actual expected = Alcotest.(check (option (array (option string)))) "should be equal" expected actual
let assert_str_array actual expected = Alcotest.(check (array string)) "should be equal" expected actual

let tests =
  [
    (* skipped: "make" — [Js.String.make] is not implemented natively (raises by design, see Js_string.mli alert) *)
    test "fromCharCode" (fun () -> assert_string (Js.String.fromCharCode 97) "a");
    test "fromCharCodeMany" (fun () -> assert_string (Js.String.fromCharCodeMany [| 97; 122 |]) "az");
    (* es2015 *)
    test "fromCodePoint" (fun () -> assert_string (Js.String.fromCodePoint 0x61) "a");
    test "fromCodePointMany" (fun () -> assert_string (Js.String.fromCodePointMany [| 0x61; 0x7a |]) "az");
    test "length" (fun () -> assert_int (Js.String.length "foo") 3);
    test "get" (fun () -> assert_string (Js.String.get "foobar" 4) "a");
    test "charAt" (fun () -> assert_string (Js.String.charAt ~index:4 "foobar") "a");
    test "charCodeAt" (fun () -> assert_float_exact (Js.String.charCodeAt ~index:4 "foobar") 97.);
    (* es2015 *)
    test "codePointAt" (fun () ->
        assert_option Alcotest.int "should be equal" (Js.String.codePointAt ~index:4 "foobar") (Some 0x61));
    test "codePointAt - out of bounds" (fun () ->
        assert_option Alcotest.int "should be equal" (Js.String.codePointAt ~index:98 "foobar") None);
    test "concat" (fun () -> assert_string (Js.String.concat ~other:"bar" "foo") "foobar");
    test "concatMany" (fun () -> assert_string (Js.String.concatMany ~strings:[| "bar"; "baz" |] "foo") "foobarbaz");
    (* es2015 *)
    test "endsWith" (fun () -> assert_bool (Js.String.endsWith ~suffix:"bar" "foobar") true);
    test "endsWithFrom" (fun () -> assert_bool (Js.String.endsWith ~suffix:"bar" ~len:1 "foobar") false);
    (* es2015 *)
    test "includes" (fun () -> assert_bool (Js.String.includes ~search:"bar" "foobarbaz") true);
    test "includesFrom" (fun () -> assert_bool (Js.String.includes ~search:"bar" ~start:4 "foobarbaz") false);
    test "indexOf" (fun () -> assert_int (Js.String.indexOf ~search:"bar" "foobarbaz") 3);
    test "indexOfFrom" (fun () -> assert_int (Js.String.indexOf ~search:"bar" ~start:4 "foobarbaz") (-1));
    test "lastIndexOf" (fun () -> assert_int (Js.String.lastIndexOf ~search:"bar" "foobarbaz") 3);
    test "lastIndexOfFrom" (fun () -> assert_int (Js.String.lastIndexOf ~search:"bar" ~start:4 "foobarbaz") 3);
    (* Note: localeCompare is byte-wise natively (no ICU), but equal strings compare 0 either way. *)
    test "localeCompare" (fun () -> assert_float_exact (Js.String.localeCompare ~other:"foo" "foo") 0.);
    test "match" (fun () ->
        assert_match (Js.String.match_ ~regexp:[%re "/na+/g"] "banana") (Some [| Some "na"; Some "na" |]));
    test "match - no match" (fun () -> assert_match (Js.String.match_ ~regexp:[%re "/nanana+/g"] "banana") None);
    test "match - not found capture groups" (fun () ->
        assert_match (Js.String.match_ ~regexp:[%re "/hello (world)?/"] "hello word") (Some [| Some "hello "; None |]));
    (* es2015 *)
    test "normalize" (fun () -> assert_string (Js.String.normalize "foo") "foo");
    test "normalizeByForm" (fun () -> assert_string (Js.String.normalize ~form:`NFKD "foo") "foo");
    (* es2015 *)
    test "repeat" (fun () -> assert_string (Js.String.repeat ~count:3 "foo") "foofoofoo");
    test "replace" (fun () ->
        assert_string (Js.String.replace ~search:"bar" ~replacement:"BORK" "foobarbaz") "fooBORKbaz");
    test "replaceByRe" (fun () ->
        assert_string (Js.String.replaceByRe ~regexp:[%re "/ba./g"] ~replacement:"BORK" "foobarbaz") "fooBORKBORK");
    test "unsafeReplaceBy0" (fun () ->
        let replace whole _offset _s = if whole = "bar" then "BORK" else "DORK" in
        assert_string (Js.String.unsafeReplaceBy0 ~regexp:[%re "/ba./g"] ~f:replace "foobarbaz") "fooBORKDORK");
    test "unsafeReplaceBy1" (fun () ->
        let replace whole _p1 _offset _s = if whole = "bar" then "BORK" else "DORK" in
        assert_string (Js.String.unsafeReplaceBy1 ~regexp:[%re "/ba./g"] ~f:replace "foobarbaz") "fooBORKDORK");
    test "unsafeReplaceBy2" (fun () ->
        let replace whole _p1 _p2 _offset _s = if whole = "bar" then "BORK" else "DORK" in
        assert_string (Js.String.unsafeReplaceBy2 ~regexp:[%re "/ba./g"] ~f:replace "foobarbaz") "fooBORKDORK");
    test "unsafeReplaceBy3" (fun () ->
        let replace whole _p1 _p2 _p3 _offset _s = if whole = "bar" then "BORK" else "DORK" in
        assert_string (Js.String.unsafeReplaceBy3 ~regexp:[%re "/ba./g"] ~f:replace "foobarbaz") "fooBORKDORK");
    test "search" (fun () -> assert_int (Js.String.search ~regexp:[%re "/ba./g"] "foobarbaz") 3);
    test "slice" (fun () -> assert_string (Js.String.slice ~start:3 ~end_:6 "foobarbaz") "bar");
    test "sliceToEnd" (fun () -> assert_string (Js.String.slice ~start:3 "foobarbaz") "barbaz");
    test "split" (fun () -> assert_str_array (Js.String.split ~sep:" " "foo bar baz") [| "foo"; "bar"; "baz" |]);
    test "splitAtMost" (fun () -> assert_str_array (Js.String.split ~sep:" " ~limit:2 "foo bar baz") [| "foo"; "bar" |]);
    test "splitByRe" (fun () ->
        assert_str_opt_array
          (Js.String.splitByRe ~regexp:[%re "/(#)(:)?/"] "a#b#:c")
          [| Some "a"; Some "#"; None; Some "b"; Some "#"; Some ":"; Some "c" |]);
    test "splitByReAtMost" (fun () ->
        assert_str_opt_array
          (Js.String.splitByRe ~regexp:[%re "/(#)(:)?/"] ~limit:3 "a#b#:c")
          [| Some "a"; Some "#"; None |]);
    (* es2015 *)
    test "startsWith" (fun () -> assert_bool (Js.String.startsWith ~prefix:"foo" "foobarbaz") true);
    test "startsWithFrom" (fun () -> assert_bool (Js.String.startsWith ~prefix:"foo" ~start:1 "foobarbaz") false);
    test "substr" (fun () -> assert_string (Js.String.substr ~start:3 "foobarbaz") "barbaz");
    test "substrAtMost" (fun () -> assert_string (Js.String.substr ~start:3 ~len:3 "foobarbaz") "bar");
    test "substring" (fun () -> assert_string (Js.String.substring ~start:3 ~end_:6 "foobarbaz") "bar");
    test "substringToEnd" (fun () -> assert_string (Js.String.substring ~start:3 "foobarbaz") "barbaz");
    test "toLowerCase" (fun () -> assert_string (Js.String.toLowerCase "BORK") "bork");
    test "toLocaleLowerCase" (fun () -> assert_string (Js.String.toLocaleLowerCase "BORK") "bork");
    test "toUpperCase" (fun () -> assert_string (Js.String.toUpperCase "fubar") "FUBAR");
    test "toLocaleUpperCase" (fun () -> assert_string (Js.String.toLocaleUpperCase "fubar") "FUBAR");
    test "trim" (fun () -> assert_string (Js.String.trim "  foo  ") "foo");
    (* es2015 *)
    test "anchor" (fun () -> assert_string (Js.String.anchor ~name:"bar" "foo") "<a name=\"bar\">foo</a>");
    test "link" (fun () ->
        assert_string (Js.String.link ~href:"https://reason.ml" "foo") "<a href=\"https://reason.ml\">foo</a>");
    test "includes returns true" (fun () -> ok (Js.String.includes "ab" ~search:"a"));
  ]
