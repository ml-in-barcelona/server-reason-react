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
    test "length" (fun () -> assert_int (Js.String.length "abcd") 4);
    test "get" (fun () ->
        assert_string (Js.String.get "Reason" 0) "R";
        assert_string (Js.String.get "Reason" 4) "o" (* assert_string (Js.String.get {js|Rẽasöń|js} 5) {js|ń|js}; *));
    test "fromCharCode" (fun () ->
        assert_string (Js.String.fromCharCode 65) "A";
        (* assert_string (Js.String.fromCharCode 0x3c8) {js|ψ|js}; *)
        (* assert_string (Js.String.fromCharCode 0xd55c) {js|한|js} *)
        (* assert_string (Js.String.fromCharCode -64568) {js|ψ|js}; *)
        ());
    test "fromCharCodeMany" (fun () ->
        (* fromCharCodeMany([|0xd55c, 0xae00, 33|]) = {js|한글!|js} *)
        ());
    test "fromCodePoint" (fun () ->
        assert_string (Js.String.fromCodePoint 65) "A"
        (* assert_string (Js.String.fromCodePoint 0x3c8) {js|ψ|js}; *)
        (* assert_string (Js.String.fromCodePoint 0xd55c) {js|한|js} *)
        (* assert_string (Js.String.fromCodePoint 0x1f63a) {js|😺|js} *));
    test "fromCodePointMany" (fun () ->
        (* assert_string
           (Js.String.fromCodePointMany [| 0xd55c; 0xae00; 0x1f63a |])
           {js|한글😺|js} *)
        ());
    test "charAt" (fun () ->
        assert_string (Js.String.charAt "Reason" ~index:0) "R";
        assert_string (Js.String.charAt "Reason" ~index:12) ""
        (* assert_string (Js.String.charAt {js|Rẽasöń|js} 5) {js|ń|js} *));
    test "charCodeAt" (fun () ->
        (* charCodeAt {js|😺|js} 0) 0xd83d *)
        assert_float (Js.String.charCodeAt "lola" ~index:1) 111.;
        assert_float (Js.String.charCodeAt "lola" ~index:0) 108.);
    test "codePointAt" (fun () ->
        assert_option_int (Js.String.codePointAt "lola" ~index:1) (Some 111);
        (* assert_option_int (Js.String.codePointAt {js|¿😺?|js} 1) (Some 0x1f63a); *)
        assert_option_int (Js.String.codePointAt "abc" ~index:5) None);
    test "concat" (fun () -> assert_string (Js.String.concat "cow" ~other:"bell") "cowbell");
    test "concatMany" (fun () ->
        assert_string (Js.String.concatMany "1st" ~strings:[| "2nd"; "3rd"; "4th" |]) "1st2nd3rd4th");
    test "endsWith" (fun () ->
        assert_bool (Js.String.endsWith "ReScript" ~suffix:"Script") true;
        assert_bool (Js.String.endsWith "ReShoes" ~suffix:"Script") false;
        assert_bool (Js.String.endsWith "abcd" ~suffix:"cd" ~len:4) true;
        assert_bool (Js.String.endsWith "abcde" ~suffix:"cd" ~len:3) false;
        (* assert_bool (Js.String.endsWith "abcde" ~suffix:"cde" ~len:99) true; *)
        assert_bool (Js.String.endsWith "example.dat" ~suffix:"ple" ~len:7) true);
    test "includes" (fun () ->
        assert_bool (Js.String.includes "programmer" ~search:"gram") true;
        assert_bool (Js.String.includes "programmer" ~search:"er") true;
        assert_bool (Js.String.includes "programmer" ~search:"pro") true;
        assert_bool (Js.String.includes "programmer" ~search:"xyz") false;
        assert_bool (Js.String.includes "programmer" ~search:"gram" ~start:1) true;
        assert_bool (Js.String.includes "programmer" ~search:"gram" ~start:4) false
        (* assert_bool (Js.String.includesFrom {js|한|js} {js|대한민국|js} 1) true *));
    test "indexOf" (fun () ->
        assert_int (Js.String.indexOf "bookseller" ~search:"ok") 2;
        assert_int (Js.String.indexOf "bookseller" ~search:"sell") 4;
        assert_int (Js.String.indexOf "beekeeper" ~search:"ee") 1;
        assert_int (Js.String.indexOf "bookseller" ~search:"xyz") (-1);
        assert_int (Js.String.indexOf "bookseller" ~search:"ok" ~start:1) 2;
        assert_int (Js.String.indexOf "bookseller" ~search:"sell" ~start:2) 4;
        assert_int (Js.String.indexOf "bookseller" ~search:"sell" ~start:5) (-1);
        assert_int (Js.String.indexOf "bookseller" ~search:"xyz") (-1));
    test "lastIndexOf" (fun () ->
        assert_int (Js.String.lastIndexOf "bookseller" ~search:"ok") 2;
        assert_int (Js.String.lastIndexOf "beekeeper" ~search:"ee") 4;
        assert_int (Js.String.lastIndexOf "abcdefg" ~search:"xyz") (-1);
        assert_int (Js.String.lastIndexOf "bookseller" ~search:"ok" ~start:6) 2;
        assert_int (Js.String.lastIndexOf "beekeeper" ~search:"ee" ~start:8) 4;
        assert_int (Js.String.lastIndexOf "beekeeper" ~search:"ee" ~start:3) 1;
        assert_int (Js.String.lastIndexOf "abcdefg" ~search:"xyz" ~start:4) (-1));
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
    test "repeat" (fun () ->
        assert_string (Js.String.repeat "ha" ~count:3) "hahaha";
        assert_string (Js.String.repeat "empty" ~count:0) "");
    test "replace" (fun () ->
        assert_string (Js.String.replace ~search:"old" ~replacement:"new" "old string") "new string";
        assert_string (Js.String.replace ~search:"the" ~replacement:"this" "the cat and the dog") "this cat and the dog");
    test "replaceByRe" (fun () ->
        assert_string (Js.String.replaceByRe "david" ~regexp:[%re "/d/"] ~replacement:"x") "xavid");
    (* test "replaceByRe with references ($n)" (fun () ->
        assert_string
          (Js.String.replaceByRe "david" ~regexp:[%re "/d(.*?)d/g"]
             ~replacement:"$1")
          "avi"); *)
    test "replaceByRe with global" (fun () ->
        assert_string
          (Js.String.replaceByRe "vowels be gone" ~regexp:[%re "/[aeiou]/g"] ~replacement:"x")
          "vxwxls bx gxnx");
    test "unsafeReplaceBy0" (fun () ->
        (* let str = "beautiful vowels" in
           let re = [%re "/[aeiou]/g"] in
           let matchFn matchPart offset wholeString =
             Js.String.toUpperCase matchPart
           in

           let replaced = Js.String.unsafeReplaceBy0 re matchFn str in

           assert_string replaced "bEAUtifUl vOwEls" *)
        ());
    test "unsafeReplaceBy1" (fun () ->
        (* let str = "increment 23" in
           let re = [%re "/increment (\\d+)/g"] in
           let matchFn matchPart p1 offset wholeString =
             wholeString ^ " is " ^ string_of_int (int_of_string p1 + 1)
           in

           let replaced = Js.String.unsafeReplaceBy1 re matchFn str in
           assert_string replaced "increment 23 is 24" *)
        ());
    test "unsafeReplaceBy2" (fun () ->
        (* let str = "7 times 6" in
           let re = [%re "/(\\d+) times (\\d+)/"] in
           let matchFn matchPart p1 p2 offset wholeString =
             string_of_int (int_of_string p1 * int_of_string p2)
           in

           let replaced = Js.String.unsafeReplaceBy2 re matchFn str in
           assert_string replaced "42" *)
        ());
    test "search" (fun () ->
        (* assert_int (Js.String.search [%re "/\\d+/"] "testing 1 2 3") 8;
           assert_int (Js.String.search [%re "/\\d+/"] "no numbers") (-1) *)
        ());
    test "slice" (fun () ->
        assert_string (Js.String.slice ~start:2 ~end_:5 "abcdefg") "cde";
        assert_string (Js.String.slice ~start:2 ~end_:9 "abcdefg") "cdefg";
        (* assert_string (Js.String.slice ~from:(-4) ~to_:(-2) "abcdefg") "de"; *)
        assert_string (Js.String.slice ~start:5 ~end_:1 "abcdefg") "";
        assert_string (Js.String.slice ~start:4 "abcdefg") "efg";
        (* assert_string (Js.String.sliceToEnd ~from:(-2) "abcdefg") "fg"; *)
        assert_string (Js.String.slice ~start:7 "abcdefg") "");
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
        (* assert_string_array
             (splitAtMost "/" ~limit:3 "ant/bee/cat/dog/elk")
             [| "ant"; "bee"; "cat" |];
           assert_string_array
             (splitAtMost "/" ~limit:0 "ant/bee/cat/dog/elk")
             [||];
           assert_string_array
             (splitAtMost "/" ~limit:9 "ant/bee/cat/dog/elk")
             [| "ant"; "bee"; "cat"; "dog"; "elk" |] *)
        ());
    test "splitByRe" (fun () ->
        let unsafe_splitByRe s r = Js.String.splitByRe ~regexp:r s |> Stdlib.Array.map Stdlib.Option.get in
        assert_string_array
          (unsafe_splitByRe "art; bed , cog ;dad" [%re "/\\s*[,;]\\s*/"])
          [| "art"; "bed"; "cog"; "dad" |]
        (* assert_string_array
           (unsafe_splitByRe "has:no:match" [%re "/[,;]/"])
           [| "has:no:match" |] *));
    (* test "splitByReAtMost" (fun () ->
        assert_string_array
            (splitByReAtMost [%re "/\\s*:\\s*/"] ~limit:3
               "one: two: three: four")
            [| Some "one"; Some "two"; Some "three" |];
          assert_string_array
            (splitByReAtMost [%re "/\\s*:\\s*/"] ~limit:0
               "one: two: three: four")
            [||];
          assert_string_array
            (splitByReAtMost [%re "/\\s*:\\s*/"] ~limit:8
               "one: two: three: four")
            [| Some "one"; Some "two"; Some "three"; Some "four" |];
          assert_string_array
            (splitByReAtMost [%re "/(#)(:)?/"] ~limit:3 "a#b#:c")
            [| Some "a"; Some "#"; None |]
       ());*)
    test "startsWith" (fun () ->
        assert_bool (Js.String.startsWith "ReScript" ~prefix:"Re") true;
        assert_bool (Js.String.startsWith "ReScript" ~prefix:"") true;
        assert_bool (Js.String.startsWith "JavaScript" ~prefix:"Re") false;
        assert_bool (Js.String.startsWith ~prefix:"cri" ~start:3 "ReScript") true;
        assert_bool (Js.String.startsWith ~prefix:"" ~start:3 "ReScript") true;
        assert_bool (Js.String.startsWith ~prefix:"Re" ~start:2 "JavaScript") false);
    test "substr" (fun () ->
        assert_string (Js.String.substr ~start:3 "abcdefghij") "defghij";
        (* assert_string (Js.String.substr ~from:(-3) "abcdefghij") "hij"; *)
        assert_string (Js.String.substr ~start:12 "abcdefghij") "");
    test "substrAtMost" (fun () ->
        (* assert_string (Js.String.substrAtMost ~from:3 ~length:4 "abcdefghij") "defghij"; *)
        (* assert_string (Js.String.substrAtMost ~from:(-3) ~length:4 "abcdefghij") "hij"; *)
        (* assert_string (Js.String.substrAtMost ~from:12 ~length:2 "abcdefghij") "" *)
        ());
    test "substring" (fun () ->
        assert_string (Js.String.substring ~start:3 ~end_:6 "playground") "ygr";
        assert_string (Js.String.substring ~start:6 ~end_:3 "playground") "ygr";
        assert_string (Js.String.substring ~start:4 ~end_:12 "playground") "ground";
        assert_string (Js.String.substring ~start:4 "playground") "ground";
        assert_string (Js.String.substring ~start:(-3) "playground") "playground";
        assert_string (Js.String.substring ~start:12 "playground") "");
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
        assert_string (Js.String.trim "\n\r\t abc def \n\n\t\r ") "abc def");
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
    test "keys" (fun _ -> assert_string_array (Js.Dict.keys (long_obj ())) [| "bar"; "david"; "foo" |]);
    test "keys duplicated" (fun _ -> assert_string_array (Js.Dict.keys (obj_duplicated ())) [| "bar"; "bar"; "foo" |]);
    test "entries" (fun _ -> assert_int_dict_entries (Js.Dict.entries (obj ())) [| ("bar", 86); ("foo", 43) |]);
    test "values" (fun _ -> assert_array_int (Js.Dict.values (obj ())) [| 86; 43 |]);
    test "values duplicated" (fun _ -> assert_array_int (Js.Dict.values (obj_duplicated ())) [| 86; 1; 43 |]);
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
        assert_int_dict_entries (Js.Dict.entries salePrices) [| ("book", 50); ("stapler", 70); ("pen", 10) |]);
  ]

