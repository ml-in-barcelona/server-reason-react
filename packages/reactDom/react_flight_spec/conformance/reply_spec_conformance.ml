(* Reply-direction conformance runner: parses the committed reply fixtures
   (client->server bodies produced by the real React encodeReply, see
   ../reply/generate-reply.mjs), feeds them to srr's decoders — decodeReply
   for string bodies, decodeFormDataReply for FormData bodies — and compares
   the decoded result against the expected value declared per case below.

   The fixture is the wire truth (what React sends); the [expected] value is
   the spec's assertion of srr's decode semantics for those exact bytes.

   Cases annotated with [xfail] are asserted to MISMATCH: they are known
   divergences and must flip loudly (test failure) once fixed.

   This runner only READS committed fixtures: it works offline, without bun
   or node_modules. *)

let fixtures_dir = "../reply/fixtures"

(* ----------------------------------------------------------------------- *)
(* Fixture parsing (format documented in ../reply/generate-reply.mjs and
   protocol.md, "Reply fixtures")                                           *)
(* ----------------------------------------------------------------------- *)

(* Standard base64 (RFC 4648), enough for the blob entries in fixtures. *)
let base64_decode input =
  let sextet c =
    match c with
    | 'A' .. 'Z' -> Char.code c - Char.code 'A'
    | 'a' .. 'z' -> Char.code c - Char.code 'a' + 26
    | '0' .. '9' -> Char.code c - Char.code '0' + 52
    | '+' -> 62
    | '/' -> 63
    | _ -> invalid_arg (Printf.sprintf "base64_decode: invalid character %C" c)
  in
  let buf = Buffer.create (String.length input) in
  let acc = ref 0 in
  let bits = ref 0 in
  String.iter
    (fun c ->
      if c <> '=' then (
        acc := (!acc lsl 6) lor sextet c;
        bits := !bits + 6;
        if !bits >= 8 then (
          bits := !bits - 8;
          Buffer.add_char buf (Char.chr ((!acc lsr !bits) land 0xff)))))
    input;
  Buffer.contents buf

type body =
  | String_body of string
  | FormData_body of (string * string) list (* key, value — blob entries base64-decoded to bytes *)

let read_fixture name =
  let path = Filename.concat fixtures_dir (name ^ ".reply") in
  if not (Sys.file_exists path) then
    Alcotest.failf "fixture %s is missing; run `make spec-generate-reply` and commit the result" path;
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in ic) (fun () -> really_input_string ic (in_channel_length ic))

let parse_formdata_entry line =
  match Yojson.Basic.from_string line with
  | `List [ `String "string"; `String key; `String value ] -> (key, value)
  | `List [ `String "blob"; `String key; `String base64 ] -> (key, base64_decode base64)
  | _ -> Alcotest.failf "unrecognized reply fixture entry: %s" line
  | exception Yojson.Json_error msg -> Alcotest.failf "invalid JSON in reply fixture entry %S: %s" line msg

let parse_fixture name =
  let contents = read_fixture name in
  let lines = String.split_on_char '\n' contents in
  let lines = match List.rev lines with "" :: rest -> List.rev rest | _ -> lines in
  match lines with
  | [ "string"; body ] -> String_body body
  | "formdata" :: entries -> FormData_body (List.map parse_formdata_entry entries)
  | _ -> Alcotest.failf "fixture %s.reply is malformed (expected `string` or `formdata` header)" name

(* ----------------------------------------------------------------------- *)
(* Case registry: kept in sync with ../reply/cases.mjs (the runner fails on
   fixtures without a case and cases without a fixture).                    *)
(* ----------------------------------------------------------------------- *)

type case = {
  name : string;
  temporary_references : (string -> Yojson.Basic.t option) option;
  expected_args : Yojson.Basic.t list;
  (* Expected residual FormData returned by decodeFormDataReply, sorted by
     key ([Js.FormData.entries] order is unspecified). Empty for string
     bodies. *)
  expected_form_entries : (string * string) list;
  xfail : string option;
}

let case ?temporary_references ?(form = []) ?xfail name expected_args =
  { name; temporary_references; expected_args; expected_form_entries = form; xfail }

