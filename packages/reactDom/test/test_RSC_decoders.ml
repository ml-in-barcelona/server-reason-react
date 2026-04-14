let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left
let assert_int left right = Alcotest.check Alcotest.int "should be equal" right left
let assert_bool left right = Alcotest.check Alcotest.bool "should be equal" right left
let assert_float ?(eps = 0.001) left right = Alcotest.check (Alcotest.float eps) "should be equal" right left

let assert_float_is_nan value =
  if not (Float.is_nan value) then Alcotest.fail (Printf.sprintf "expected NaN, got %f" value)

let assert_float_is_infinity value =
  if not (Float.is_infinite value && value > 0.) then Alcotest.fail (Printf.sprintf "expected Infinity, got %f" value)

let assert_float_is_neg_infinity value =
  if not (Float.is_infinite value && value < 0.) then Alcotest.fail (Printf.sprintf "expected -Infinity, got %f" value)

let assert_float_is_neg_zero value =
  if not (Float.equal value (-0.) && Float.sign_bit value) then
    Alcotest.fail (Printf.sprintf "expected -0., got %f" value)

(* Unwrap Ok or fail the test *)
let unwrap_ok = function Ok v -> v | Error msg -> Alcotest.fail (Printf.sprintf "unexpected Error: %s" msg)
let unwrap_error = function Error msg -> msg | Ok _ -> Alcotest.fail "expected Error but got Ok"

(* Assert that decodeReply returns Error with a message starting with expected_prefix *)
let assert_decodeReply_errors ?temporaryReferences input expected_prefix () =
  match ReactServerDOM.decodeReply ?temporaryReferences input with
  | Ok _ -> Alcotest.fail (Printf.sprintf "expected Error starting with %S" expected_prefix)
  | Error msg ->
      if not (String.starts_with ~prefix:expected_prefix msg) then
        Alcotest.fail (Printf.sprintf "expected prefix %S, got %S" expected_prefix msg)

(* Build FormData with the given entries and root model, then decode *)
let decode_outlined ~entries ~root_json =
  let formData = Js.FormData.make () in
  List.iter (fun (k, v) -> Js.FormData.append formData k (`String v)) entries;
  Js.FormData.append formData "0" (`String root_json);
  ReactServerDOM.decodeFormDataReply formData |> unwrap_ok

(* Basic types *)

let decodeReply_string_and_int () =
  let response = ReactServerDOM.decodeReply "[\"Lola\", 20]" |> unwrap_ok in
  match response with
  | [| `String name; `Int age |] ->
      assert_string name "Lola";
      assert_int age 20
  | _ -> Alcotest.fail "expected [String, Int]"

let decodeReply_bool_and_null () =
  let response = ReactServerDOM.decodeReply "[true, false, null]" |> unwrap_ok in
  match response with
  | [| `Bool t; `Bool f; `Null |] ->
      assert_bool t true;
      assert_bool f false
  | _ -> Alcotest.fail "expected [Bool true, Bool false, Null]"

let decodeReply_float () =
  let response = ReactServerDOM.decodeReply "[3.14, -2.5]" |> unwrap_ok in
  match response with
  | [| `Float pi; `Float neg |] ->
      assert_float pi 3.14;
      assert_float neg (-2.5)
  | _ -> Alcotest.fail "expected [Float, Float]"

let decodeReply_nested_object () =
  let response = ReactServerDOM.decodeReply "[{\"name\": \"Lola\", \"age\": 20}]" |> unwrap_ok in
  match response with
  | [| `Assoc [ ("name", `String name); ("age", `Int age) ] |] ->
      assert_string name "Lola";
      assert_int age 20
  | _ -> Alcotest.fail "expected [Assoc]"

let decodeReply_nested_array () =
  let response = ReactServerDOM.decodeReply "[[1, 2, 3]]" |> unwrap_ok in
  match response with
  | [| `List [ `Int a; `Int b; `Int c ] |] ->
      assert_int a 1;
      assert_int b 2;
      assert_int c 3
  | _ -> Alcotest.fail "expected [List [Int, Int, Int]]"

