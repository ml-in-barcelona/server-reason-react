let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left
let assert_option x left right = Alcotest.check (Alcotest.option x) "should be equal" right left
let assert_array ty left right = Alcotest.check (Alcotest.array ty) "should be equal" right left
let assert_string_array = assert_array Alcotest.string
let assert_string_option_array = assert_array (Alcotest.option Alcotest.string)
let assert_array_int = assert_array Alcotest.int

let assert_dict_entries type_ left right =
  Alcotest.check (Alcotest.array (Alcotest.pair Alcotest.string type_)) "should be equal" right left

let assert_int_dict_entries = assert_dict_entries Alcotest.int
let assert_string_dict_entries = assert_dict_entries Alcotest.string
let assert_option_int = assert_option Alcotest.int
(* let assert_option_string = assert_option Alcotest.string *)

let assert_int left right = Alcotest.check Alcotest.int "should be equal" right left
let assert_float left right = Alcotest.check (Alcotest.float 2.) "should be equal" right left
let assert_float_exact left right = Alcotest.check (Alcotest.float 0.) "should be equal" right left
let assert_bool left right = Alcotest.check Alcotest.bool "should be equal" right left

let assert_raises fn exn =
  match fn () with
  | exception exn -> assert_string (Printexc.to_string exn) (Printexc.to_string exn)
  | _ -> Alcotest.failf "Expected exception %s" (Printexc.to_string exn)

let test title fn = Alcotest_lwt.test_case_sync title `Quick fn
let test_async title fn = Alcotest_lwt.test_case title `Quick fn

let re_tests =
  [
    test "captures" (fun () ->
        let abc_regex = Js.Re.fromString "abc" in
        let result = Js.Re.exec ~str:"abcdefabcdef" abc_regex |> Option.get in
        let matches = Js.Re.captures result |> Array.map Option.get in
        assert_string_array matches [| "abc" |]);
    test "exec" (fun () ->
        let regex = Js.Re.fromString ".ats" in
        let input = "cats and bats" in
        let regex_and_capture = Js.Re.exec ~str:input regex |> Option.get |> Js.Re.captures |> Array.map Option.get in
        assert_string_array regex_and_capture [| "cats" |];
        assert_string_array regex_and_capture [| "cats" |];
        assert_string_array regex_and_capture [| "cats" |]);
    test "exec with global" (fun () ->
        let regex = Js.Re.fromStringWithFlags ~flags:"g" ".ats" in
        let input = "cats and bats and mats" in
        assert_bool (Js.Re.global regex) true;
        assert_string_array
          (Js.Re.exec ~str:input regex |> Option.get |> Js.Re.captures |> Array.map Option.get)
          [| "cats" |];
        assert_string_array
          (Js.Re.exec ~str:input regex |> Option.get |> Js.Re.captures |> Array.map Option.get)
          [| "bats" |];
        assert_string_array
          (Js.Re.exec ~str:input regex |> Option.get |> Js.Re.captures |> Array.map Option.get)
          [| "mats" |]);
    test "modifier: end ($)" (fun () ->
        let regex = Js.Re.fromString "cat$" in
        assert_bool (Js.Re.test ~str:"The cat and mouse" regex) false;
        assert_bool (Js.Re.test ~str:"The mouse and cat" regex) true);
    test "modifier: more than one (+)" (fun () ->
        let regex = Js.Re.fromStringWithFlags ~flags:"i" "boo+(hoo+)+" in
        assert_bool (Js.Re.test ~str:"Boohoooohoohooo" regex) true);
    test "global (g) and caseless (i)" (fun () ->
        let regex = Js.Re.fromStringWithFlags ~flags:"gi" "Hello" in
        let result = Js.Re.exec ~str:"Hello gello! hello" regex |> Option.get in
        let matches = Js.Re.captures result |> Array.map Option.get in
        assert_string_array matches [| "Hello" |];
        let result = Js.Re.exec ~str:"Hello gello! hello" regex |> Option.get in
        let matches = Js.Re.captures result |> Array.map Option.get in
        assert_string_array matches [| "hello" |]);
    test "modifier: or ([])" (fun () ->
        let regex = Js.Re.fromString "(\\w+)\\s(\\w+)" in
        assert_bool (Js.Re.test ~str:"Jane Smith" regex) true;
        assert_bool (Js.Re.test ~str:"Wololo" regex) false);
    test "backreferencing" (fun () ->
        let regex = Js.Re.fromString "[bt]ear" in
        assert_bool (Js.Re.test ~str:"bear" regex) true;
        assert_bool (Js.Re.test ~str:"tear" regex) true;
        assert_bool (Js.Re.test ~str:"fear" regex) false);
    test "http|s example" (fun () ->
        let regex = Js.Re.fromString "^[https?]+:\\/\\/((w{3}\\.)?[\\w+]+)\\.[\\w+]+$" in
        assert_bool (Js.Re.test ~str:"https://www.example.com" regex) true;
        assert_bool (Js.Re.test ~str:"http://example.com" regex) true;
        assert_bool (Js.Re.test ~str:"https://example" regex) false);
    test "index" (fun () ->
        let regex = Js.Re.fromString "zbar" in
        match Js.Re.exec ~str:"foobarbazbar" regex with
        | Some res -> assert_int (Js.Re.index res) 8
        | None -> Alcotest.fail "should have matched");
    test "lastIndex" (fun () ->
        let regex = Js.Re.fromStringWithFlags ~flags:"g" "y" in
        Js.Re.setLastIndex regex 3;
        match Js.Re.exec ~str:"xyzzy" regex with
        | Some res ->
            assert_int (Js.Re.index res) 4;
            assert_int (Js.Re.lastIndex regex) 5
        | None -> Alcotest.fail "should have matched");
    test "input" (fun () ->
        let regex = Js.Re.fromString "zbar" in
        match Js.Re.exec ~str:"foobarbazbar" regex with
        | Some res -> assert_string (Js.Re.input res) "foobarbazbar"
        | None -> Alcotest.fail "should have matched");
  ]

