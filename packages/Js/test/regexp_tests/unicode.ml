(** TC39 Test262: RegExp Unicode flag tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/RegExp/unicode

    ECMA-262 Section: Unicode flag (u) - enables full Unicode support *)

open Helpers

(* ===================================================================
   Basic unicode flag functionality
   =================================================================== *)

let unicode_flag_accessor () =
  let re_without = Js.Re.fromString "abc" in
  let re_with = Js.Re.fromStringWithFlags "abc" ~flags:"u" in
  assert_bool (Js.Re.unicode re_without) false;
  assert_bool (Js.Re.unicode re_with) true

let flags_includes_u () =
  let re = Js.Re.fromStringWithFlags "abc" ~flags:"u" in
  let flags = Js.Re.flags re in
  assert_true "flags contains u" (String.contains flags 'u')

(* ===================================================================
   Unicode character matching
   =================================================================== *)

let basic_unicode_match () =
  let re = Js.Re.fromStringWithFlags "世界" ~flags:"u" in
  assert_bool (Js.Re.test ~str:"hello 世界" re) true

let emoji_match () =
  let re = Js.Re.fromStringWithFlags "🎉" ~flags:"u" in
  assert_bool (Js.Re.test ~str:"celebrate 🎉!" re) true

let unicode_no_match () =
  let re = Js.Re.fromStringWithFlags "世界" ~flags:"u" in
  assert_bool (Js.Re.test ~str:"hello world" re) false

(* ===================================================================
   Unicode with other flags
   =================================================================== *)

let unicode_with_global () =
  let re = Js.Re.fromStringWithFlags "\\w+" ~flags:"gu" in
  assert_bool (Js.Re.global re) true;
  assert_bool (Js.Re.unicode re) true

let unicode_with_ignorecase () =
  let re = Js.Re.fromStringWithFlags "abc" ~flags:"ui" in
  assert_bool (Js.Re.unicode re) true;
  assert_bool (Js.Re.ignoreCase re) true;
  assert_bool (Js.Re.test ~str:"ABC" re) true

let unicode_with_multiline () =
  let re = Js.Re.fromStringWithFlags "^hello" ~flags:"um" in
  assert_bool (Js.Re.unicode re) true;
  assert_bool (Js.Re.multiline re) true

(* ===================================================================
   Unicode property escapes (\p{} and \P{})
   Note: Support depends on the regex engine implementation
   =================================================================== *)

let unicode_letter_category () =
  (* This test checks if the regex with unicode flag compiles *)
  (* Support for \p{L} depends on implementation *)
  let re = Js.Re.fromStringWithFlags "\\p{L}+" ~flags:"u" in
  assert_bool (Js.Re.unicode re) true

(* ===================================================================
   Unicode astral plane characters
   =================================================================== *)

let astral_plane_chars () =
  (* Test with emoji (from astral plane) *)
  let re = Js.Re.fromStringWithFlags "." ~flags:"u" in
  (* In unicode mode, . should match full emoji codepoint *)
  assert_bool (Js.Re.test ~str:"🎉" re) true

let surrogate_pairs () =
  (* UTF-16 surrogate pairs should be treated as single codepoint in unicode mode *)
  let re = Js.Re.fromStringWithFlags "^..$" ~flags:"u" in
  (* Two emoji characters *)
  assert_bool (Js.Re.test ~str:"🎉🎊" re) true

(* ===================================================================
   Practical examples
   =================================================================== *)

let international_text () =
  let re = Js.Re.fromStringWithFlags "こんにちは" ~flags:"u" in
  assert_bool (Js.Re.test ~str:"こんにちは世界" re) true

let mixed_scripts () =
  let re = Js.Re.fromStringWithFlags "Hello 世界 🌍" ~flags:"u" in
  assert_bool (Js.Re.test ~str:"Hello 世界 🌍!" re) true

let tests =
  [
    (* Basic flag *)
    test "flag: accessor" unicode_flag_accessor;
    test "flag: in flags string" flags_includes_u;
    (* Character matching *)
    test "match: basic unicode" basic_unicode_match;
    test "match: emoji" emoji_match;
    test "match: no match" unicode_no_match;
    (* Combined flags *)
    test "combined: with global" unicode_with_global;
    test "combined: with ignorecase" unicode_with_ignorecase;
    test "combined: with multiline" unicode_with_multiline;
    (* Property escapes *)
    test "property: letter category" unicode_letter_category;
    (* Astral plane *)
    test "astral: basic" astral_plane_chars;
    test "astral: surrogate pairs" surrogate_pairs;
    (* Practical *)
    test "practical: international" international_text;
    test "practical: mixed scripts" mixed_scripts;
  ]
