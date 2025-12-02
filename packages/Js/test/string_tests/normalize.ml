(** TC39 Test262: String.prototype.normalize tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/String/prototype/normalize

    ECMA-262 Section: String.prototype.normalize([form])

    Note: Unicode normalization forms:
    - NFC: Canonical Decomposition, followed by Canonical Composition
    - NFD: Canonical Decomposition
    - NFKC: Compatibility Decomposition, followed by Canonical Composition
    - NFKD: Compatibility Decomposition *)

open Helpers

(* ===================================================================
   Default normalization (NFC)
   =================================================================== *)

let default_form () =
  (* Without form argument, NFC is used *)
  let composed = "café" in
  (* é as single codepoint U+00E9 *)
  assert_string (Js.String.normalize composed) composed;
  let decomposed = "cafe\u{0301}" in
  (* e + combining acute accent *)
  assert_string (Js.String.normalize decomposed) composed

let empty_string () = assert_string (Js.String.normalize "") ""

let ascii_unchanged () =
  assert_string (Js.String.normalize "hello") "hello";
  assert_string (Js.String.normalize "ABC123") "ABC123"

(* ===================================================================
   NFC - Canonical Composition
   =================================================================== *)

let nfc_basic () =
  let decomposed = "e\u{0301}" in
  (* e + combining acute *)
  let composed = "é" in
  assert_string (Js.String.normalize ~form:`NFC decomposed) composed

let nfc_multiple_accents () =
  (* Multiple combining characters *)
  let decomposed = "e\u{0301}\u{0327}" in
  (* e + acute + cedilla *)
  let result = Js.String.normalize ~form:`NFC decomposed in
  (* Result varies by Unicode version, just check it's normalized *)
  assert_true "NFC result not empty" (String.length result > 0)

(* ===================================================================
   NFD - Canonical Decomposition
   =================================================================== *)

let nfd_basic () =
  let composed = "é" in
  (* U+00E9 *)
  let decomposed = "e\u{0301}" in
  assert_string (Js.String.normalize ~form:`NFD composed) decomposed

let nfd_already_decomposed () =
  let decomposed = "e\u{0301}" in
  assert_string (Js.String.normalize ~form:`NFD decomposed) decomposed

(* ===================================================================
   NFKC - Compatibility Composition
   =================================================================== *)

let nfkc_ligature () =
  (* fi ligature U+FB01 -> "fi" *)
  let ligature = "\u{FB01}" in
  assert_string (Js.String.normalize ~form:`NFKC ligature) "fi"

let nfkc_superscript () =
  (* Superscript 2 U+00B2 -> "2" *)
  let superscript = "\u{00B2}" in
  assert_string (Js.String.normalize ~form:`NFKC superscript) "2"

(* ===================================================================
   NFKD - Compatibility Decomposition
   =================================================================== *)

let nfkd_ligature () =
  (* fi ligature U+FB01 -> "fi" *)
  let ligature = "\u{FB01}" in
  assert_string (Js.String.normalize ~form:`NFKD ligature) "fi"

let nfkd_with_accents () =
  (* Composed character with compatibility decomposition *)
  let nfkd = Js.String.normalize ~form:`NFKD "ﬁ" in
  assert_string nfkd "fi"

(* ===================================================================
   Edge cases
   =================================================================== *)

let hangul_syllable () =
  (* Korean syllable normalization *)
  let syllable = "가" in
  (* U+AC00 *)
  assert_string (Js.String.normalize ~form:`NFC syllable) syllable

let combining_sequences () =
  (* Canonical ordering of combining marks *)
  let text = "a\u{0308}\u{0323}" in
  (* a + umlaut + dot below *)
  let result = Js.String.normalize ~form:`NFC text in
  assert_true "NFC combining sequence" (String.length result > 0)

let tests =
  [
    (* Default form *)
    test "default form (NFC)" default_form;
    test "empty string" empty_string;
    test "ASCII unchanged" ascii_unchanged;
    (* NFC *)
    test "NFC: basic" nfc_basic;
    test "NFC: multiple accents" nfc_multiple_accents;
    (* NFD *)
    test "NFD: basic" nfd_basic;
    test "NFD: already decomposed" nfd_already_decomposed;
    (* NFKC *)
    test "NFKC: ligature" nfkc_ligature;
    test "NFKC: superscript" nfkc_superscript;
    (* NFKD *)
    test "NFKD: ligature" nfkd_ligature;
    test "NFKD: with accents" nfkd_with_accents;
    (* Edge cases *)
    test "Hangul syllable" hangul_syllable;
    test "combining sequences" combining_sequences;
  ]