let string_tests =
  [
    test "make" (fun () ->
        (* assert_string (make 3.5) "3.5"; *)
        (* assert_string (make [| 1; 2; 3 |]) "1,2,3"); *)
        ());
    test "length" (fun () ->
        assert_int (Js.String.length "abcd") 4;
        assert_int (Js.String.length {js|é|js}) 1;
        assert_int (Js.String.length {js|😀|js}) 2;
        assert_int (Js.String.length {js|Rẽasöń|js}) 6);
    test "get" (fun () ->
        assert_string (Js.String.get "Reason" 0) "R";
        assert_string (Js.String.get "Reason" 4) "o";
        assert_string (Js.String.get {js|Rẽasöń|js} 5) {js|ń|js};
        (* JavaScript returns undefined out of bounds; the closest [t] value is "" *)
        assert_string (Js.String.get "Reason" 12) "");
    test "fromCharCode" (fun () ->
        assert_string (Js.String.fromCharCode 65) "A";
        assert_string (Js.String.fromCharCode 0x3c8) {js|ψ|js};
        assert_string (Js.String.fromCharCode 0xd55c) {js|한|js};
        assert_string (Js.String.fromCharCode (-64568)) {js|ψ|js});
    test "fromCharCodeMany" (fun () ->
        assert_string (Js.String.fromCharCodeMany [| 0xd55c; 0xae00; 33 |]) {js|한글!|js};
        (* surrogate halves pair up into a single code point *)
        assert_string (Js.String.fromCharCodeMany [| 0xd83d; 0xde00 |]) {js|😀|js});
    test "fromCodePoint" (fun () ->
        assert_string (Js.String.fromCodePoint 65) "A";
        assert_string (Js.String.fromCodePoint 0x3c8) {js|ψ|js};
        assert_string (Js.String.fromCodePoint 0xd55c) {js|한|js};
        assert_string (Js.String.fromCodePoint 0x1f63a) {js|😺|js};
        assert_string (Js.String.fromCodePoint 0x1f600) {js|😀|js});
    test "fromCodePointMany" (fun () ->
        assert_string (Js.String.fromCodePointMany [| 0xd55c; 0xae00; 0x1f63a |]) {js|한글😺|js});
    test "charAt" (fun () ->
        assert_string (Js.String.charAt "Reason" ~index:0) "R";
        assert_string (Js.String.charAt "Reason" ~index:12) "";
        assert_string (Js.String.charAt {js|Rẽasöń|js} ~index:5) {js|ń|js});
    test "charCodeAt" (fun () ->
        assert_float (Js.String.charCodeAt {js|😺|js} ~index:0) (float_of_int 0xd83d);
        assert_float (Js.String.charCodeAt {js|😺|js} ~index:1) (float_of_int 0xde3a);
        assert_float (Js.String.charCodeAt {js|é|js} ~index:0) 233.;
        assert_bool (Float.is_nan (Js.String.charCodeAt "abc" ~index:5)) true;
        assert_float (Js.String.charCodeAt "lola" ~index:1) 111.;
        assert_float (Js.String.charCodeAt "lola" ~index:0) 108.);
    test "codePointAt" (fun () ->
        assert_option_int (Js.String.codePointAt "lola" ~index:1) (Some 111);
        assert_option_int (Js.String.codePointAt {js|¿😺?|js} ~index:1) (Some 0x1f63a);
        assert_option_int (Js.String.codePointAt {js|😀|js} ~index:0) (Some 0x1f600);
        (* index on the low surrogate returns the trailing surrogate value *)
        assert_option_int (Js.String.codePointAt {js|😀|js} ~index:1) (Some 0xde00);
        assert_option_int (Js.String.codePointAt "abc" ~index:5) None);
    test "concat" (fun () -> assert_string (Js.String.concat "cow" ~other:"bell") "cowbell");
    test "concatMany" (fun () ->
        assert_string (Js.String.concatMany "1st" ~strings:[| "2nd"; "3rd"; "4th" |]) "1st2nd3rd4th");
    test "endsWith" (fun () ->
        assert_bool (Js.String.endsWith "ReScript" ~suffix:"Script") true;
        assert_bool (Js.String.endsWith "ReShoes" ~suffix:"Script") false;
        assert_bool (Js.String.endsWith "abcd" ~suffix:"cd" ~len:4) true;
        assert_bool (Js.String.endsWith "abcde" ~suffix:"cd" ~len:3) false;
        assert_bool (Js.String.endsWith "abcde" ~suffix:"cde" ~len:99) true;
        assert_bool (Js.String.endsWith {js|😀b|js} ~suffix:{js|😀|js} ~len:2) true;
        assert_bool (Js.String.endsWith "example.dat" ~suffix:"ple" ~len:7) true);
    test "includes" (fun () ->
        assert_bool (Js.String.includes "programmer" ~search:"gram") true;
        assert_bool (Js.String.includes "programmer" ~search:"er") true;
        assert_bool (Js.String.includes "programmer" ~search:"pro") true;
        assert_bool (Js.String.includes "programmer" ~search:"xyz") false;
        assert_bool (Js.String.includes "programmer" ~search:"gram" ~start:1) true;
        assert_bool (Js.String.includes "programmer" ~search:"gram" ~start:4) false;
        assert_bool (Js.String.includes {js|대한민국|js} ~search:{js|한|js} ~start:1) true;
        assert_bool (Js.String.includes {js|😀b|js} ~search:"b" ~start:2) true);
    test "indexOf" (fun () ->
        assert_int (Js.String.indexOf "bookseller" ~search:"ok") 2;
        assert_int (Js.String.indexOf "bookseller" ~search:"sell") 4;
        assert_int (Js.String.indexOf "beekeeper" ~search:"ee") 1;
        assert_int (Js.String.indexOf "bookseller" ~search:"xyz") (-1);
        assert_int (Js.String.indexOf "bookseller" ~search:"ok" ~start:1) 2;
        assert_int (Js.String.indexOf "bookseller" ~search:"sell" ~start:2) 4;
        assert_int (Js.String.indexOf "bookseller" ~search:"sell" ~start:5) (-1);
        assert_int (Js.String.indexOf "bookseller" ~search:"xyz") (-1);
        (* negative start clamps to 0; indices are UTF-16 code units *)
        assert_int (Js.String.indexOf "bookseller" ~search:"ok" ~start:(-3)) 2;
        assert_int (Js.String.indexOf {js|éb|js} ~search:"b") 1;
        assert_int (Js.String.indexOf {js|a😀b|js} ~search:"b") 3);
    test "lastIndexOf" (fun () ->
        assert_int (Js.String.lastIndexOf "bookseller" ~search:"ok") 2;
        assert_int (Js.String.lastIndexOf "beekeeper" ~search:"ee") 4;
        assert_int (Js.String.lastIndexOf "abcdefg" ~search:"xyz") (-1);
        assert_int (Js.String.lastIndexOf "bookseller" ~search:"ok" ~start:6) 2;
        assert_int (Js.String.lastIndexOf "beekeeper" ~search:"ee" ~start:8) 4;
        assert_int (Js.String.lastIndexOf "beekeeper" ~search:"ee" ~start:3) 1;
        assert_int (Js.String.lastIndexOf "abcdefg" ~search:"xyz" ~start:4) (-1);
        assert_int (Js.String.lastIndexOf {js|a😀b😀b|js} ~search:"b") 6);
    (* test "localeCompare" (fun () ->
         localeCompare "ant" "zebra" > 0.0
           localeCompare "zebra" "ant" < 0.0
           localeCompare "cat" "cat" = 0.0
           localeCompare "cat" "CAT" > 0.0
        ());
    *)
    test "match" (fun () ->
        let unsafe_match s r = Js.String.match_ ~regexp:r s |> Stdlib.Option.get in
        assert_string_option_array (unsafe_match "The better bats" (Js.Re.fromString "b[aeiou]t")) [| Some "bet" |]);
    test "match 0" (fun () ->
        let unsafe_match r s = Js.String.match_ ~regexp:r s |> Stdlib.Option.value ~default:[||] in
        assert_string_option_array (unsafe_match (Js.Re.fromString "b[aeiou]t") "The better bats") [| Some "bet" |];
        assert_string_option_array
          (unsafe_match (Js.Re.fromStringWithFlags "b[aeiou]t" ~flags:"g") "The better bats")
          [| Some "bet"; Some "bat" |];
        assert_string_option_array
          (unsafe_match [%re "/(\\d+)-(\\d+)-(\\d+)/"] "Today is 2018-04-05.")
          [| Some "2018-04-05"; Some "2018"; Some "04"; Some "05" |];
        assert_string_option_array (unsafe_match [%re "/b[aeiou]g/"] "The large container.") [||]);
    test "match global returns all full matches without groups" (fun () ->
        let unsafe_match r s = Js.String.match_ ~regexp:r s |> Stdlib.Option.value ~default:[||] in
        assert_string_option_array
          (unsafe_match [%re "/(\\d+)-(\\d+)-(\\d+)/g"] "2018-04-05 2019-05-06")
          [| Some "2018-04-05"; Some "2019-05-06" |];
        (* empty matches are all found, like "abc".match(/x*/g) *)
        assert_string_option_array (unsafe_match [%re "/x*/g"] "abc") [| Some ""; Some ""; Some ""; Some "" |];
        (* no match with the global flag returns None (null in JavaScript) *)
        assert_bool (Js.String.match_ ~regexp:[%re "/b[aeiou]g/g"] "The large container." = None) true);
    test "repeat" (fun () ->
        assert_string (Js.String.repeat "ha" ~count:3) "hahaha";
        assert_string (Js.String.repeat "empty" ~count:0) "";
        (* JavaScript raises RangeError on a negative count *)
        match Js.String.repeat "ha" ~count:(-1) with
        | exception Invalid_argument _ -> ()
        | (_ : string) -> Alcotest.fail "repeat with a negative count should raise Invalid_argument");
    test "replace" (fun () ->
        assert_string (Js.String.replace ~search:"old" ~replacement:"new" "old string") "new string";
        assert_string (Js.String.replace ~search:"the" ~replacement:"this" "the cat and the dog") "this cat and the dog";
        (* only the first occurrence is replaced; $&, $$, $`, $' are expanded *)
        assert_string (Js.String.replace ~search:"a" ~replacement:"[$&]" "banana") "b[a]nana";
        assert_string (Js.String.replace ~search:"price" ~replacement:"$$100" "price") "$100";
        assert_string (Js.String.replace ~search:"cd" ~replacement:"[$`|$']" "abcdef") "ab[ab|ef]ef";
        (* backslash sequences are literal, not backreferences *)
        assert_string (Js.String.replace ~search:"b" ~replacement:"\\1" "abc") "a\\1c");
    test "replaceByRe" (fun () ->
        assert_string (Js.String.replaceByRe "david" ~regexp:[%re "/d/"] ~replacement:"x") "xavid");
    test "replaceByRe with references ($n)" (fun () ->
        assert_string (Js.String.replaceByRe "david" ~regexp:[%re "/d(.*?)d/g"] ~replacement:"$1") "avi");
    test "replaceByRe with $1 capturing group" (fun () ->
        assert_string
          (Js.String.replaceByRe "<em>hello</em> world" ~regexp:[%re "/<em>(.*?)<\\/em>/gi"] ~replacement:"$1")
          "hello world");
    test "replaceByRe with multiple capturing groups" (fun () ->
        assert_string
          (Js.String.replaceByRe "John Smith" ~regexp:[%re "/(\\w+)\\s(\\w+)/"] ~replacement:"$2, $1")
          "Smith, John");
    test "replaceByRe with $&" (fun () ->
        assert_string (Js.String.replaceByRe "hello" ~regexp:[%re "/l/g"] ~replacement:"[$&]") "he[l][l]o");
    test "replaceByRe with $$" (fun () ->
        assert_string (Js.String.replaceByRe "price" ~regexp:[%re "/price/"] ~replacement:"$$100") "$100");
    test "replaceByRe with global" (fun () ->
        assert_string
          (Js.String.replaceByRe "vowels be gone" ~regexp:[%re "/[aeiou]/g"] ~replacement:"x")
          "vxwxls bx gxnx");
    test "replaceByRe global empty matches" (fun () ->
        (* "abc".replace(/x*/g, "-") = "-a-b-c-" *)
        assert_string (Js.String.replaceByRe "abc" ~regexp:[%re "/x*/g"] ~replacement:"-") "-a-b-c-");
    test "replaceByRe global on multibyte input" (fun () ->
        (* "éb".replace(/b/g, "X") = "éX": UTF-16 index 1 is byte offset 2 *)
        assert_string (Js.String.replaceByRe {js|éb|js} ~regexp:[%re "/b/g"] ~replacement:"X") {js|éX|js});
    test "replaceByRe unicode flag advances over full code points" (fun () ->
        (* "😀a".replace(/x*/gu, "-") = "-😀-a-" *)
        assert_string (Js.String.replaceByRe {js|😀a|js} ~regexp:[%re "/x*/gu"] ~replacement:"-") {js|-😀-a-|js});
    test "replaceByRe leaves lastIndex at 0 after a global replace" (fun () ->
        let regexp = [%re "/b/g"] in
        Js.Re.setLastIndex regexp 3;
        assert_string (Js.String.replaceByRe "abcb" ~regexp ~replacement:"X") "aXcX";
        assert_int (Js.Re.lastIndex regexp) 0);
    test "replaceByRe with named groups referenced by number" (fun () ->
        assert_string
          (Js.String.replaceByRe "John Smith" ~regexp:[%re "/(?<first>\\w+) (?<last>\\w+)/"] ~replacement:"$2 $1")
          "Smith John");
    test "replaceByRe with a non-participating group" (fun () ->
        (* "ac".replace(/a(b)?c/, "[$1]") = "[]" *)
        assert_string (Js.String.replaceByRe "ac" ~regexp:[%re "/a(b)?c/"] ~replacement:"[$1]") "[]");
    test "replaceByRe with an invalid group reference" (fun () ->
        (* "abc".replace(/b/, "$9") = "a$9c" *)
        assert_string (Js.String.replaceByRe "abc" ~regexp:[%re "/b/"] ~replacement:"$9") "a$9c");
    test "replaceByRe with $` on the original string" (fun () ->
        assert_string (Js.String.replaceByRe "abcdef" ~regexp:[%re "/cd/"] ~replacement:"<$`>") "ab<ab>ef");
    test "replaceByRe writes multibyte prefix and suffix references" (fun () ->
        assert_string
          (Js.String.replaceByRe {js|ébéb|js} ~regexp:[%re "/b/g"] ~replacement:"[$`|$'|$&]")
          {js|é[é|éb|b]é[ébé||b]|js});
    test "replaceByRe handles a match that splits a surrogate pair" (fun () ->
        assert_string (Js.String.replaceByRe {js|😀|js} ~regexp:(Js.Re.fromString "\\uD83D") ~replacement:"X") {js|X�|js});
    test "replaceByRe sticky non-global starts at lastIndex" (fun () ->
        let regexp = [%re "/b/y"] in
        Js.Re.setLastIndex regexp 1;
        assert_string (Js.String.replaceByRe "ab" ~regexp ~replacement:"X") "aX";
        assert_int (Js.Re.lastIndex regexp) 2);
    test "splitByRe with sticky flag scans like JavaScript" (fun () ->
        (* "a-b-c".split(/-/y) = ["a", "b", "c"] *)
        assert_string_option_array (Js.String.splitByRe ~regexp:[%re "/-/y"] "a-b-c") [| Some "a"; Some "b"; Some "c" |]);
    test "splitByRe does not touch the caller's lastIndex" (fun () ->
        let regexp = [%re "/-/g"] in
        Js.Re.setLastIndex regexp 4;
        ignore (Js.String.splitByRe ~regexp "a-b-c");
        assert_int (Js.Re.lastIndex regexp) 4);
    (* unsafeReplaceBy examples come from the Melange documentation; expected
       strings are node's output for the equivalent String.prototype.replace
       calls (the doc example for unsafeReplaceBy0 has a typo: node returns
       "bEAUtIfUl vOwEls", with the "i" uppercased too). *)
    test "unsafeReplaceBy0" (fun () ->
        let str = "beautiful vowels" in
        let matchFn matchPart _offset _wholeString = Js.String.toUpperCase matchPart in
        let replaced = Js.String.unsafeReplaceBy0 ~regexp:[%re "/[aeiou]/g"] ~f:matchFn str in
        assert_string replaced "bEAUtIfUl vOwEls");
    test "unsafeReplaceBy0 callback cannot change global match collection" (fun () ->
        let regexp = [%re "/./g"] in
        let offsets = ref [] in
        let replaced =
          Js.String.unsafeReplaceBy0 ~regexp
            ~f:(fun matched offset _ ->
              offsets := offset :: !offsets;
              Js.Re.setLastIndex regexp 99;
              Js.String.toUpperCase matched)
            "ab"
        in
        assert_string replaced "AB";
        Alcotest.check (Alcotest.list Alcotest.int) "callback offsets" [ 0; 1 ] (Stdlib.List.rev !offsets);
        assert_int (Js.Re.lastIndex regexp) 99);
    test "unsafeReplaceBy1" (fun () ->
        let str = "increment 23" in
        let matchFn _matchPart p1 _offset wholeString = wholeString ^ " is " ^ string_of_int (int_of_string p1 + 1) in
        let replaced = Js.String.unsafeReplaceBy1 ~regexp:[%re "/increment (\\d+)/g"] ~f:matchFn str in
        assert_string replaced "increment 23 is 24");
    test "unsafeReplaceBy2" (fun () ->
        let str = "7 times 6" in
        let matchFn _matchPart p1 p2 _offset _wholeString = string_of_int (int_of_string p1 * int_of_string p2) in
        let replaced = Js.String.unsafeReplaceBy2 ~regexp:[%re "/(\\d+) times (\\d+)/"] ~f:matchFn str in
        assert_string replaced "42");
    test "unsafeReplaceBy0 offset is a UTF-16 index" (fun () ->
        (* "a😀b".replace(/b/, (m, offset) => String(offset)) = "a😀3" (node) *)
        let replaced =
          Js.String.unsafeReplaceBy0 ~regexp:[%re "/b/"]
            ~f:(fun _ offset _ -> string_of_int offset)
            "a\xF0\x9F\x98\x80b"
        in
        assert_string replaced "a\xF0\x9F\x98\x803");
    test "search" (fun () ->
        assert_int (Js.String.search ~regexp:[%re "/\\d+/"] "testing 1 2 3") 8;
        assert_int (Js.String.search ~regexp:[%re "/\\d+/"] "no numbers") (-1));
    test "slice" (fun () ->
        assert_string (Js.String.slice ~start:2 ~end_:5 "abcdefg") "cde";
        assert_string (Js.String.slice ~start:2 ~end_:9 "abcdefg") "cdefg";
        assert_string (Js.String.slice ~start:(-4) ~end_:(-2) "abcdefg") "de";
        assert_string (Js.String.slice ~start:5 ~end_:1 "abcdefg") "";
        assert_string (Js.String.slice ~start:4 "abcdefg") "efg";
        assert_string (Js.String.slice ~start:(-2) "abcdefg") "fg";
        assert_string (Js.String.slice ~start:7 "abcdefg") "";
        (* UTF-16 indices: "a😀b".slice(1, 3) = "😀" *)
        assert_string (Js.String.slice ~start:1 ~end_:3 {js|a😀b|js}) {js|😀|js};
        assert_string (Js.String.slice ~start:(-1) {js|😀x|js}) "x");
    test "split" (fun () ->
        assert_string_array (Js.String.split ~sep:"" "") [||];
        assert_string_array (Js.String.split ~sep:"-" "2018-01-02") [| "2018"; "01"; "02" |];
        assert_string_array (Js.String.split ~sep:"," "a,b,,c") [| "a"; "b"; ""; "c" |];
        assert_string_array
          (Js.String.split ~sep:"::" "good::bad as great::awful")
          [| "good"; "bad as great"; "awful" |];
        assert_string_array (Js.String.split ~sep:";" "has-no-delimiter") [| "has-no-delimiter" |];
        assert_string_array
          (Js.String.split ~sep:"with" "with-sep-equals-to-beginning")
          [| ""; "-sep-equals-to-beginning" |];
        assert_string_array (Js.String.split ~sep:"end" "with-sep-equals-to-end") [| "with-sep-equals-to-"; "" |];
        assert_string_array
          (Js.String.split ~sep:"/" "/with-sep-on-beginning-and-end/")
          [| ""; "with-sep-on-beginning-and-end"; "" |];
        assert_string_array
          (Js.String.split ~sep:"" "with-empty-sep")
          [| "w"; "i"; "t"; "h"; "-"; "e"; "m"; "p"; "t"; "y"; "-"; "s"; "e"; "p" |];
        assert_string_array (Js.String.split ~sep:"-" "with-limit-equals-to-zero" ~limit:0) [||];
        assert_string_array
          (Js.String.split ~sep:"-" "with-limit-equals-to-length" ~limit:5)
          [| "with"; "limit"; "equals"; "to"; "length" |];
        assert_string_array
          (Js.String.split ~sep:"-" "with-limit-greater-than-length" ~limit:100)
          [| "with"; "limit"; "greater"; "than"; "length" |];
        assert_string_array
          (Js.String.split ~sep:"-" "with-limit-less-than-zero" ~limit:(-2))
          [| "with"; "limit"; "less"; "than"; "zero" |]);
    test "splitAtMost" (fun () ->
        assert_string_array (Js.String.split ~sep:"/" ~limit:3 "ant/bee/cat/dog/elk") [| "ant"; "bee"; "cat" |];
        assert_string_array (Js.String.split ~sep:"/" ~limit:0 "ant/bee/cat/dog/elk") [||];
        assert_string_array
          (Js.String.split ~sep:"/" ~limit:9 "ant/bee/cat/dog/elk")
          [| "ant"; "bee"; "cat"; "dog"; "elk" |]);
    test "split unicode" (fun () ->
        (* an empty separator splits per UTF-16 code unit; "é" is one unit *)
        assert_string_array (Js.String.split ~sep:"" {js|héllo|js}) [| "h"; {js|é|js}; "l"; "l"; "o" |]);
    test "split without separator" (fun () ->
        (* str.split(undefined) is [str], like in JavaScript *)
        assert_string_array (Js.String.split "abc") [| "abc" |];
        assert_string_array (Js.String.split ~limit:2 "abc") [| "abc" |];
        assert_string_array (Js.String.split ~limit:0 "abc") [||]);
    test "split empty string" (fun () ->
        (* "".split("-") is [""], but "".split("") is [] *)
        assert_string_array (Js.String.split ~sep:"-" "") [| "" |];
        assert_string_array (Js.String.split ~sep:"" "") [||]);
    test "splitByRe" (fun () ->
        let unsafe_splitByRe s r = Js.String.splitByRe ~regexp:r s |> Stdlib.Array.map Stdlib.Option.get in
        assert_string_array
          (unsafe_splitByRe "art; bed , cog ;dad" [%re "/\\s*[,;]\\s*/"])
          [| "art"; "bed"; "cog"; "dad" |];
        assert_string_array (unsafe_splitByRe "has:no:match" [%re "/[,;]/"]) [| "has:no:match" |]);
    test "splitByRe with empty-match regex terminates" (fun () ->
        (* "abc".split(/x*/) = ["a", "b", "c"] *)
        assert_string_option_array (Js.String.splitByRe ~regexp:[%re "/x*/"] "abc") [| Some "a"; Some "b"; Some "c" |];
        assert_string_option_array (Js.String.splitByRe ~regexp:[%re "/x*/g"] "abc") [| Some "a"; Some "b"; Some "c" |]);
    test "splitByRe handles a separator that splits a surrogate pair" (fun () ->
        assert_string_option_array
          (Js.String.splitByRe ~regexp:(Js.Re.fromString "\\uD83D") {js|😀|js})
          [| Some ""; Some {js|�|js} |]);
    test "splitByRe splices captures in" (fun () ->
        (* "a#b#:c".split(/(#)(:)?/) = ["a", "#", undefined, "b", "#", ":", "c"] *)
        assert_string_option_array
          (Js.String.splitByRe ~regexp:[%re "/(#)(:)?/"] "a#b#:c")
          [| Some "a"; Some "#"; None; Some "b"; Some "#"; Some ":"; Some "c" |]);
    test "splitByReAtMost" (fun () ->
        assert_string_option_array
          (Js.String.splitByRe ~regexp:[%re "/\\s*:\\s*/"] ~limit:3 "one: two: three: four")
          [| Some "one"; Some "two"; Some "three" |];
        assert_string_option_array
          (Js.String.splitByRe ~regexp:[%re "/\\s*:\\s*/"] ~limit:0 "one: two: three: four")
          [||];
        assert_string_option_array
          (Js.String.splitByRe ~regexp:[%re "/\\s*:\\s*/"] ~limit:8 "one: two: three: four")
          [| Some "one"; Some "two"; Some "three"; Some "four" |];
        (* spliced captures count toward the limit *)
        assert_string_option_array
          (Js.String.splitByRe ~regexp:[%re "/(#)(:)?/"] ~limit:3 "a#b#:c")
          [| Some "a"; Some "#"; None |];
        (* negative limits are coerced with ToUint32 and behave as "no limit" *)
        assert_string_option_array
          (Js.String.splitByRe ~regexp:[%re "/,/"] ~limit:(-1) "a,b,c")
          [| Some "a"; Some "b"; Some "c" |]);
    test "startsWith" (fun () ->
        assert_bool (Js.String.startsWith "ReScript" ~prefix:"Re") true;
        assert_bool (Js.String.startsWith "ReScript" ~prefix:"") true;
        assert_bool (Js.String.startsWith "JavaScript" ~prefix:"Re") false;
        assert_bool (Js.String.startsWith ~prefix:"cri" ~start:3 "ReScript") true;
        assert_bool (Js.String.startsWith ~prefix:"" ~start:3 "ReScript") true;
        assert_bool (Js.String.startsWith ~prefix:"Re" ~start:2 "JavaScript") false;
        (* negative start clamps to 0; positions are UTF-16 code units *)
        assert_bool (Js.String.startsWith ~prefix:"He" ~start:(-5) "Hello") true;
        assert_bool (Js.String.startsWith ~prefix:"b" ~start:2 {js|😀b|js}) true);
    test "substr" (fun () ->
        assert_string (Js.String.substr ~start:3 "abcdefghij") "defghij";
        assert_string (Js.String.substr ~start:(-3) "abcdefghij") "hij";
        assert_string (Js.String.substr ~start:12 "abcdefghij") "");
    test "substrAtMost" (fun () ->
        assert_string (Js.String.substr ~start:3 ~len:4 "abcdefghij") "defg";
        assert_string (Js.String.substr ~start:(-3) ~len:4 "abcdefghij") "hij";
        assert_string (Js.String.substr ~start:12 ~len:2 "abcdefghij") "");
    test "substring" (fun () ->
        assert_string (Js.String.substring ~start:3 ~end_:6 "playground") "ygr";
        assert_string (Js.String.substring ~start:6 ~end_:3 "playground") "ygr";
        assert_string (Js.String.substring ~start:4 ~end_:12 "playground") "ground";
        assert_string (Js.String.substring ~start:4 "playground") "ground";
        assert_string (Js.String.substring ~start:(-3) "playground") "playground";
        assert_string (Js.String.substring ~start:12 "playground") "";
        (* UTF-16 indices: "a😀b".substring(3) = "b" *)
        assert_string (Js.String.substring ~start:3 {js|a😀b|js}) "b");
    test "toLowerCase" (fun () ->
        assert_string (Js.String.toLowerCase "") "";
        assert_string (Js.String.toLowerCase "ASCII: ABC") "ascii: abc";
        assert_string (Js.String.toLowerCase "Non ASCII: ΣΠ") "non ascii: σπ";
        assert_string (Js.String.toLowerCase "Unicode Σ: \u{03a3}") "unicode σ: \u{03c3}";
        assert_string
          (Js.String.toLowerCase "Unicode Mongolian separator + Σ + Mongolian separator: \u{180E} + \u{03a3} + \u{180E}")
          "unicode mongolian separator + σ + mongolian separator: \u{180E} + \u{03c3} + \u{180E}");
    test "toUpperCase" (fun () ->
        assert_string (Js.String.toUpperCase "") "";
        assert_string (Js.String.toUpperCase "abc") "ABC";
        assert_string (Js.String.toUpperCase "Non ASCII: σπ") "NON ASCII: ΣΠ";
        assert_string (Js.String.toUpperCase "Unicode: \u{03c3}") "UNICODE: \u{03a3}";
        assert_string
          (Js.String.toUpperCase "Unicode Mongolian separator + σ + Mongolian separator: \u{180E} + \u{03c3} + \u{180E}")
          "UNICODE MONGOLIAN SEPARATOR + Σ + MONGOLIAN SEPARATOR: \u{180E} + \u{03a3} + \u{180E}");
    test "trim" (fun () ->
        assert_string (Js.String.trim "   abc def   ") "abc def";
        assert_string (Js.String.trim "\n\r\t abc def \n\n\t\r ") "abc def";
        (* the ECMA-262 WhiteSpace set includes \f, NBSP and the BOM *)
        assert_string (Js.String.trim "\x0Cx\x0C") "x";
        assert_string (Js.String.trim "\u{00A0}x\u{00A0}") "x";
        assert_string (Js.String.trim "\u{FEFF}x\u{FEFF}") "x";
        (* U+180E (Mongolian vowel separator) is not whitespace since Unicode 6.3 *)
        assert_string (Js.String.trim "\u{180E}x\u{180E}") "\u{180E}x\u{180E}");
    test "anchor" (fun () ->
        (* node: anchor with a double quote in the name escapes it as &quot; *)
        assert_string (Js.String.anchor ~name:"bar\"baz" "foo") "<a name=\"bar&quot;baz\">foo</a>");
    test "link" (fun () ->
        (* node: link wraps in an <a href> tag, expected output verified in node *)
        assert_string
          (Js.String.link ~href:"https://x.com?a=1&b=2" "click")
          "<a href=\"https://x.com?a=1&b=2\">click</a>");
    test "anchor" (fun () ->
        (* assert_string
           (anchor "page1" "Page One")
           "<a name=\"page1\">Page One</a>" *)
        ());
    test "link" (fun () ->
        (* assert_string
           (link "page2.html" "Go to page two")
           "<a href=\"page2.html\">Go to page two</a>" *)
        ());
  ]

let global_tests =
  [
    test "decodeURI - ascii and spaces" (fun () ->
        assert_string (Js.Global.decodeURI "Hello%20World") "Hello World";
        assert_string (Js.Global.decodeURI "Hello%20%20%20World") "Hello   World";
        assert_string (Js.Global.decodeURI "Hello%2DWorld") "Hello-World");
    test "decodeURI - reserved characters" (fun () ->
        assert_string (Js.Global.decodeURI ";,/?:@&=+$#") ";,/?:@&=+$#";
        assert_string (Js.Global.decodeURI "-_.!~*'()") "-_.!~*'()";
        assert_string (Js.Global.decodeURI "%5B%5D") "[]";
        assert_string (Js.Global.decodeURI "%7B%7D") "{}";
        assert_string (Js.Global.decodeURI "%7C") "|");
    test "decodeURI - alphabets" (fun () ->
        assert_string (Js.Global.decodeURI "ABCDEFGHIJKLMNOPQRSTUVWXYZ") "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        assert_string (Js.Global.decodeURI "abcdefghijklmnopqrstuvwxyz") "abcdefghijklmnopqrstuvwxyz";
        assert_string (Js.Global.decodeURI "0123456789") "0123456789");
    test "decodeURI - unicode characters" (fun () ->
        assert_string (Js.Global.decodeURI "%D0%AE%D0%BD%D0%B8%D0%BA%D0%BE%D0%B4") "Юникод";
        assert_string (Js.Global.decodeURI "%E2%82%AC%E2%98%85%E2%99%A0") "€★♠";
        assert_string (Js.Global.decodeURI "%E4%BD%A0%E5%A5%BD") "你好");
    test "decodeURI - mixed percent encodings and Unicode" (fun () ->
        assert_string (Js.Global.decodeURI "Hello%20%E4%BD%A0%E5%A5%BD%20World") "Hello 你好 World";
        assert_string (Js.Global.decodeURI "%E2%82%AC%20%24%20%C2%A3%20%C2%A5") "€ %24 £ ¥");
    test "decodeURI - complete URLs" (fun () ->
        assert_string
          (Js.Global.decodeURI "http://ru.wikipedia.org/wiki/%D0%AE%D0%BD%D0%B8%D0%BA%D0%BE%D0%B4")
          "http://ru.wikipedia.org/wiki/Юникод";
        assert_string
          (Js.Global.decodeURI "http://www.google.ru/support/jobs/bin/static.py?page=why-ru.html&sid=liveandwork")
          "http://www.google.ru/support/jobs/bin/static.py?page=why-ru.html&sid=liveandwork";
        assert_string
          (Js.Global.decodeURI "https://example.com/path%20name/file.txt")
          "https://example.com/path name/file.txt");
    test "decodeURI - overencoded sequences" (fun () ->
        assert_string (Js.Global.decodeURI "Hello%2520World") "Hello%20World";
        assert_string (Js.Global.decodeURI "%25252525") "%252525");
    test "decodeURI - special characters" (fun () ->
        assert_string (Js.Global.decodeURI "%0A") "\n";
        assert_string (Js.Global.decodeURI "%0D") "\r";
        assert_string (Js.Global.decodeURI "%3C%3E%22%5C") "<>\"\\");
    test "decodeURI - beyond U+10FFFF" (fun () ->
        assert_raises (fun () -> Js.Global.decodeURI "%F4%90%80%80") (Failure "decodeURI: malformed URI sequence"));
    test "decodeURI - partial sequences" (fun () ->
        (* Incomplete or malformed sequences *)
        assert_raises (fun () -> Js.Global.decodeURI "%E4") (Failure "decodeURI: malformed URI sequence");
        assert_raises (fun () -> Js.Global.decodeURI "%E4%A") (Failure "decodeURI: malformed URI sequence"));
    test "encodeURI - ascii and spaces" (fun () ->
        assert_string (Js.Global.encodeURI "Hello World") "Hello%20World";
        assert_string (Js.Global.encodeURI "Hello   World") "Hello%20%20%20World";
        assert_string (Js.Global.encodeURI "Hello-World") "Hello-World");
    test "encodeURI - reserved characters" (fun () ->
        assert_string (Js.Global.encodeURI ";,/?:@&=+$#") ";,/?:@&=+$#";
        assert_string (Js.Global.encodeURI "-_.!~*'()") "-_.!~*'()");
    test "encodeURI - alphabets" (fun () ->
        assert_string (Js.Global.encodeURI "ABCDEFGHIJKLMNOPQRSTUVWXYZ") "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        assert_string (Js.Global.encodeURI "abcdefghijklmnopqrstuvwxyz") "abcdefghijklmnopqrstuvwxyz";
        assert_string (Js.Global.encodeURI "0123456789") "0123456789");
    test "encodeURI - unicode characters" (fun () ->
        assert_string (Js.Global.encodeURI "Юникод") "%D0%AE%D0%BD%D0%B8%D0%BA%D0%BE%D0%B4";
        assert_string (Js.Global.encodeURI "€★♠") "%E2%82%AC%E2%98%85%E2%99%A0";
        assert_string (Js.Global.encodeURI "你好") "%E4%BD%A0%E5%A5%BD");
    test "encodeURI - complete URLs" (fun () ->
        assert_string (Js.Global.encodeURI "http://unipro.ru/0123456789") "http://unipro.ru/0123456789";
        assert_string
          (Js.Global.encodeURI "http://www.google.ru/support/jobs/bin/static.py?page=why-ru.html&sid=liveandwork")
          "http://www.google.ru/support/jobs/bin/static.py?page=why-ru.html&sid=liveandwork";
        assert_string (Js.Global.encodeURI "http://unipro.ru/\nabout") "http://unipro.ru/%0Aabout";
        assert_string (Js.Global.encodeURI "http://unipro.ru/\rabout") "http://unipro.ru/%0Dabout";
        assert_string
          (Js.Global.encodeURI "http://ru.wikipedia.org/wiki/Юникод")
          "http://ru.wikipedia.org/wiki/%D0%AE%D0%BD%D0%B8%D0%BA%D0%BE%D0%B4";
        assert_string
          (Js.Global.encodeURI "http://www.google.ru/support/jobs/bin/static.py?page=why-ru.html&sid=liveandwork")
          "http://www.google.ru/support/jobs/bin/static.py?page=why-ru.html&sid=liveandwork";
        assert_string
          (Js.Global.encodeURI "https://example.com/path name/file.txt")
          "https://example.com/path%20name/file.txt");
    test "encodeURI - special characters" (fun () ->
        assert_string (Js.Global.encodeURI "\n") "%0A";
        assert_string (Js.Global.encodeURI "\r") "%0D";
        assert_string (Js.Global.encodeURI "<>\"\\") "%3C%3E%22%5C";
        assert_string (Js.Global.encodeURI "http://unipro.ru/\nabout") "http://unipro.ru/%0Aabout";
        assert_string (Js.Global.encodeURI "http://unipro.ru/\rabout") "http://unipro.ru/%0Dabout");
    test "encodeURI - combining characters" (fun () ->
        (* Characters with combining diacritical marks *)
        assert_string (Js.Global.encodeURI "é") (* e + acute accent as single char *) "%C3%A9";
        assert_string (Js.Global.encodeURI "e\u{0301}") (* e + combining acute accent *) "e%CC%81";
        assert_string (Js.Global.encodeURI "ế") (* e + circumflex + acute *) "%E1%BA%BF");
    test "encodeURI - Surrogate pairs" (fun () ->
        (* Surrogate pairs for emoji and complex Unicode *)
        assert_string (Js.Global.encodeURI "𝌆") (* Musical symbol *) "%F0%9D%8C%86";
        assert_string (Js.Global.encodeURI "🌍") (* Earth globe *) "%F0%9F%8C%8D";
        assert_string
          (Js.Global.encodeURI "👨‍👩‍👧‍👦") (* Family emoji with ZWJ sequences *)
          "%F0%9F%91%A8%E2%80%8D%F0%9F%91%A9%E2%80%8D%F0%9F%91%A7%E2%80%8D%F0%9F%91%A6");
    (* \v and \f are not supported in ocaml *)
    (*
       assert_string
         (Js.Global.decodeURIComponent "http://unipro.ru/%0Babout")
          "http://unipro.ru/\vabout";
        assert_string
          (Js.Global.decodeURIComponent "http://unipro.ru/%0Cabout")
          "http://unipro.ru/\fabout"; *)
    test "encodeURIComponent" (fun () ->
        assert_string (Js.Global.encodeURIComponent "http://unipro.ru") "http%3A%2F%2Funipro.ru";
        assert_string
          (Js.Global.encodeURIComponent
             "http://www.google.ru/support/jobs/bin/static.py?page=why-ru.html&sid=liveandwork")
          "http%3A%2F%2Fwww.google.ru%2Fsupport%2Fjobs%2Fbin%2Fstatic.py%3Fpage%3Dwhy-ru.html%26sid%3Dliveandwork";
        assert_string (Js.Global.encodeURIComponent "ABCDEFGHIJKLMNOPQRSTUVWXYZ") "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        assert_string (Js.Global.encodeURIComponent "abcdefghijklmnopqrstuvwxyz") "abcdefghijklmnopqrstuvwxyz";
        assert_string (Js.Global.encodeURIComponent "http://unipro.ru/\nabout") "http%3A%2F%2Funipro.ru%2F%0Aabout";
        assert_string (Js.Global.encodeURIComponent "http://unipro.ru/\rabout") "http%3A%2F%2Funipro.ru%2F%0Dabout");
    (* \v and \f are not supported in ocaml
       assert_string
         (Js.Global.encodeURIComponent "http://unipro.ru/\vabout")
         "http%3A%2F%2Funipro.ru%2F%0Babout";
       assert_string
         (Js.Global.encodeURIComponent "http://unipro.ru/\fabout")
         "http%3A%2F%2Funipro.ru%2F%0Cabout"; *)
  ]

let obj () = Js.Dict.fromList [ ("foo", 43); ("bar", 86) ]
let long_obj () = Js.Dict.fromList [ ("david", 99); ("foo", 43); ("bar", 86) ]
let obj_duplicated () = Js.Dict.fromList [ ("foo", 43); ("bar", 86); ("bar", 1) ]

module Obj_test = struct
  external make : onLoad:string -> ?retries:int -> unit -> < onLoad : string ; retries : int option > Js.t = ""
  [@@mel.obj]

  external makeKeyword : _type:string -> unit -> < _type : string > Js.t = "" [@@mel.obj]
end

let obj_tests =
  [
    test "empty" (fun () -> assert_string_array (Js.Obj.keys (Js.Obj.empty ())) [||]);
    test "@@mel.obj" (fun () ->
        let props = Obj_test.make ~onLoad:"ready" () in
        assert_string props##onLoad "ready";
        assert_option_int props##retries None;
        assert_string_array (Js.Obj.keys props) [| "onLoad" |];
        let props = Obj_test.make ~onLoad:"ready" ~retries:2 () in
        assert_option_int props##retries (Some 2);
        assert_string_array (Js.Obj.keys props) [| "onLoad"; "retries" |]);
    test "@@mel.obj with keyword label" (fun () ->
        let props = Obj_test.makeKeyword ~_type:"button" () in
        assert_string props##_type "button";
        assert_string_array (Js.Obj.keys props) [| "type" |]);
    test "assign mutates target" (fun () ->
        let target = Obj_test.make ~onLoad:"ready" () in
        let source = Obj_test.make ~onLoad:"updated" ~retries:2 () in
        let returned = Js.Obj.assign target source in
        assert_int (Oo.id returned) (Oo.id target);
        assert_string target##onLoad "updated";
        assert_option_int target##retries (Some 2);
        assert_string_array (Js.Obj.keys target) [| "onLoad"; "retries" |];
        assert_string source##onLoad "updated";
        assert_option_int source##retries (Some 2));
    test "merge creates fresh object" (fun () ->
        let left = Obj_test.make ~onLoad:"left" () in
        let right = Obj_test.make ~onLoad:"right" ~retries:3 () in
        let merged : < onLoad : string ; retries : int option > Js.t = Obj.magic (Js.Obj.merge () left right) in
        assert_bool (Oo.id merged = Oo.id left) false;
        assert_bool (Oo.id merged = Oo.id right) false;
        assert_string merged##onLoad "right";
        assert_option_int merged##retries (Some 3);
        assert_string_array (Js.Obj.keys merged) [| "onLoad"; "retries" |];
        assert_string left##onLoad "left";
        assert_option_int left##retries None);
    test "[%mel.obj] evaluates fields once" (fun () ->
        let counter = ref 0 in
        let props =
          [%mel.obj
            {
              count =
                (incr counter;
                 !counter);
            }]
        in
        assert_int props##count 1;
        assert_int props##count 1;
        assert_int !counter 1;
        assert_string_array (Js.Obj.keys props) [| "count" |]);
  ]

let dict_tests =
  [
    test "empty" (fun _ -> assert_string_dict_entries (Js.Dict.entries (Js.Dict.empty ())) [||]);
    test "get" (fun _ -> assert_option_int (Js.Dict.get (obj ()) "foo") (Some 43));
    test "get from missing property" (fun _ -> assert_option_int (Js.Dict.get (obj ()) "baz") None);
    test "unsafe_get" (fun _ -> assert_int (Js.Dict.unsafeGet (obj ()) "foo") 43);
    test "set" (fun _ ->
        let o = Js.Dict.empty () in
        Js.Dict.set o "foo" 36;
        assert_option_int (Js.Dict.get o "foo") (Some 36));
    (* node: Object.keys({david:99,foo:43,bar:86}) = ['david','foo','bar'] — insertion order *)
    test "keys" (fun _ -> assert_string_array (Js.Dict.keys (long_obj ())) [| "david"; "foo"; "bar" |]);
    (* node: Object.keys({foo:43,bar:86,bar:1}) = ['foo','bar'] — duplicate keys collapse, first position kept *)
    test "keys duplicated" (fun _ -> assert_string_array (Js.Dict.keys (obj_duplicated ())) [| "foo"; "bar" |]);
    (* node: Object.entries({foo:43,bar:86}) = [['foo',43],['bar',86]] *)
    test "entries" (fun _ -> assert_int_dict_entries (Js.Dict.entries (obj ())) [| ("foo", 43); ("bar", 86) |]);
    test "values" (fun _ -> assert_array_int (Js.Dict.values (obj ())) [| 43; 86 |]);
    (* node: Object.values({foo:43,bar:86,bar:1}) = [43,1] — last value wins *)
    test "values duplicated" (fun _ -> assert_array_int (Js.Dict.values (obj_duplicated ())) [| 43; 1 |]);
    test "fromList - []" (fun _ -> assert_int_dict_entries (Js.Dict.entries (Js.Dict.fromList [])) [||]);
    test "fromList" (fun _ ->
        assert_int_dict_entries (Js.Dict.entries (Js.Dict.fromList [ ("x", 23); ("y", 46) ])) [| ("x", 23); ("y", 46) |]);
    test "fromArray - []" (fun _ -> assert_int_dict_entries (Js.Dict.entries (Js.Dict.fromArray [||])) [||]);
    test "fromArray" (fun _ ->
        assert_int_dict_entries
          (Js.Dict.entries (Js.Dict.fromArray [| ("x", 23); ("y", 46) |]))
          [| ("x", 23); ("y", 46) |]);
    test "map" (fun _ ->
        let prices = Js.Dict.fromList [ ("pen", 1); ("book", 5); ("stapler", 7) ] in
        let discount price = price * 10 in
        let salePrices = Js.Dict.map ~f:discount prices in
        (* insertion order: pen, book, stapler *)
        assert_int_dict_entries (Js.Dict.entries salePrices) [| ("pen", 10); ("book", 50); ("stapler", 70) |]);
  ]

let promise_to_lwt (p : 'a Js.Promise.t) : 'a Lwt.t = Obj.magic p

let set_timeout callback delay =
  Lwt.async (fun () ->
      let%lwt () = Lwt_unix.sleep delay in
      callback ();
      Lwt.return ())

let set_immediate callback =
  Lwt.async (fun () ->
      let%lwt () = Lwt.pause () in
      callback ();
      Lwt.return ())

let promise_tests =
  [
    test_async "resolve" (fun _switch () ->
        let value = "hi" in
        let resolved = Js.Promise.resolve value in
        resolved |> promise_to_lwt |> Lwt.map (assert_string value));
    test_async "all" (fun _switch () ->
        let p0 = Js.Promise.make (fun ~resolve ~reject:_ -> resolve 5) in
        let p1 = Js.Promise.make (fun ~resolve ~reject:_ -> resolve 10) in
        let resolved = Js.Promise.all [| p0; p1 |] in
        resolved |> promise_to_lwt |> Lwt.map (assert_array_int [| 5; 10 |]));
    test_async "all_async" (fun _switch () ->
        let p0 = Js.Promise.make (fun ~resolve ~reject:_ -> set_immediate (fun () -> resolve 5)) in
        let p1 = Js.Promise.make (fun ~resolve ~reject:_ -> set_immediate (fun () -> resolve 99)) in
        let resolved = Js.Promise.all [| p0; p1 |] in
        resolved |> promise_to_lwt |> Lwt.map (assert_array_int [| 5; 99 |]));
    test_async "race_async" (fun _switch () ->
        let p0 = Js.Promise.make (fun ~resolve ~reject:_ -> set_timeout (fun () -> resolve "second") 0.005) in
        let p1 = Js.Promise.make (fun ~resolve ~reject:_ -> set_immediate (fun () -> resolve "first")) in
        let resolved = Js.Promise.race [| p0; p1 |] in
        resolved |> promise_to_lwt |> Lwt.map (assert_string "first"));
  ]

let float_tests =
  [
    test "string_of_float" (fun () ->
        assert_string (string_of_float 0.5) "0.5";
        assert_string (string_of_float 80.0) "80.";
        assert_string (string_of_float 80.) "80.";
        assert_string (string_of_float 80.0001) "80.0001";
        assert_string (string_of_float 80.00000000001) "80.");
    test "toString" (fun () ->
        assert_string (Js.Float.toString 0.5) "0.5";
        assert_string (Js.Float.toString 80.0) "80";
        assert_string (Js.Float.toString 80.) "80";
        assert_string (Js.Float.toString 80.0001) "80.0001";
        (* assert_string (Js.Float.toString 80.00000000001) "80.00000000001"; JS/Melange outputs "80.00000000001" but ocaml outputs "80." *)
        assert_string (Js.Float.toString Stdlib.Float.nan) "NaN";
        assert_string (Js.Float.toString Stdlib.Float.infinity) "Infinity";
        assert_string (Js.Float.toString Stdlib.Float.neg_infinity) "-Infinity");
    test "fromString" (fun () ->
        assert_float (Js.Float.fromString "0.5") 0.5;
        assert_float (Js.Float.fromString "80") 80.;
        assert_float (Js.Float.fromString "80.0001") 80.0001;
        (* assert_float (Js.Float.fromString "80.00000000001") 80.00000000001; JS/Melange outputs 80.00000000001 but ocaml outputs 80. *)
        assert_float (Js.Float.fromString "NaN") Stdlib.Float.nan;
        assert_float (Js.Float.fromString "Infinity") Stdlib.Float.infinity;
        assert_float (Js.Float.fromString "-Infinity") Stdlib.Float.neg_infinity);
    test "fromString follows JS Number() semantics" (fun () ->
        (* node: Number("abc") is NaN (Number(), not parseFloat) *)
        assert_float_exact (Js.Float.fromString "abc") Stdlib.Float.nan;
        (* node: Number("3.5px") is NaN, unlike parseFloat("3.5px") === 3.5 *)
        assert_float_exact (Js.Float.fromString "3.5px") Stdlib.Float.nan;
        (* node: Number("1_0") is NaN (no numeric separators) *)
        assert_float_exact (Js.Float.fromString "1_0") Stdlib.Float.nan;
        (* node: Number("") === 0 and Number("   ") === 0 *)
        assert_float_exact (Js.Float.fromString "") 0.;
        assert_float_exact (Js.Float.fromString "   ") 0.;
        (* node: Number(" 42 ") === 42 (whitespace trimmed on both sides) *)
        assert_float_exact (Js.Float.fromString " 42 ") 42.;
        (* node: Number("0x10") === 16, Number("0b101") === 5, Number("0o17") === 15 *)
        assert_float_exact (Js.Float.fromString "0x10") 16.;
        assert_float_exact (Js.Float.fromString "0b101") 5.;
        assert_float_exact (Js.Float.fromString "0o17") 15.;
        (* node: Number("+Infinity") === Infinity *)
        assert_float_exact (Js.Float.fromString "+Infinity") Stdlib.Float.infinity);
    test "toFixed" (fun () ->
        assert_string (Js.Float.toFixed 12.3456) "12";
        assert_string (Js.Float.toFixed ~digits:20 0.) "0.00000000000000000000";
        assert_string (Js.Float.toFixed ~digits:0 (-12.)) "-12";
        assert_string (Js.Float.toFixed ~digits:0 Stdlib.Float.nan) "NaN";
        assert_string (Js.Float.toFixed ~digits:0 1000000000000000128.) "1000000000000000128";
        assert_string (Js.Float.toFixed ~digits:3 12.3456) "12.346";
        assert_string (Js.Float.toFixed ~digits:50 0.3) "0.29999999999999998889776975374843459576368331909180";
        Alcotest.check_raises "Expected failure" (Failure "toFixed() digits argument must be between 0 and 100")
          (fun () ->
            let _ = Js.Float.toFixed ~digits:(-1) 12. in
            ());
        assert_string (Js.Float.toFixed ~digits:2 12.345) "12.35";
        assert_string (Js.Float.toFixed ~digits:2 12.344) "12.34";
        assert_string (Js.Float.toFixed ~digits:1 0.05) "0.1";
        assert_string (Js.Float.toFixed ~digits:5 1e20) "100000000000000000000.00000";
        assert_string (Js.Float.toFixed ~digits:5 1e-20) "0.00000";
        assert_string (Js.Float.toFixed ~digits:10 1e-10) "0.0000000001";
        assert_string (Js.Float.toFixed ~digits:100 0.1)
          "0.1000000000000000055511151231257827021181583404541015625000000000000000000000000000000000000000000000";
        assert_string (Js.Float.toFixed ~digits:0 0.99) "1";
        assert_string (Js.Float.toFixed ~digits:5 Float.infinity) "Infinity";
        assert_string (Js.Float.toFixed ~digits:5 Float.neg_infinity) "-Infinity";
        assert_string (Js.Float.toFixed ~digits:2 (-12.3456)) "-12.35";
        assert_string (Js.Float.toFixed ~digits:4 0.) "0.0000";
        (* assert_string (Js.Float.toFixed ~digits:0 1.2e34) "1.2e+34"; JS/Melange outputs "1.2e+34" but ocaml outputs "11999999999999999346902771844513792" *)
        Alcotest.check_raises "Expected failure for negative digits"
          (Failure "toFixed() digits argument must be between 0 and 100") (fun () ->
            ignore (Js.Float.toFixed ~digits:(-1) 12.34));
        Alcotest.check_raises "Expected failure for exceeding digits limit"
          (Failure "toFixed() digits argument must be between 0 and 100") (fun () ->
            ignore (Js.Float.toFixed ~digits:101 12.34)));
  ]

let math_tests =
  [
    (* Full double-precision values, verified against node's Math.* *)
    test "constants" (fun () ->
        assert_float_exact Js.Math._E 2.718281828459045;
        assert_float_exact Js.Math._LN2 0.6931471805599453;
        assert_float_exact Js.Math._LN10 2.302585092994046;
        assert_float_exact Js.Math._LOG2E 1.4426950408889634;
        assert_float_exact Js.Math._LOG10E 0.4342944819032518;
        assert_float_exact Js.Math._PI 3.141592653589793;
        assert_float_exact Js.Math._SQRT1_2 0.7071067811865476;
        assert_float_exact Js.Math._SQRT2 1.4142135623730951);
  ]

let () =
  Lwt_main.run
  @@ Alcotest_lwt.run "Js"
       [
         ("Js.Global", global_tests);
         ("Js.Global.timers", Melange_tests.Js_global_timers.tests);
         ("Js.Math", math_tests);
         (* Ported from Melange's test suite (jscomp/test) *)
         ("Melange.Js.Math", Melange_tests.Js_math.tests);
         ("Melange.Js.Array", Melange_tests.Js_array.tests);
         ("Melange.Js.Json", Melange_tests.Js_json.tests);
         ("Melange.Js.Dict", Melange_tests.Js_dict.tests);
         ("Melange.Js.Obj", Melange_tests.Js_obj.tests);
         ("Melange.Js.Global", Melange_tests.Js_global.tests);
         ("Melange.Js.Int", Melange_tests.Js_int.tests);
         ("Melange.Js.Float", Melange_tests.Js_float.tests);
         ("Melange.Js.Null", Melange_tests.Js_null.tests);
         ("Melange.Js.Promise", Melange_tests.Js_promise.tests);
         ("Melange.Js.Re", Melange_tests.Js_re.tests);
         ("Melange.Js.Undefined", Melange_tests.Js_undefined.tests);
         ("Melange.Js.Array.modern", Melange_tests.Js_array_modern.tests);
         ("Melange.Js.Nullable", Melange_tests.Js_nullable.tests);
         ("Melange.Js.MapSet", Melange_tests.Js_map_set.tests);
         ("Melange.Js.Exn", Melange_tests.Js_exn.tests);
         ("Melange.Js.String", Melange_tests.Js_string.tests);
         ("Melange.Js.Date", Melange_tests.Js_date.tests);
         ("Js.Promise", promise_tests);
         ("Js.Float", float_tests);
         ("Js.String", string_tests);
         ("Js.Re", re_tests);
         ("Js.Obj", obj_tests);
         ("Js.Dict", dict_tests);
         ("Js.Array", []);
         ("Js.Undefined", Undefined_tests.Undefined.tests);
         (* Test262 - BigInt *)
         ("BigInt.Arithmetic", Bigint_tests.Arithmetic.tests);
         ("BigInt.Bitwise", Bigint_tests.Bitwise.tests);
         ("BigInt.Comparison", Bigint_tests.Comparison.tests);
         ("BigInt.Constructor", Bigint_tests.Constructor.tests);
         ("BigInt.Conversion", Bigint_tests.Conversion.tests);
         ("BigInt.AsIntN", Bigint_tests.As_int_n.tests);
         ("BigInt.AsUintN", Bigint_tests.As_uint_n.tests);
         ("BigInt.Prototype", Bigint_tests.Prototype.tests);
         (* Test262 - Date *)
         ("Date.Getters", Date_tests.Getters.tests);
         ("Date.LocalGetters", Date_tests.Local_getters.tests);
         ("Date.Setters", Date_tests.Setters.tests);
         ("Date.ToString", Date_tests.To_string.tests);
         ("Date.Now", Date_tests.Now.tests);
         ("Date.Parse", Date_tests.Parse.tests);
         ("Date.LocalTime", Date_tests.Local_time.tests);
         ("Date.ToISOString", Date_tests.To_iso_string.tests);
         ("Date.UTC", Date_tests.Utc.tests);
         (* Test262 - Number *)
         ("Number.IsFinite", Number_tests.Is_finite.tests);
         ("Number.IsInteger", Number_tests.Is_integer.tests);
         ("Number.IsNaN", Number_tests.Is_nan.tests);
         ("Number.ParseFloat", Number_tests.Parse_float.tests);
         ("Number.ParseInt", Number_tests.Parse_int.tests);
         ("Number.ToString", Number_tests.To_string.tests);
         ("Number.ToExponential", Number_tests.To_exponential.tests);
         ("Number.ToPrecision", Number_tests.To_precision.tests);
         (* Test262 - String *)
         ("String.Normalize", String_tests.Normalize.tests);
         ("String.Search", String_tests.Search.tests);
         (* Test262 - RegExp *)
         ("RegExp.NamedGroups", Regexp_tests.Named_groups.tests);
         ("RegExp.DotAll", Regexp_tests.Dotall.tests);
         ("RegExp.Unicode", Regexp_tests.Unicode.tests);
       ]