let promise_to_lwt (p : 'a Js.Promise.t) : 'a Lwt.t = Obj.magic p

let set_timeout callback delay =
  let _ =
    Lwt.async (fun () ->
        let%lwt () = Lwt_unix.sleep delay in
        callback ();
        Lwt.return ())
  in
  ()

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
        let p0 = Js.Promise.make (fun ~resolve ~reject:_ -> set_timeout (fun () -> resolve 5) 0.5) in
        let p1 = Js.Promise.make (fun ~resolve ~reject:_ -> set_timeout (fun () -> resolve 99) 0.3) in
        let resolved = Js.Promise.all [| p0; p1 |] in
        resolved |> promise_to_lwt |> Lwt.map (assert_array_int [| 5; 99 |]));
    test_async "race_async" (fun _switch () ->
        let p0 = Js.Promise.make (fun ~resolve ~reject:_ -> set_timeout (fun () -> resolve "second") 0.5) in
        let p1 = Js.Promise.make (fun ~resolve ~reject:_ -> set_timeout (fun () -> resolve "first") 0.3) in
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

let () =
  Lwt_main.run
  @@ Alcotest_lwt.run "Js"
       [
         ("Js.Global", global_tests);
         ("Js.Promise", promise_tests);
         ("Js.Float", float_tests);
         ("Js.String", string_tests);
         ("Js.Re", re_tests);
         ("Js.Dict", dict_tests);
         ("Js.Array", []);
         (* Test262 - BigInt *)
         ("Test262.BigInt.Arithmetic", Test262.Bigint_tests.Arithmetic.tests);
         ("Test262.BigInt.Bitwise", Test262.Bigint_tests.Bitwise.tests);
         ("Test262.BigInt.Comparison", Test262.Bigint_tests.Comparison.tests);
         ("Test262.BigInt.Constructor", Test262.Bigint_tests.Constructor.tests);
         ("Test262.BigInt.Conversion", Test262.Bigint_tests.Conversion.tests);
         (* Test262 - Date *)
         ("Test262.Date.Getters", Test262.Date_tests.Getters.tests);
         ("Test262.Date.Now", Test262.Date_tests.Now.tests);
         ("Test262.Date.Parse", Test262.Date_tests.Parse.tests);
         ("Test262.Date.ToISOString", Test262.Date_tests.To_iso_string.tests);
         ("Test262.Date.UTC", Test262.Date_tests.Utc.tests);
         (* Test262 - Number *)
         ("Test262.Number.IsFinite", Test262.Number_tests.Is_finite.tests);
         ("Test262.Number.IsInteger", Test262.Number_tests.Is_integer.tests);
         ("Test262.Number.IsNaN", Test262.Number_tests.Is_nan.tests);
         ("Test262.Number.ParseFloat", Test262.Number_tests.Parse_float.tests);
         ("Test262.Number.ParseInt", Test262.Number_tests.Parse_int.tests);
       ]