let decodeReply_empty_args () =
  let response = ReactServerDOM.decodeReply "[]" |> unwrap_ok in
  Alcotest.check Alcotest.int "should have 0 args" (Array.length response) 0

(* Special $-prefixed values *)

let decodeReply_undefined () =
  let response = ReactServerDOM.decodeReply "[\"$undefined\"]" |> unwrap_ok in
  match response with [| `Null |] -> () | _ -> Alcotest.fail "expected [Null] for $undefined"

let decodeReply_undefined_preserves_positions () =
  (* Verifies $undefined converts to Null and does NOT shift array positions *)
  let response = ReactServerDOM.decodeReply "[\"hello\", \"$undefined\", 42]" |> unwrap_ok in
  match response with
  | [| `String hello; `Null; `Int n |] ->
      assert_string hello "hello";
      assert_int n 42
  | _ -> Alcotest.fail "expected [String, Null, Int] — $undefined must preserve position"

let decodeReply_escaped_dollar_string () =
  let response = ReactServerDOM.decodeReply "[\"$$money\"]" |> unwrap_ok in
  match response with
  | [| `String s |] -> assert_string s "money"
  | _ -> Alcotest.fail "expected [String \"money\"] for $$money"

let decodeReply_escaped_dollar_empty () =
  (* "$$" with nothing after the escape should produce an empty string *)
  let response = ReactServerDOM.decodeReply "[\"$$\"]" |> unwrap_ok in
  match response with [| `String s |] -> assert_string s "" | _ -> Alcotest.fail "expected [String \"\"] for $$"

let decodeReply_date () =
  let response = ReactServerDOM.decodeReply "[\"$D2024-01-15T10:30:00.000Z\"]" |> unwrap_ok in
  match response with
  | [| `String s |] -> assert_string s "2024-01-15T10:30:00.000Z"
  | _ -> Alcotest.fail "expected [String] for $D date"

let decodeReply_bigint () =
  let response = ReactServerDOM.decodeReply "[\"$n9007199254740993\"]" |> unwrap_ok in
  match response with
  | [| `String s |] -> assert_string s "9007199254740993"
  | _ -> Alcotest.fail "expected [String] for $n bigint"

let decodeReply_nan () =
  let response = ReactServerDOM.decodeReply "[\"$N\"]" |> unwrap_ok in
  match response with [| `Float f |] -> assert_float_is_nan f | _ -> Alcotest.fail "expected [Float nan] for $N"

let decodeReply_infinity () =
  let response = ReactServerDOM.decodeReply "[\"$I\"]" |> unwrap_ok in
  match response with
  | [| `Float f |] -> assert_float_is_infinity f
  | _ -> Alcotest.fail "expected [Float infinity] for $I"

let decodeReply_neg_infinity () =
  let response = ReactServerDOM.decodeReply "[\"$-\"]" |> unwrap_ok in
  match response with
  | [| `Float f |] -> assert_float_is_neg_infinity f
  | _ -> Alcotest.fail "expected [Float neg_infinity] for $-"

let decodeReply_neg_infinity_long_form () =
  (* React sends "$-Infinity" but any "$-" prefix that isn't "$-0" is neg_infinity *)
  let response = ReactServerDOM.decodeReply "[\"$-Infinity\"]" |> unwrap_ok in
  match response with
  | [| `Float f |] -> assert_float_is_neg_infinity f
  | _ -> Alcotest.fail "expected [Float neg_infinity] for $-Infinity"