let all : case list =
  [
    (* String bodies *)
    case "primitives" [ `String "hello"; `Int 42; `Float 3.14; `Bool true; `Bool false; `Null ];
    case "numbers" [ `Int 0; `Int (-1); `Int 1073741824; `Float 1e21; `Float 1.5; `Float (-3.5) ];
    case "empty_args" [];
    (* React escapes user strings starting with `$` by prepending one `$`
       ("$money" -> "$$money"); its decoder strips only that escape
       character. srr's decodeReply strips the escape AND the first payload
       character ("$$money" -> "money" instead of "$money"). *)
    case "dollar_strings" [ `String "$money"; `String "$$x"; `String "$"; `String "price is $10" ];
    case "undefined_arg" [ `String "a"; `Null; `Int 42 ];
    case "date" [ `String "2024-01-15T10:30:00.000Z" ];
    case "bigint" [ `String "9007199254740993" ];
    case "nonfinite_numbers" [ `Float Float.nan; `Float Float.infinity; `Float Float.neg_infinity; `Float (-0.) ];
    case "nested_object"
      [
        `Assoc
          [
            ("user", `Assoc [ ("name", `String "Lola"); ("tags", `List [ `String "a"; `String "b" ]) ]); ("meta", `Null);
          ];
      ];
    case "nested_array" [ `List [ `Int 1; `List [ `Int 2; `List [ `Int 3 ] ] ] ];
    case "unicode_string" [ `String "héllo → 🚀"; `String "line\nbreak\ttab" ];
    case "mixed_special"
      [ `String "hello"; `Null; `Int 42; `String "2024-06-15T00:00:00.000Z"; `Float Float.nan; `Float Float.infinity ];
    (* React 19.1 serializes temporary references as a bare "$T" (the key is
       the object path, tracked by the temporary reference set, not part of
       the wire string), so srr's resolver is called with the empty id. *)
    case "temporary_reference"
      ~temporary_references:(function "" -> Some (`String "<temporary>") | _ -> None)
      [ `Assoc [ ("fn", `String "<temporary>") ] ];
    (* FormData bodies. Outlined entries that are not consumed as $K input
       pass through into the residual FormData returned by
       decodeFormDataReply (they are not filtered out). *)
    case "map_string_keys"
      [ `Assoc [ ("name", `String "Alice"); ("role", `String "admin") ] ]
      ~form:[ ("1", {|[["name","Alice"],["role","admin"]]|}) ];
    case "map_number_keys"
      [ `List [ `List [ `Int 1; `String "one" ]; `List [ `Int 2; `String "two" ] ] ]
      ~form:[ ("1", {|[[1,"one"],[2,"two"]]|}) ];
    case "map_empty" [ `Assoc [] ] ~form:[ ("1", "[]") ];
    case "map_of_dates"
      [ `Assoc [ ("d", `String "2024-06-15T00:00:00.000Z") ] ]
      ~form:[ ("1", {|[["d","$D2024-06-15T00:00:00.000Z"]]|}) ];
    case "set_numbers" [ `List [ `Int 1; `Int 2; `Int 3 ] ] ~form:[ ("1", "[1,2,3]") ];
    case "set_strings" [ `List [ `String "a"; `String "b"; `String "c" ] ] ~form:[ ("1", {|["a","b","c"]|}) ];
    case "set_in_map"
      [ `Assoc [ ("nums", `List [ `Int 10; `Int 20; `Int 30 ]) ] ]
      ~form:[ ("1", {|[["nums","$W2"]]|}); ("2", "[10,20,30]") ];
    case "map_in_object"
      [ `Assoc [ ("config", `Assoc [ ("x", `Int 1) ]) ]; `String "tail" ]
      ~form:[ ("1", {|[["x",1]]|}) ];
    (* A top-level FormData argument is consumed: it is removed from the args
       array and returned as the residual FormData with the "<id>_" prefix
       stripped. *)
    case "formdata" [] ~form:[ ("age", "20"); ("name", "Lola") ];
    case "formdata_with_leading_arg" [ `String "Hello" ] ~form:[ ("age", "20"); ("name", "Lola") ];
    (* A FormData nested inside an object is NOT reconstructed: srr has no
       Yojson representation for it, so the $K reference decodes to `Null and
       its prefixed entries pass through untouched. *)
    case "formdata_nested" [ `Assoc [ ("form", `Null) ] ] ~form:[ ("1_name", "Lola") ];
    case "blob_text" [ `String "blob-content-here" ] ~form:[ ("1", "blob-content-here") ];
    case "server_reference"
      [ `Assoc [ ("id", `String "srv#action"); ("bound", `Null) ] ]
      ~form:[ ("1", {|{"id":"srv#action","bound":null}|}) ];
    case "server_reference_nested"
      [ `Assoc [ ("fn", `Assoc [ ("id", `String "srv#action"); ("bound", `Null) ]) ] ]
      ~form:[ ("1", {|{"id":"srv#action","bound":null}|}) ];
  ]

(* ----------------------------------------------------------------------- *)
(* Comparison and reporting                                                 *)
(* ----------------------------------------------------------------------- *)

(* Structural equality that also distinguishes -0. and treats NaN as equal to
   itself (Stdlib.(=) does neither for floats). *)
let rec json_equal (a : Yojson.Basic.t) (b : Yojson.Basic.t) =
  match (a, b) with
  | `Float x, `Float y -> Float.compare x y = 0 && Bool.equal (Float.sign_bit x) (Float.sign_bit y)
  | `List xs, `List ys -> List.equal json_equal xs ys
  | `Assoc xs, `Assoc ys -> List.equal (fun (ka, va) (kb, vb) -> String.equal ka kb && json_equal va vb) xs ys
  | _ -> a = b

(* Yojson.Basic.to_string with std:false prints NaN/Infinity literals. *)
let json_to_string json = Yojson.Basic.to_string ~std:false json
let args_to_string args = "[" ^ String.concat "; " (List.map json_to_string args) ^ "]"

let entries_to_string entries =
  "[" ^ String.concat "; " (List.map (fun (k, v) -> Printf.sprintf "%S -> %S" k v) entries) ^ "]"

let decode (case : case) = function
  | String_body body -> (
      match ReactServerDOM.decodeReply ?temporaryReferences:case.temporary_references body with
      | Ok args -> Ok (Array.to_list args, [])
      | Error _ as err -> err)
  | FormData_body entries -> (
      let formData = Js.FormData.make () in
      List.iter (fun (key, value) -> Js.FormData.append formData key (`String value)) entries;
      match ReactServerDOM.decodeFormDataReply ?temporaryReferences:case.temporary_references formData with
      | Ok (args, residual) ->
          let residual_entries =
            Js.FormData.entries residual
            |> List.map (fun (key, `String value) -> (key, value))
            |> List.sort (fun (a, _) (b, _) -> String.compare a b)
          in
          Ok (Array.to_list args, residual_entries)
      | Error _ as err -> err)

let print_divergence ~fixture ~expected_args ~expected_form = function
  | Error message ->
      Printf.printf "    fixture:  %s\n" (String.escaped fixture);
      Printf.printf "    expected: %s\n" (args_to_string expected_args);
      Printf.printf "    decoded:  Error %S\n" message
  | Ok (args, form_entries) ->
      Printf.printf "    fixture:       %s\n" (String.escaped fixture);
      Printf.printf "    expected args: %s\n" (args_to_string expected_args);
      Printf.printf "    decoded args:  %s\n" (args_to_string args);
      if expected_form <> form_entries then (
        Printf.printf "    expected form: %s\n" (entries_to_string expected_form);
        Printf.printf "    decoded form:  %s\n" (entries_to_string form_entries))

let make_test (case : case) =
  let run () =
    let body = parse_fixture case.name in
    let decoded = decode case body in
    let matches =
      match decoded with
      | Error _ -> false
      | Ok (args, form_entries) ->
          List.equal json_equal case.expected_args args
          && List.equal
               (fun (ka, va) (kb, vb) -> String.equal ka kb && String.equal va vb)
               case.expected_form_entries form_entries
    in
    let fixture = read_fixture case.name in
    match (case.xfail, matches) with
    | None, true -> ()
    | None, false ->
        print_divergence ~fixture ~expected_args:case.expected_args ~expected_form:case.expected_form_entries decoded;
        Alcotest.failf "case %s: srr decode diverges from the expected semantics of the React fixture" case.name
    | Some reason, false ->
        Printf.printf "  [xfail] %s: known divergence (%s)\n" case.name reason;
        print_divergence ~fixture ~expected_args:case.expected_args ~expected_form:case.expected_form_entries decoded
    | Some reason, true ->
        Alcotest.failf "case %s now MATCHES the expected semantics: divergence fixed! Remove ~xfail (%s)" case.name
          reason
  in
  (Printf.sprintf "reply_spec / %s" case.name, [ Alcotest.test_case "" `Quick run ])

(* Every fixture must have a case and every case a fixture, so the registry
   here cannot silently drift from ../reply/cases.mjs. *)
let registry_covers_fixtures () =
  let fixtures =
    Sys.readdir fixtures_dir |> Array.to_list
    |> List.filter_map (Filename.chop_suffix_opt ~suffix:".reply")
    |> List.sort String.compare
  in
  let cases = List.map (fun case -> case.name) all |> List.sort String.compare in
  Alcotest.(check (list string)) "reply fixtures and OCaml case registry must list the same names" fixtures cases

let () =
  let xfails = List.filter (fun case -> Option.is_some case.xfail) all in
  Printf.printf "reply_spec: %d cases, %d known divergences (xfail)\n" (List.length all) (List.length xfails);
  Alcotest.run "reply_spec_conformance"
    (("reply_spec / registry", [ Alcotest.test_case "covers fixtures" `Quick registry_covers_fixtures ])
    :: List.map make_test all)
