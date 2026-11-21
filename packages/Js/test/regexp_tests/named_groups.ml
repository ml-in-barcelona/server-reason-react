open Helpers

let basic_named_group () =
  let re = Js.Re.fromString "(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})" in
  let result = Js.Re.exec ~str:"2024-03-15" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r ->
      let groups = Js.Re.groups r in
      assert_true "has year group" (List.exists (fun (k, _) -> k = "year") groups);
      assert_true "has month group" (List.exists (fun (k, _) -> k = "month") groups);
      assert_true "has day group" (List.exists (fun (k, _) -> k = "day") groups)

let single_named_group () =
  let re = Js.Re.fromString "hello (?<name>\\w+)" in
  let result = Js.Re.exec ~str:"hello world" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r ->
      let name_value = Js.Re.group "name" r in
      assert_string (Option.get name_value) "world"

let multiple_named_groups () =
  let re = Js.Re.fromString "(?<first>\\w+) (?<second>\\w+)" in
  let result = Js.Re.exec ~str:"hello world" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r ->
      assert_string (Option.get (Js.Re.group "first" r)) "hello";
      assert_string (Option.get (Js.Re.group "second" r)) "world"

let group_by_name () =
  let re = Js.Re.fromString "(?<greeting>hello|hi) (?<target>\\w+)" in
  let result = Js.Re.exec ~str:"hello world" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r ->
      let greeting = Js.Re.group "greeting" r in
      let target = Js.Re.group "target" r in
      assert_string (Option.get greeting) "hello";
      assert_string (Option.get target) "world"

let nonexistent_group () =
  let re = Js.Re.fromString "(?<name>\\w+)" in
  let result = Js.Re.exec ~str:"hello" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r ->
      let nonexistent = Js.Re.group "nonexistent" r in
      assert_true "nonexistent group is None" (Option.is_none nonexistent)

let all_groups_list () =
  let re = Js.Re.fromString "(?<a>\\d)(?<b>\\d)(?<c>\\d)" in
  let result = Js.Re.exec ~str:"123" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r ->
      let groups = Js.Re.groups r in
      assert_int (List.length groups) 3

let named_group_with_quantifiers () =
  let re = Js.Re.fromString "(?<digits>\\d+)" in
  let result = Js.Re.exec ~str:"abc123def" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r -> assert_string (Option.get (Js.Re.group "digits" r)) "123"

let named_group_with_alternation () =
  let re = Js.Re.fromString "(?<animal>cat|dog)" in
  let result = Js.Re.exec ~str:"I have a cat" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r -> assert_string (Option.get (Js.Re.group "animal" r)) "cat"

let no_named_groups () =
  let re = Js.Re.fromString "(\\d+)" in
  let result = Js.Re.exec ~str:"123" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r ->
      let groups = Js.Re.groups r in
      assert_int (List.length groups) 0

let mixed_named_and_unnamed () =
  let re = Js.Re.fromString "(\\d+)-(?<name>\\w+)" in
  let result = Js.Re.exec ~str:"123-abc" re in
  match result with
  | None -> Alcotest.fail "Expected match"
  | Some r -> assert_string (Option.get (Js.Re.group "name" r)) "abc"

let tests =
  [
    test "basic: date pattern" basic_named_group;
    test "basic: single group" single_named_group;
    test "basic: multiple groups" multiple_named_groups;
    test "access: by name" group_by_name;
    test "access: nonexistent" nonexistent_group;
    test "access: all groups list" all_groups_list;
    test "pattern: with quantifiers" named_group_with_quantifiers;
    test "pattern: with alternation" named_group_with_alternation;
    test "edge: no named groups" no_named_groups;
    test "edge: mixed named and unnamed" mixed_named_and_unnamed;
  ]