let decodeReply_neg_zero () =
  let response = ReactServerDOM.decodeReply "[\"$-0\"]" |> unwrap_ok in
  match response with
  | [| `Float f |] -> assert_float_is_neg_zero f
  | _ -> Alcotest.fail "expected [Float (-0.)] for $-0"

(* Mixed special and regular values *)

let decodeReply_mixed_special_values () =
  let response =
    ReactServerDOM.decodeReply
      "[\"hello\", \"$undefined\", 42, \"$D2024-06-15T00:00:00.000Z\", \"$$price\", \"$N\", \"$I\"]"
    |> unwrap_ok
  in
  match response with
  | [| `String hello; `Null; `Int n; `String date; `String price; `Float nan_val; `Float inf_val |] ->
      assert_string hello "hello";
      assert_int n 42;
      assert_string date "2024-06-15T00:00:00.000Z";
      assert_string price "price";
      assert_float_is_nan nan_val;
      assert_float_is_infinity inf_val
  | _ -> Alcotest.fail "expected mixed special values to decode correctly"

(* Regular string starting with $ that is only 1 char long *)

let decodeReply_single_dollar_string () =
  (* A lone "$" is only 1 char, so it doesn't match the special prefix pattern *)
  let response = ReactServerDOM.decodeReply "[\"$\"]" |> unwrap_ok in
  match response with [| `String s |] -> assert_string s "$" | _ -> Alcotest.fail "expected [String \"$\"] for lone $"

(* Invalid input *)

let decodeReply_invalid_body () =
  let _ = ReactServerDOM.decodeReply "{\"not\": \"a list\"}" |> unwrap_error in
  ()

(* FormData tests *)

let decodeFormDataReply () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "1_name" (`String "Lola");
  Js.FormData.append formData "1_age" (`String "20");
  Js.FormData.append formData "0" (`String "[\"$K1\"]");
  let _, formData = ReactServerDOM.decodeFormDataReply formData |> unwrap_ok in
  match (Js.FormData.get formData "name", Js.FormData.get formData "age") with
  | `String name, `String age ->
      assert_string name "Lola";
      assert_string age "20"

let decodeFormDataReplyWithArg () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "1_name" (`String "Lola");
  Js.FormData.append formData "1_age" (`String "20");
  Js.FormData.append formData "0" (`String "[\"Hello\", \"$K1\"]");
  let args, formData = ReactServerDOM.decodeFormDataReply formData |> unwrap_ok in
  match (args, Js.FormData.get formData "name", Js.FormData.get formData "age") with
  | [| `String greet |], `String name, `String age ->
      assert_string greet "Hello";
      assert_string name "Lola";
      assert_string age "20"
  | _ -> Alcotest.fail "Something went wrong on the decodeFormDataReplyWithArg"

let decodeFormDataReply_with_undefined_arg () =
  (* Simulates: fn(~name: option(string)=?, formData: Js.FormData.t)
     called with name=None. $undefined should become Null, not be filtered. *)
  let formData = Js.FormData.make () in
  Js.FormData.append formData "1_name" (`String "Lola");
  Js.FormData.append formData "0" (`String "[\"$undefined\", \"$K1\"]");
  let args, formData = ReactServerDOM.decodeFormDataReply formData |> unwrap_ok in
  match (args, Js.FormData.get formData "name") with
  | [| `Null |], `String name -> assert_string name "Lola"
  | _ -> Alcotest.fail "expected [Null] for $undefined in FormData args"

let decodeFormDataReply_with_special_values () =
  (* Mixed special values alongside FormData reference *)
  let formData = Js.FormData.make () in
  Js.FormData.append formData "1_file" (`String "data");
  Js.FormData.append formData "0" (`String "[\"$$escaped\", \"$D2024-01-01T00:00:00.000Z\", \"$K1\", \"$N\"]");
  let args, formData = ReactServerDOM.decodeFormDataReply formData |> unwrap_ok in
  match (args, Js.FormData.get formData "file") with
  | [| `String escaped; `String date; `Float nan_val |], `String file ->
      assert_string escaped "escaped";
      assert_string date "2024-01-01T00:00:00.000Z";
      assert_float_is_nan nan_val;
      assert_string file "data"
  | _ -> Alcotest.fail "expected special values decoded correctly with FormData"

(* Outlined model resolution: $Q Map *)

let decodeFormDataReply_map_string_keys () =
  let args, _ =
    decode_outlined ~entries:[ ("1", "[[\"name\",\"Alice\"],[\"role\",\"admin\"]]") ] ~root_json:"[\"$Q1\"]"
  in
  match args with
  | [| `Assoc [ ("name", `String name); ("role", `String role) ] |] ->
      assert_string name "Alice";
      assert_string role "admin"
  | _ -> Alcotest.fail "expected Assoc for Map with string keys"

let decodeFormDataReply_map_non_string_keys () =
  let args, _ = decode_outlined ~entries:[ ("1", "[[1,\"one\"],[2,\"two\"]]") ] ~root_json:"[\"$Q1\"]" in
  match args with
  | [| `List [ `List [ `Int 1; `String one ]; `List [ `Int 2; `String two ] ] |] ->
      assert_string one "one";
      assert_string two "two"
  | _ -> Alcotest.fail "expected List of pairs for Map with non-string keys"

let decodeFormDataReply_map_empty () =
  let args, _ = decode_outlined ~entries:[ ("1", "[]") ] ~root_json:"[\"$Q1\"]" in
  match args with [| `Assoc [] |] -> () | _ -> Alcotest.fail "expected empty Assoc for empty Map"

(* Outlined model resolution: $W Set *)

let decodeFormDataReply_set () =
  let args, _ = decode_outlined ~entries:[ ("1", "[1,2,3]") ] ~root_json:"[\"$W1\"]" in
  match args with [| `List [ `Int 1; `Int 2; `Int 3 ] |] -> () | _ -> Alcotest.fail "expected List for Set"

let decodeFormDataReply_set_strings () =
  let args, _ = decode_outlined ~entries:[ ("1", "[\"a\",\"b\",\"c\"]") ] ~root_json:"[\"$W1\"]" in
  match args with
  | [| `List [ `String "a"; `String "b"; `String "c" ] |] -> ()
  | _ -> Alcotest.fail "expected List of strings for Set"

(* Outlined model resolution: $i Iterator *)

let decodeFormDataReply_iterator () =
  let args, _ = decode_outlined ~entries:[ ("1", "[\"x\",\"y\",\"z\"]") ] ~root_json:"[\"$i1\"]" in
  match args with
  | [| `List [ `String "x"; `String "y"; `String "z" ] |] -> ()
  | _ -> Alcotest.fail "expected List for Iterator"

(* Outlined model resolution: $F Server Reference *)

let decodeFormDataReply_server_ref () =
  let args, _ = decode_outlined ~entries:[ ("1", "{\"id\":\"abc123\",\"bound\":null}") ] ~root_json:"[\"$F1\"]" in
  match args with
  | [| `Assoc [ ("id", `String id); ("bound", `Null) ] |] -> assert_string id "abc123"
  | _ -> Alcotest.fail "expected Assoc {id, bound} for Server Reference"

(* Nested outlined models *)

let decodeFormDataReply_nested_outlined () =
  let args, _ =
    decode_outlined ~entries:[ ("2", "[10,20,30]"); ("1", "[[\"nums\",\"$W2\"]]") ] ~root_json:"[\"$Q1\"]"
  in
  match args with
  | [| `Assoc [ ("nums", `List [ `Int 10; `Int 20; `Int 30 ]) ] |] -> ()
  | _ -> Alcotest.fail "expected nested outlined models to resolve"

let decodeFormDataReply_outlined_with_special_values () =
  let args, _ =
    decode_outlined
      ~entries:[ ("1", "[\"$D2024-01-01T00:00:00.000Z\",\"$undefined\",\"$$dollar\"]") ]
      ~root_json:"[\"$W1\"]"
  in
  match args with
  | [| `List [ `String date; `Null; `String dollar ] |] ->
      assert_string date "2024-01-01T00:00:00.000Z";
      assert_string dollar "dollar"
  | _ -> Alcotest.fail "expected outlined model with special values resolved"

(* Mixed regular args + outlined models + FormData *)

let decodeFormDataReply_mixed_outlined_and_regular () =
  let args, _ = decode_outlined ~entries:[ ("1", "[[\"x\",1],[\"y\",2]]") ] ~root_json:"[\"hello\",\"$Q1\",42]" in
  match args with
  | [| `String "hello"; `Assoc [ ("x", `Int 1); ("y", `Int 2) ]; `Int 42 |] -> ()
  | _ -> Alcotest.fail "expected mixed regular args and outlined model"

let decodeFormDataReply_outlined_and_formdata () =
  let args, fd = decode_outlined ~entries:[ ("1", "[[\"a\",1]]"); ("2_name", "Lola") ] ~root_json:"[\"$Q1\",\"$K2\"]" in
  (match args with
  | [| `Assoc [ ("a", `Int 1) ] |] -> ()
  | _ -> Alcotest.fail "expected outlined Map resolved alongside FormData");
  match Js.FormData.get fd "name" with `String name -> assert_string name "Lola"

(* Hex ID resolution *)

let decodeFormDataReply_hex_id () =
  let args, _ = decode_outlined ~entries:[ ("10", "[\"from_hex\"]") ] ~root_json:"[\"$Wa\"]" in
  match args with
  | [| `List [ `String s ] |] -> assert_string s "from_hex"
  | _ -> Alcotest.fail "expected hex ID 'a' to resolve to FormData key '10'"

(* Blob ($B) resolution *)

let decodeFormDataReply_blob () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "1" (`String "blob-content-here");
  Js.FormData.append formData "0" (`String "[\"$B1\"]");
  let args, _ = ReactServerDOM.decodeFormDataReply formData |> unwrap_ok in
  match args with
  | [| `String data |] -> assert_string data "blob-content-here"
  | _ -> Alcotest.fail "expected blob reference to resolve from FormData"

let decodeReply_blob_without_formdata () =
  match ReactServerDOM.decodeReply {|["$B1"]|} with
  | Error msg ->
      if not (String.starts_with ~prefix:"decodeReply: Blob ($B) requires FormData" msg) then
        Alcotest.fail (Printf.sprintf "expected FormData error, got %S" msg)
  | Ok _ -> Alcotest.fail "expected Error for blob without FormData"

let decodeFormDataReply_blob_missing_entry () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "0" (`String "[\"$B1\"]");
  match ReactServerDOM.decodeFormDataReply formData with
  | Error msg ->
      if not (String.starts_with ~prefix:"decodeReply: Blob ($B) entry not found in FormData for key 1" msg) then
        Alcotest.fail (Printf.sprintf "expected missing entry error, got %S" msg)
  | Ok _ -> Alcotest.fail "expected Error for blob with missing FormData entry"

(* Recursive resolution of nested JSON objects *)

let decodeReply_nested_special_values_in_object () =
  (* Special values inside nested JSON objects get resolved *)
  let response =
    ReactServerDOM.decodeReply "[{\"date\": \"$D2024-01-01T00:00:00.000Z\", \"value\": \"$$50\"}]" |> unwrap_ok
  in
  match response with
  | [| `Assoc [ ("date", `String date); ("value", `String price) ] |] ->
      assert_string date "2024-01-01T00:00:00.000Z";
      assert_string price "50"
  | _ -> Alcotest.fail "expected special values in nested objects to be resolved"

let decodeReply_nested_special_values_in_array () =
  (* Special values inside nested arrays get resolved *)
  let response = ReactServerDOM.decodeReply "[[\"$N\", \"$I\", \"$undefined\"]]" |> unwrap_ok in
  match response with
  | [| `List [ `Float nan_val; `Float inf_val; `Null ] |] ->
      assert_float_is_nan nan_val;
      assert_float_is_infinity inf_val
  | _ -> Alcotest.fail "expected special values in nested arrays to be resolved"

(* Temporary Reference ($T) tests *)

let decodeReply_temporary_reference_resolves () =
  let temporaryReferences = function "abc" -> Some (`String "resolved_value") | _ -> None in
  let response = ReactServerDOM.decodeReply ~temporaryReferences {|["$Tabc"]|} |> unwrap_ok in
  match response with
  | [| `String s |] -> assert_string s "resolved_value"
  | _ -> Alcotest.fail "expected temporary reference to resolve to stored value"

let decodeReply_temporary_reference_not_found () =
  let temporaryReferences = function _ -> None in
  match ReactServerDOM.decodeReply ~temporaryReferences {|["$Txyz"]|} with
  | Error msg ->
      if not (String.starts_with ~prefix:"decodeReply: Temporary Reference $Txyz not found" msg) then
        Alcotest.fail (Printf.sprintf "unexpected error message: %S" msg)
  | Ok _ -> Alcotest.fail "expected Error for missing temporary reference"

let decodeReply_temporary_reference_no_resolver () =
  match ReactServerDOM.decodeReply {|["$Tabc"]|} with
  | Error msg ->
      if not (String.starts_with ~prefix:"decodeReply: Temporary Reference ($T) requires" msg) then
        Alcotest.fail (Printf.sprintf "unexpected error message: %S" msg)
  | Ok _ -> Alcotest.fail "expected Error when no temporaryReferences resolver provided"

let decodeReply_temporary_reference_complex_value () =
  let temporaryReferences = function
    | "obj1" -> Some (`Assoc [ ("key", `String "value"); ("num", `Int 42) ])
    | _ -> None
  in
  let response = ReactServerDOM.decodeReply ~temporaryReferences {|["$Tobj1"]|} |> unwrap_ok in
  match response with
  | [| `Assoc [ ("key", `String v); ("num", `Int n) ] |] ->
      assert_string v "value";
      assert_int n 42
  | _ -> Alcotest.fail "expected temporary reference to resolve to complex value"

let decodeReply_temporary_reference_in_nested_array () =
  let temporaryReferences = function "ref1" -> Some (`String "nested_resolved") | _ -> None in
  let response = ReactServerDOM.decodeReply ~temporaryReferences {|[["$Tref1", 42]]|} |> unwrap_ok in
  match response with
  | [| `List [ `String s; `Int n ] |] ->
      assert_string s "nested_resolved";
      assert_int n 42
  | _ -> Alcotest.fail "expected temporary reference to resolve inside nested array"

let decodeReply_temporary_reference_in_nested_object () =
  let temporaryReferences = function "ref1" -> Some (`String "obj_resolved") | _ -> None in
  let response = ReactServerDOM.decodeReply ~temporaryReferences {|[{"val": "$Tref1", "other": 1}]|} |> unwrap_ok in
  match response with
  | [| `Assoc [ ("val", `String s); ("other", `Int n) ] |] ->
      assert_string s "obj_resolved";
      assert_int n 1
  | _ -> Alcotest.fail "expected temporary reference to resolve inside nested object"

(* decodeAction tests *)

let decodeAction_with_action_id_and_fields () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "$ACTION_ID_abc123" (`String "");
  Js.FormData.append formData "name" (`String "Lola");
  Js.FormData.append formData "age" (`String "20");
  match ReactServerDOM.decodeAction formData with
  | Some (id, user_fd) -> (
      assert_string id "abc123";
      match (Js.FormData.get user_fd "name", Js.FormData.get user_fd "age") with
      | `String name, `String age ->
          assert_string name "Lola";
          assert_string age "20")
  | None -> Alcotest.fail "expected Some but got None"

let decodeAction_no_action_keys () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "name" (`String "Lola");
  Js.FormData.append formData "age" (`String "20");
  match ReactServerDOM.decodeAction formData with None -> () | Some _ -> Alcotest.fail "expected None but got Some"

let decodeAction_action_id_only () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "$ACTION_ID_abc123" (`String "");
  match ReactServerDOM.decodeAction formData with
  | Some (id, user_fd) ->
      assert_string id "abc123";
      let entries = Js.FormData.entries user_fd in
      Alcotest.check Alcotest.int "should have 0 user entries" (List.length entries) 0
  | None -> Alcotest.fail "expected Some but got None"

let decodeAction_multiple_action_keys () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "$ACTION_ID_first" (`String "");
  Js.FormData.append formData "name" (`String "Lola");
  Js.FormData.append formData "$ACTION_ID_second" (`String "");
  match ReactServerDOM.decodeAction formData with
  | Some (id, user_fd) -> (
      (* Either action ID is valid since Hashtbl iteration order is unspecified *)
      assert_bool (String.equal id "first" || String.equal id "second") true;
      match Js.FormData.get user_fd "name" with `String name -> assert_string name "Lola")
  | None -> Alcotest.fail "expected Some but got None"

let decodeAction_filters_other_action_keys () =
  (* $ACTION_REF_ and other $ACTION_ prefixed keys should be filtered out from user data *)
  let formData = Js.FormData.make () in
  Js.FormData.append formData "$ACTION_ID_abc123" (`String "");
  Js.FormData.append formData "$ACTION_REF_xyz" (`String "some_ref");
  Js.FormData.append formData "name" (`String "Lola");
  match ReactServerDOM.decodeAction formData with
  | Some (id, user_fd) -> (
      assert_string id "abc123";
      (match Js.FormData.get user_fd "name" with `String name -> assert_string name "Lola");
      (* $ACTION_REF_ should not be in user_fd *)
      try
        let _ = Js.FormData.get user_fd "$ACTION_REF_xyz" in
        Alcotest.fail "$ACTION_REF_ key should not be in user FormData"
      with Not_found -> ())
  | None -> Alcotest.fail "expected Some but got None"

let test title fn = (Printf.sprintf "Decoders / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    (* Basic types *)
    test "decodeReply: string and int" decodeReply_string_and_int;
    test "decodeReply: bool and null" decodeReply_bool_and_null;
    test "decodeReply: float" decodeReply_float;
    test "decodeReply: nested object" decodeReply_nested_object;
    test "decodeReply: nested array" decodeReply_nested_array;
    test "decodeReply: empty args" decodeReply_empty_args;
    (* Special $-prefixed values *)
    test "decodeReply: $undefined → Null" decodeReply_undefined;
    test "decodeReply: $undefined preserves positions" decodeReply_undefined_preserves_positions;
    test "decodeReply: $$ escaped string" decodeReply_escaped_dollar_string;
    test "decodeReply: $$ empty escape" decodeReply_escaped_dollar_empty;
    test "decodeReply: $D date" decodeReply_date;
    test "decodeReply: $n bigint" decodeReply_bigint;
    test "decodeReply: $N NaN" decodeReply_nan;
    test "decodeReply: $I Infinity" decodeReply_infinity;
    test "decodeReply: $- neg infinity" decodeReply_neg_infinity;
    test "decodeReply: $-Infinity long form" decodeReply_neg_infinity_long_form;
    test "decodeReply: $-0 negative zero" decodeReply_neg_zero;
    test "decodeReply: mixed special values" decodeReply_mixed_special_values;
    test "decodeReply: single $ string" decodeReply_single_dollar_string;
    test "decodeReply: invalid body raises" decodeReply_invalid_body;
    (* Recursive resolution in nested structures *)
    test "decodeReply: special values in nested objects" decodeReply_nested_special_values_in_object;
    test "decodeReply: special values in nested arrays" decodeReply_nested_special_values_in_array;
    (* FormData: basic *)
    test "decodeFormDataReply: basic" decodeFormDataReply;
    test "decodeFormDataReply: with arg" decodeFormDataReplyWithArg;
    test "decodeFormDataReply: $undefined preserves position" decodeFormDataReply_with_undefined_arg;
    test "decodeFormDataReply: special values with FormData" decodeFormDataReply_with_special_values;
    (* FormData: outlined model resolution *)
    test "decodeFormDataReply: $Q Map with string keys → Assoc" decodeFormDataReply_map_string_keys;
    test "decodeFormDataReply: $Q Map with non-string keys → List" decodeFormDataReply_map_non_string_keys;
    test "decodeFormDataReply: $Q Map empty" decodeFormDataReply_map_empty;
    test "decodeFormDataReply: $W Set" decodeFormDataReply_set;
    test "decodeFormDataReply: $W Set of strings" decodeFormDataReply_set_strings;
    test "decodeFormDataReply: $i Iterator" decodeFormDataReply_iterator;
    test "decodeFormDataReply: $F Server Reference" decodeFormDataReply_server_ref;
    test "decodeFormDataReply: nested outlined models" decodeFormDataReply_nested_outlined;
    test "decodeFormDataReply: outlined with special values" decodeFormDataReply_outlined_with_special_values;
    test "decodeFormDataReply: mixed regular + outlined" decodeFormDataReply_mixed_outlined_and_regular;
    test "decodeFormDataReply: outlined + FormData coexist" decodeFormDataReply_outlined_and_formdata;
    test "decodeFormDataReply: hex ID resolution" decodeFormDataReply_hex_id;
    (* Outlined models without FormData context *)
    test "decodeReply: $Q Map without FormData raises" (assert_decodeReply_errors "[\"$Q1\"]" "decodeReply: Map");
    test "decodeReply: $W Set without FormData raises" (assert_decodeReply_errors "[\"$W1\"]" "decodeReply: Set");
    (* Unsupported types raise descriptive errors *)
    test "decodeReply: $@ Promise raises" (assert_decodeReply_errors "[\"$@1\"]" "decodeReply: Promise");
    (* Temporary References ($T) *)
    test "decodeReply: $T resolves with temporaryReferences" decodeReply_temporary_reference_resolves;
    test "decodeReply: $T not found returns error" decodeReply_temporary_reference_not_found;
    test "decodeReply: $T without resolver returns error" decodeReply_temporary_reference_no_resolver;
    test "decodeReply: $T resolves complex value" decodeReply_temporary_reference_complex_value;
    test "decodeReply: $T resolves in nested array" decodeReply_temporary_reference_in_nested_array;
    test "decodeReply: $T resolves in nested object" decodeReply_temporary_reference_in_nested_object;
    test "decodeReply: $A TypedArray raises" (assert_decodeReply_errors "[\"$A1\"]" "decodeReply: TypedArray");
    (* Blob ($B) resolution *)
    test "decodeFormDataReply: $B Blob resolves from FormData" decodeFormDataReply_blob;
    test "decodeReply: $B Blob without FormData returns error" decodeReply_blob_without_formdata;
    test "decodeFormDataReply: $B Blob with missing entry returns error" decodeFormDataReply_blob_missing_entry;
    test "decodeReply: $R ReadableStream raises"
      (assert_decodeReply_errors "[\"$R1\"]" "decodeReply: ReadableStream ($R)");
    test "decodeReply: $r ReadableStream bytes raises"
      (assert_decodeReply_errors "[\"$r1\"]" "decodeReply: ReadableStream bytes");
    test "decodeReply: $X AsyncIterable raises" (assert_decodeReply_errors "[\"$X1\"]" "decodeReply: AsyncIterable");
    test "decodeReply: $x AsyncIterator raises" (assert_decodeReply_errors "[\"$x1\"]" "decodeReply: AsyncIterator");
    test "decodeReply: all TypedArray variants raise" (fun () ->
        List.iter
          (fun prefix -> assert_decodeReply_errors (Printf.sprintf "[\"$%s1\"]" prefix) "decodeReply: TypedArray" ())
          [ "O"; "o"; "U"; "S"; "s"; "L"; "l"; "G"; "g"; "M"; "m"; "V" ]);
    (* decodeAction *)
    test "decodeAction: $ACTION_ID with form fields" decodeAction_with_action_id_and_fields;
    test "decodeAction: no $ACTION_* keys returns None" decodeAction_no_action_keys;
    test "decodeAction: $ACTION_ID with no other fields" decodeAction_action_id_only;
    test "decodeAction: multiple $ACTION_ID keys (unspecified which wins)" decodeAction_multiple_action_keys;
    test "decodeAction: filters $ACTION_* keys from user data" decodeAction_filters_other_action_keys;
  ]
