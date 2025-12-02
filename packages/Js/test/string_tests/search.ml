(** TC39 Test262: String.prototype.search tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/String/prototype/search

    ECMA-262 Section: String.prototype.search(regexp) *)

open Helpers

(* ===================================================================
   Basic search functionality
   =================================================================== *)

let basic_match () =
  let re = Js.Re.fromString "world" in
  assert_int (Js.String.search ~regexp:re "hello world") 6

let no_match () =
  let re = Js.Re.fromString "xyz" in
  assert_int (Js.String.search ~regexp:re "hello world") (-1)

let match_at_start () =
  let re = Js.Re.fromString "hello" in
  assert_int (Js.String.search ~regexp:re "hello world") 0

let match_at_end () =
  let re = Js.Re.fromString "world" in
  assert_int (Js.String.search ~regexp:re "hello world") 6

let empty_string () =
  let re = Js.Re.fromString "a" in
  assert_int (Js.String.search ~regexp:re "") (-1)

let empty_pattern () =
  let re = Js.Re.fromString "" in
  assert_int (Js.String.search ~regexp:re "hello") 0

(* ===================================================================
   Case sensitivity
   =================================================================== *)

let case_sensitive () =
  let re = Js.Re.fromString "WORLD" in
  assert_int (Js.String.search ~regexp:re "hello world") (-1)

let case_insensitive () =
  let re = Js.Re.fromStringWithFlags "world" ~flags:"i" in
  assert_int (Js.String.search ~regexp:re "hello WORLD") 6

(* ===================================================================
   Special patterns
   =================================================================== *)

let digit_class () =
  let re = Js.Re.fromString "\\d+" in
  assert_int (Js.String.search ~regexp:re "abc123def") 3

let word_boundary () =
  let re = Js.Re.fromString "\\bworld\\b" in
  assert_int (Js.String.search ~regexp:re "hello world here") 6

let any_character () =
  let re = Js.Re.fromString "w.rld" in
  assert_int (Js.String.search ~regexp:re "hello world") 6

let alternation () =
  let re = Js.Re.fromString "cat|dog" in
  assert_int (Js.String.search ~regexp:re "I have a dog") 9;
  assert_int (Js.String.search ~regexp:re "I have a cat") 9

let optional_character () =
  let re = Js.Re.fromString "colou?r" in
  assert_int (Js.String.search ~regexp:re "colour") 0;
  assert_int (Js.String.search ~regexp:re "color") 0

(* ===================================================================
   Multiple occurrences (search finds first)
   =================================================================== *)

let multiple_matches () =
  let re = Js.Re.fromString "a" in
  assert_int (Js.String.search ~regexp:re "banana") 1

let global_flag_ignored () =
  (* search should return first match regardless of global flag *)
  let re = Js.Re.fromStringWithFlags "a" ~flags:"g" in
  assert_int (Js.String.search ~regexp:re "banana") 1

(* ===================================================================
   Unicode
   =================================================================== *)

let unicode_characters () =
  let re = Js.Re.fromString "世界" in
  assert_int (Js.String.search ~regexp:re "hello 世界") 6

let emoji () =
  let re = Js.Re.fromString "🎉" in
  let result = Js.String.search ~regexp:re "celebrate 🎉!" in
  assert_true "emoji found" (result >= 0)

(* ===================================================================
   Edge cases
   =================================================================== *)

let special_regex_chars () =
  let re = Js.Re.fromString "\\." in
  assert_int (Js.String.search ~regexp:re "hello.world") 5

let newline () =
  let re = Js.Re.fromString "world" in
  assert_int (Js.String.search ~regexp:re "hello\nworld") 6

let tests =
  [
    (* Basic *)
    test "basic: match" basic_match;
    test "basic: no match" no_match;
    test "basic: match at start" match_at_start;
    test "basic: match at end" match_at_end;
    test "basic: empty string" empty_string;
    test "basic: empty pattern" empty_pattern;
    (* Case sensitivity *)
    test "case: sensitive" case_sensitive;
    test "case: insensitive" case_insensitive;
    (* Special patterns *)
    test "pattern: digit class" digit_class;
    test "pattern: word boundary" word_boundary;
    test "pattern: any character" any_character;
    test "pattern: alternation" alternation;
    test "pattern: optional" optional_character;
    (* Multiple matches *)
    test "multiple: finds first" multiple_matches;
    test "multiple: global flag ignored" global_flag_ignored;
    (* Unicode *)
    test "unicode: characters" unicode_characters;
    test "unicode: emoji" emoji;
    (* Edge cases *)
    test "edge: special regex chars" special_regex_chars;
    test "edge: newline" newline;
  ]

