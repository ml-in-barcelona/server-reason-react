open Helpers

let dot_without_flag () =
  let re = Js.Re.fromString "a.b" in
  assert_bool (Js.Re.test ~str:"a\nb" re) false

let dot_with_flag () =
  let re = Js.Re.fromStringWithFlags "a.b" ~flags:"s" in
  assert_bool (Js.Re.test ~str:"a\nb" re) true

let dotall_flag_accessor () =
  let re_without = Js.Re.fromString "abc" in
  let re_with = Js.Re.fromStringWithFlags "abc" ~flags:"s" in
  assert_bool (Js.Re.dotAll re_without) false;
  assert_bool (Js.Re.dotAll re_with) true

let matches_line_feed () =
  let re = Js.Re.fromStringWithFlags "a.b" ~flags:"s" in
  assert_bool (Js.Re.test ~str:"a\nb" re) true

let matches_carriage_return () =
  let re = Js.Re.fromStringWithFlags "a.b" ~flags:"s" in
  assert_bool (Js.Re.test ~str:"a\rb" re) true

let matches_crlf () =
  let re = Js.Re.fromStringWithFlags "a..b" ~flags:"s" in
  assert_bool (Js.Re.test ~str:"a\r\nb" re) true

let with_global_flag () =
  let re = Js.Re.fromStringWithFlags "a.b" ~flags:"gs" in
  assert_bool (Js.Re.global re) true;
  assert_bool (Js.Re.dotAll re) true;
  assert_bool (Js.Re.test ~str:"a\nb" re) true

let with_ignorecase_flag () =
  let re = Js.Re.fromStringWithFlags "a.b" ~flags:"si" in
  assert_bool (Js.Re.ignoreCase re) true;
  assert_bool (Js.Re.dotAll re) true;
  assert_bool (Js.Re.test ~str:"A\nB" re) true

let with_multiline_flag () =
  let re = Js.Re.fromStringWithFlags "a.b" ~flags:"sm" in
  assert_bool (Js.Re.multiline re) true;
  assert_bool (Js.Re.dotAll re) true;
  assert_bool (Js.Re.test ~str:"a\nb" re) true

let flags_includes_s () =
  let re = Js.Re.fromStringWithFlags "abc" ~flags:"s" in
  let flags = Js.Re.flags re in
  assert_true "flags contains s" (String.contains flags 's')

let flags_order () =
  let re = Js.Re.fromStringWithFlags "abc" ~flags:"smig" in
  let flags = Js.Re.flags re in
  assert_true "contains g" (String.contains flags 'g');
  assert_true "contains i" (String.contains flags 'i');
  assert_true "contains m" (String.contains flags 'm');
  assert_true "contains s" (String.contains flags 's')

let multiline_content () =
  let re = Js.Re.fromStringWithFlags "start.*end" ~flags:"s" in
  let multiline_text = "start\nmiddle\nend" in
  assert_bool (Js.Re.test ~str:multiline_text re) true

let no_dotall_multiline_fail () =
  let re = Js.Re.fromString "start.*end" in
  let multiline_text = "start\nmiddle\nend" in
  assert_bool (Js.Re.test ~str:multiline_text re) false

let tests =
  [
    test "basic: dot without flag" dot_without_flag;
    test "basic: dot with flag" dot_with_flag;
    test "basic: flag accessor" dotall_flag_accessor;
    test "line: matches LF" matches_line_feed;
    test "line: matches CR" matches_carriage_return;
    test "line: matches CRLF" matches_crlf;
    test "flags: with global" with_global_flag;
    test "flags: with ignorecase" with_ignorecase_flag;
    test "flags: with multiline" with_multiline_flag;
    test "accessor: includes s" flags_includes_s;
    test "accessor: order" flags_order;
    test "practical: multiline content" multiline_content;
    test "practical: without flag fails" no_dotall_multiline_fail;
  ]
