(** Ported from Melange's test suite: jscomp/test/js_json_test.ml (melange 6.0.1-54).

    Skipped (unsupported natively, raise by design): [stringifyAny], [serializeExn]/[deserializeUnsafe] round-trips, and
    the [%mel.obj] test. Extra parse/stringify cases at the bottom cite node's JSON.parse/JSON.stringify output. *)

open Helpers
module J = Js.Json

let ok cond = assert_true "expected true" cond
let option_get = function None -> Alcotest.fail "expected Some" | Some x -> x

let tests =
  [
    test "parse + classify object with array field" (fun () ->
        let v = J.parseExn {| { "x" : [1, 2, 3 ] } |} in
        (match J.classify v with
        | J.JSONObject x -> (
            match Js.Dict.get x "x" with
            | Some v -> (
                match J.classify v with
                | J.JSONArray x ->
                    Stdlib.Array.iter
                      (fun x -> match J.classify x with J.JSONNumber _ -> () | _ -> Alcotest.fail "expected number")
                      x
                | _ -> Alcotest.fail "expected array")
            | None -> Alcotest.fail "expected x key")
        | _ -> Alcotest.fail "expected object");
        ok (J.test v Object));
    test "null round-trip" (fun () ->
        let json = J.null |> J.stringify |> J.parseExn in
        match J.classify json with J.JSONNull -> () | _ -> Alcotest.fail "expected null");
    test "string round-trip" (fun () ->
        let json = J.string "test string" |> J.stringify |> J.parseExn in
        match J.classify json with
        | J.JSONString x -> assert_string x "test string"
        | _ -> Alcotest.fail "expected string");
    test "number round-trip" (fun () ->
        let json = J.number 1.23456789 |> J.stringify |> J.parseExn in
        match J.classify json with
        | J.JSONNumber x -> assert_float_exact x 1.23456789
        | _ -> Alcotest.fail "expected number");
    test "int number round-trip" (fun () ->
        let json = J.number (float_of_int 0xAFAFAFAF) |> J.stringify |> J.parseExn in
        match J.classify json with
        | J.JSONNumber x -> assert_int (int_of_float x) 0xAFAFAFAF
        | _ -> Alcotest.fail "expected number");
    test "boolean round-trip" (fun () ->
        let check v =
          let json = J.boolean v |> J.stringify |> J.parseExn in
          match J.classify json with
          | J.JSONTrue -> assert_bool true v
          | J.JSONFalse -> assert_bool false v
          | _ -> Alcotest.fail "expected boolean"
        in
        check true;
        check false);
    test "object round-trip" (fun () ->
        let dict = Js.Dict.empty () in
        Js.Dict.set dict "a" (J.string "test string");
        Js.Dict.set dict "b" (J.number 123.0);
        let json = dict |> J.object_ |> J.stringify |> J.parseExn in
        match J.classify json with
        | J.JSONObject x -> (
            (match J.classify (option_get (Js.Dict.get x "a")) with
            | J.JSONString a -> assert_string a "test string"
            | _ -> Alcotest.fail "expected string");
            match J.classify (option_get (Js.Dict.get x "b")) with
            | J.JSONNumber b -> assert_float_exact b 123.0
            | _ -> Alcotest.fail "expected number")
        | _ -> Alcotest.fail "expected object");
    test "array of strings round-trip" (fun () ->
        let expect_string_at json i expected =
          match J.classify json with
          | J.JSONArray x -> (
              match J.classify (Stdlib.Array.get x i) with
              | J.JSONString s -> assert_string s expected
              | _ -> Alcotest.fail "expected string")
          | _ -> Alcotest.fail "expected array"
        in
        let json =
          [| "string 0"; "string 1"; "string 2" |] |> Stdlib.Array.map J.string |> J.array |> J.stringify |> J.parseExn
        in
        expect_string_at json 0 "string 0";
        expect_string_at json 1 "string 1";
        expect_string_at json 2 "string 2";
        let json = [| "string 0"; "string 1"; "string 2" |] |> J.stringArray |> J.stringify |> J.parseExn in
        expect_string_at json 0 "string 0";
        expect_string_at json 1 "string 1";
        expect_string_at json 2 "string 2");
    test "array of numbers round-trip" (fun () ->
        let expect_number_at json i expected =
          match J.classify json with
          | J.JSONArray x -> (
              match J.classify (Stdlib.Array.get x i) with
              | J.JSONNumber n -> assert_float_exact n expected
              | _ -> Alcotest.fail "expected number")
          | _ -> Alcotest.fail "expected array"
        in
        let a = [| 1.0000001; 10000000000.1; 123.0 |] in
        let json = a |> J.numberArray |> J.stringify |> J.parseExn in
        expect_number_at json 0 a.(0);
        expect_number_at json 1 a.(1);
        expect_number_at json 2 a.(2);
        let b = [| 0; 0xAFAFAFAF; 0xF000AABB |] in
        let json = b |> Stdlib.Array.map float_of_int |> J.numberArray |> J.stringify |> J.parseExn in
        expect_number_at json 0 (float_of_int b.(0));
        expect_number_at json 1 (float_of_int b.(1));
        expect_number_at json 2 (float_of_int b.(2)));
    test "array of booleans round-trip" (fun () ->
        let a = [| true; false; true |] in
        let json = a |> J.booleanArray |> J.stringify |> J.parseExn in
        match J.classify json with
        | J.JSONArray x ->
            Stdlib.Array.iteri
              (fun i expected ->
                match J.classify (Stdlib.Array.get x i) with
                | J.JSONTrue -> assert_bool true expected
                | J.JSONFalse -> assert_bool false expected
                | _ -> Alcotest.fail "expected boolean")
              a
        | _ -> Alcotest.fail "expected array");
    test "array of objects round-trip" (fun () ->
        let make_d s i =
          let d = Js.Dict.empty () in
          Js.Dict.set d "a" (J.string s);
          Js.Dict.set d "b" (J.number (float_of_int i));
          d
        in
        let a = [| make_d "aaa" 123; make_d "bbb" 456 |] in
        let json = a |> J.objectArray |> J.stringify |> J.parseExn in
        match J.classify json with
        | J.JSONArray x -> (
            match J.classify (Stdlib.Array.get x 1) with
            | J.JSONObject a1 -> (
                match J.classify (option_get (Js.Dict.get a1 "a")) with
                | J.JSONString aValue -> assert_string aValue "bbb"
                | _ -> Alcotest.fail "expected string")
            | _ -> Alcotest.fail "expected object")
        | _ -> Alcotest.fail "expected array");
    test "parseExn raises on invalid JSON" (fun () ->
        match J.parseExn "{{ A}" with _ -> Alcotest.fail "expected raise" | exception Js.Exn.SyntaxError _ -> ());
    test "decodeString" (fun () ->
        assert_option Alcotest.string "should be equal" (J.decodeString (J.string "test")) (Some "test");
        assert_option Alcotest.string "should be equal" (J.decodeString (J.boolean true)) None;
        assert_option Alcotest.string "should be equal" (J.decodeString (J.array [||])) None;
        assert_option Alcotest.string "should be equal" (J.decodeString J.null) None;
        assert_option Alcotest.string "should be equal" (J.decodeString (J.object_ (Js.Dict.empty ()))) None;
        assert_option Alcotest.string "should be equal" (J.decodeString (J.number 1.23)) None);
    test "decodeNumber" (fun () ->
        ok (J.decodeNumber (J.string "test") = None);
        ok (J.decodeNumber (J.boolean true) = None);
        ok (J.decodeNumber (J.array [||]) = None);
        ok (J.decodeNumber J.null = None);
        ok (J.decodeNumber (J.object_ (Js.Dict.empty ())) = None);
        ok (J.decodeNumber (J.number 1.23) = Some 1.23));
    test "decodeObject" (fun () ->
        ok (J.decodeObject (J.string "test") = None);
        ok (J.decodeObject (J.boolean true) = None);
        ok (J.decodeObject (J.array [||]) = None);
        ok (J.decodeObject J.null = None);
        ok (J.decodeObject (J.object_ (Js.Dict.empty ())) <> None);
        ok (J.decodeObject (J.number 1.23) = None));
    test "decodeArray" (fun () ->
        ok (J.decodeArray (J.string "test") = None);
        ok (J.decodeArray (J.boolean true) = None);
        ok (J.decodeArray (J.array [||]) = Some [||]);
        ok (J.decodeArray J.null = None);
        ok (J.decodeArray (J.object_ (Js.Dict.empty ())) = None);
        ok (J.decodeArray (J.number 1.23) = None));
    test "decodeBoolean" (fun () ->
        ok (J.decodeBoolean (J.string "test") = None);
        ok (J.decodeBoolean (J.boolean true) = Some true);
        ok (J.decodeBoolean (J.array [||]) = None);
        ok (J.decodeBoolean J.null = None);
        ok (J.decodeBoolean (J.object_ (Js.Dict.empty ())) = None);
        ok (J.decodeBoolean (J.number 1.23) = None));
    test "decodeNull" (fun () ->
        ok (J.decodeNull (J.string "test") = None);
        ok (J.decodeNull (J.boolean true) = None);
        ok (J.decodeNull (J.array [||]) = None);
        ok (J.decodeNull J.null = Some Js.null);
        ok (J.decodeNull (J.object_ (Js.Dict.empty ())) = None);
        ok (J.decodeNull (J.number 1.23) = None));
    (* --- Extra cases, expectations are node's JSON.parse/JSON.stringify output --- *)
    test "JSON.stringify(1) is \"1\" (node)" (fun () -> assert_string (J.stringify (J.number 1.)) "1");
    test "JSON.stringify(1e21) is \"1e+21\" (node)" (fun () -> assert_string (J.stringify (J.number 1e21)) "1e+21");
    test "JSON.stringify(NaN) is \"null\" (node)" (fun () -> assert_string (J.stringify (J.number Float.nan)) "null");
    test "JSON.stringify(Infinity) is \"null\" (node)" (fun () ->
        assert_string (J.stringify (J.number Float.infinity)) "null");
    test "JSON.stringify escapes (node)" (fun () ->
        assert_string (J.stringify (J.string "a\"b\\c\nd\t\001")) {|"a\"b\\c\nd\t\u0001"|});
    test "JSON.stringify with space (node)" (fun () ->
        assert_string (J.stringifyWithSpace (J.parseExn {|{"a":[1]}|}) 2) "{\n  \"a\": [\n    1\n  ]\n}");
    test "JSON.parse unicode escapes (node)" (fun () ->
        (match J.classify (J.parseExn {|"\u4e2d"|}) with
        | J.JSONString s -> assert_string s "\xE4\xB8\xAD"
        | _ -> Alcotest.fail "expected string");
        match J.classify (J.parseExn {|"\ud83d\ude00"|}) with
        | J.JSONString s -> assert_string s "\xF0\x9F\x98\x80"
        | _ -> Alcotest.fail "expected string");
    test "JSON.parse duplicate keys keep the last (node)" (fun () ->
        assert_string (J.stringify (J.parseExn {|{"a":1,"a":2}|})) {|{"a":2}|});
    test "JSON.parse rejects trailing input (node)" (fun () ->
        match J.parseExn "[1,]" with
        | _ -> Alcotest.fail "expected raise"
        | exception Js.Exn.SyntaxError _ -> (
            match J.parseExn "01" with _ -> Alcotest.fail "expected raise" | exception Js.Exn.SyntaxError _ -> ()));
    test "patch is the identity (no undefined natively)" (fun () ->
        let v = J.parseExn {|{"a":[1,null]}|} in
        ok (J.patch v == v));
  ]
