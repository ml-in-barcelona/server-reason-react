open Helpers

let default_form () =
  let composed = "café" in
  assert_string (Js.String.normalize composed) composed;
  let decomposed = "cafe\u{0301}" in
  assert_string (Js.String.normalize decomposed) composed

let empty_string () = assert_string (Js.String.normalize "") ""

let ascii_unchanged () =
  assert_string (Js.String.normalize "hello") "hello";
  assert_string (Js.String.normalize "ABC123") "ABC123"

let nfc_basic () =
  let decomposed = "e\u{0301}" in
  let composed = "é" in
  assert_string (Js.String.normalize ~form:`NFC decomposed) composed

let nfc_multiple_accents () =
  let decomposed = "e\u{0301}\u{0327}" in
  let result = Js.String.normalize ~form:`NFC decomposed in
  assert_true "NFC result not empty" (String.length result > 0)

let nfd_basic () =
  let composed = "é" in
  let decomposed = "e\u{0301}" in
  assert_string (Js.String.normalize ~form:`NFD composed) decomposed

let nfd_already_decomposed () =
  let decomposed = "e\u{0301}" in
  assert_string (Js.String.normalize ~form:`NFD decomposed) decomposed

let nfkc_ligature () =
  let ligature = "\u{FB01}" in
  assert_string (Js.String.normalize ~form:`NFKC ligature) "fi"

let nfkc_superscript () =
  let superscript = "\u{00B2}" in
  assert_string (Js.String.normalize ~form:`NFKC superscript) "2"

let nfkd_ligature () =
  let ligature = "\u{FB01}" in
  assert_string (Js.String.normalize ~form:`NFKD ligature) "fi"

let nfkd_with_accents () =
  let nfkd = Js.String.normalize ~form:`NFKD "ﬁ" in
  assert_string nfkd "fi"

let hangul_syllable () =
  let syllable = "가" in
  assert_string (Js.String.normalize ~form:`NFC syllable) syllable

let combining_sequences () =
  let text = "a\u{0308}\u{0323}" in
  let result = Js.String.normalize ~form:`NFC text in
  assert_true "NFC combining sequence" (String.length result > 0)

let tests =
  [
    test "default form (NFC)" default_form;
    test "empty string" empty_string;
    test "ASCII unchanged" ascii_unchanged;
    test "NFC: basic" nfc_basic;
    test "NFC: multiple accents" nfc_multiple_accents;
    test "NFD: basic" nfd_basic;
    test "NFD: already decomposed" nfd_already_decomposed;
    test "NFKC: ligature" nfkc_ligature;
    test "NFKC: superscript" nfkc_superscript;
    test "NFKD: ligature" nfkd_ligature;
    test "NFKD: with accents" nfkd_with_accents;
    test "Hangul syllable" hangul_syllable;
    test "combining sequences" combining_sequences;
  ]
