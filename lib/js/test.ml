let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let assert_option x left right =
  Alcotest.check (Alcotest.option x) "should be equal" right left

let assert_string_array left right =
  Alcotest.check (Alcotest.array Alcotest.string) "should be equal" right left

let assert_int left right =
  Alcotest.check Alcotest.int "should be equal" right left

let assert_float left right =
  Alcotest.check (Alcotest.float 2.) "should be equal" right left

let assert_bool left right =
  Alcotest.check Alcotest.bool "should be equal" right left

let case title (fn : unit -> unit) = Alcotest.test_case title `Quick fn

let re_tests =
  ( "Js.Re",
    [
      case "captures" (fun () ->
          let abc_regex = Js.Re.fromString "abc" in
          let result = Js.Re.exec_ abc_regex "abcdefabcdef" |> Option.get in
          let matches = Js.Re.captures result |> Array.map Option.get in
          assert_string_array matches [| "abc" |]);
      case "modifier: end ($)" (fun () ->
          let regex = Js.Re.fromString "cat$" in
          assert_bool (Js.Re.test_ regex "The cat and mouse") false;
          assert_bool (Js.Re.test_ regex "The mouse and cat") true);
      case "modifier: more than one (+)" (fun () ->
          let regex = Js.Re.fromStringWithFlags ~flags:"i" "boo+(hoo+)+" in
          assert_bool (Js.Re.test_ regex "Boohoooohoohooo") true);
      case "global" (fun () ->
          let regex = Js.Re.fromStringWithFlags ~flags:"g" "hello" in
          let result = Js.Re.exec_ regex "hello world! hello" |> Option.get in
          let matches = Js.Re.captures result |> Array.map Option.get in
          assert_string_array matches [| "hello"; "hello" |]);
      case "global (g) and caseless (i)" (fun () ->
          let regex = Js.Re.fromStringWithFlags ~flags:"gi" "Hello" in
          let result = Js.Re.exec_ regex "Hello gello! hello" |> Option.get in
          let matches = Js.Re.captures result |> Array.map Option.get in
          assert_string_array matches [| "Hello"; "hello" |]);
      case "modifier: or ([])" (fun () ->
          let regex = Js.Re.fromString "(\\w+)\\s(\\w+)" in
          assert_bool (Js.Re.test_ regex "Jane Smith") true;
          assert_bool (Js.Re.test_ regex "Wololo") false);
      case "backreferencing" (fun () ->
          let regex = Js.Re.fromString "[bt]ear" in
          assert_bool (Js.Re.test_ regex "bear") true;
          assert_bool (Js.Re.test_ regex "tear") true;
          assert_bool (Js.Re.test_ regex "fear") false);
      case "http|s example" (fun () ->
          let regex =
            Js.Re.fromString "^[https?]+:\\/\\/((w{3}\\.)?[\\w+]+)\\.[\\w+]+$"
          in
          assert_bool (Js.Re.test_ regex "https://www.example.com") true;
          assert_bool (Js.Re.test_ regex "http://example.com") true;
          assert_bool (Js.Re.test_ regex "https://example") false);
      case "index" (fun () ->
          let regex = Js.Re.fromString "zbar" in
          match Js.Re.exec_ regex "foobarbazbar" with
          | Some res -> assert_int (Js.Re.index res) 8
          | None -> Alcotest.fail "should have matched");
      case "lastIndex" (fun () ->
          let regex = Js.Re.fromStringWithFlags ~flags:"g" "y" in
          Js.Re.setLastIndex regex 3;
          match Js.Re.exec_ regex "xyzzy" with
          | Some res ->
              assert_int (Js.Re.index res) 4;
              assert_int (Js.Re.lastIndex regex) 3
          | None -> Alcotest.fail "should have matched");
      case "input" (fun () ->
          let regex = Js.Re.fromString "zbar" in
          match Js.Re.exec_ regex "foobarbazbar" with
          | Some res -> assert_string (Js.Re.input res) "foobarbazbar"
          | None -> Alcotest.fail "should have matched");
    ] )

let string2_tests =
  ( "Js.String2",
    [
      case "make" (fun () ->
          (* assert_string (make 3.5) "3.5"; *)
          (* assert_string (make [| 1; 2; 3 |]) "1,2,3"); *)
          ());
      case "length" (fun () -> assert_int (Js.String2.length "abcd") 4);
      case "get" (fun () ->
          assert_string (Js.String2.get "Reason" 0) "R";
          assert_string (Js.String2.get "Reason" 4) "o"
          (* assert_string (Js.String2.get {js|Rẽasöń|js} 5) {js|ń|js}; *));
      case "fromCharCode" (fun () ->
          assert_string (Js.String2.fromCharCode 65) "A";
          (* assert_string (Js.String2.fromCharCode 0x3c8) {js|ψ|js}; *)
          (* assert_string (Js.String2.fromCharCode 0xd55c) {js|한|js} *)
          (* assert_string (Js.String2.fromCharCode -64568) {js|ψ|js}; *)
          ());
      case "fromCharCodeMany" (fun () ->
          (* fromCharCodeMany([|0xd55c, 0xae00, 33|]) = {js|한글!|js} *)
          ());
      case "fromCodePoint" (fun () ->
          assert_string (Js.String2.fromCodePoint 65) "A"
          (* assert_string (Js.String2.fromCodePoint 0x3c8) {js|ψ|js}; *)
          (* assert_string (Js.String2.fromCodePoint 0xd55c) {js|한|js} *)
          (* assert_string (Js.String2.fromCodePoint 0x1f63a) {js|😺|js} *));
      case "fromCodePointMany" (fun () ->
          (* assert_string
             (Js.String2.fromCodePointMany [| 0xd55c; 0xae00; 0x1f63a |])
             {js|한글😺|js} *)
          ());
      case "charAt" (fun () ->
          assert_string (Js.String2.charAt "Reason" 0) "R";
          assert_string (Js.String2.charAt "Reason" 12) ""
          (* assert_string (Js.String2.charAt {js|Rẽasöń|js} 5) {js|ń|js} *));
      case "charCodeAt" (fun () ->
          (* charCodeAt {js|😺|js} 0) 0xd83d *)
          assert_float (Js.String2.charCodeAt "lola" 1) 111.;
          assert_float (Js.String2.charCodeAt "lola" 0) 108.);
      case "codePointAt" (fun () ->
          assert_option Alcotest.int
            (Js.String2.codePointAt "lola" 1)
            (Some 111);
          (* assert_option Alcotest.int (Js.String2.codePointAt {js|¿😺?|js} 1) (Some 0x1f63a); *)
          assert_option Alcotest.int (Js.String2.codePointAt "abc" 5) None);
      case "concat" (fun () ->
          assert_string (Js.String2.concat "cow" "bell") "cowbell");
      case "concatMany" (fun () ->
          assert_string
            (Js.String2.concatMany "1st" [| "2nd"; "3rd"; "4th" |])
            "1st2nd3rd4th");
      case "endsWith" (fun () ->
          assert_bool (Js.String2.endsWith "ReScript" "Script") true;
          assert_bool (Js.String2.endsWith "ReShoes" "Script") false);
      case "endsWithFrom" (fun () ->
          assert_bool (Js.String2.endsWithFrom "abcd" "cd" 4) true;
          assert_bool (Js.String2.endsWithFrom "abcde" "cd" 3) false;
          (* assert_bool (Js.String2.endsWithFrom "abcde" "cde" 99) true; *)
          assert_bool (Js.String2.endsWithFrom "example.dat" "ple" 7) true);
      case "includes" (fun () ->
          assert_bool (Js.String2.includes "programmer" "gram") true;
          assert_bool (Js.String2.includes "programmer" "er") true;
          assert_bool (Js.String2.includes "programmer" "pro") true;
          assert_bool (Js.String2.includes "programmer" "xyz") false);
      case "includesFrom" (fun () ->
          assert_bool (Js.String2.includesFrom "programmer" "gram" 1) true;
          assert_bool (Js.String2.includesFrom "programmer" "gram" 4) false
          (* assert_bool (Js.String2.includesFrom {js|한|js} {js|대한민국|js} 1) true *));
      case "indexOf" (fun () ->
          assert_int (Js.String2.indexOf "bookseller" "ok") 2;
          assert_int (Js.String2.indexOf "bookseller" "sell") 4;
          assert_int (Js.String2.indexOf "beekeeper" "ee") 1;
          assert_int (Js.String2.indexOf "bookseller" "xyz") (-1));
      case "indexOfFrom" (fun () ->
          assert_int (Js.String2.indexOfFrom "bookseller" "ok" 1) 2;
          assert_int (Js.String2.indexOfFrom "bookseller" "sell" 2) 4;
          assert_int (Js.String2.indexOfFrom "bookseller" "sell" 5) (-1);
          assert_int (Js.String2.indexOf "bookseller" "xyz") (-1));
      case "lastIndexOf" (fun () ->
          assert_int (Js.String2.lastIndexOf "bookseller" "ok") 2;
          assert_int (Js.String2.lastIndexOf "beekeeper" "ee") 4;
          assert_int (Js.String2.lastIndexOf "abcdefg" "xyz") (-1));
      case "lastIndexOfFrom" (fun () ->
          (* assert_int (Js.String2.lastIndexOfFrom "bookseller" "ok" 6) 2;
             assert_int (Js.String2.lastIndexOfFrom "beekeeper" "ee" 8) 4;
             assert_int (Js.String2.lastIndexOfFrom "beekeeper" "ee" 3) 1;
             assert_int (Js.String2.lastIndexOfFrom "abcdefg" "xyz" 4) (-1) *)
          ());
      (* case "localeCompare" (fun () ->
           localeCompare "ant" "zebra" > 0.0
             localeCompare "zebra" "ant" < 0.0
             localeCompare "cat" "cat" = 0.0
             localeCompare "cat" "CAT" > 0.0
          ());
      *)
      (* case "match" (fun () ->
         assert_string_array
               (match_ [%bs.re "/b[aeiou]t/"] "The better bats"
               |> Stdlib.Option.get)
               [| "bet" |]; *)
      (* match_ [%re "/b[aeiou]t/"] "The better bats" = Some [|"bet"|]
            match_ [%re "/b[aeiou]t/g"] "The better bats" = Some [|"bet";"bat"|]
            match_ [%re "/(\\d+)-(\\d+)-(\\d+)/"] "Today is 2018-04-05." =
              Some [|"2018-04-05"; "2018"; "04"; "05"|]
            match_ [%re "/b[aeiou]g/"] "The large container." = None
         ());
      *)
      case "repeat" (fun () ->
          assert_string (Js.String2.repeat "ha" 3) "hahaha";
          assert_string (Js.String2.repeat "empty" 0) "");
      case "replace" (fun () ->
          (* assert_string (Js.String2.replace "old" "new" "old string") "new string";
             assert_string
               (replace "the" "this" "the cat and the dog")
               "this cat and the dog" *)
          ());
      case "replaceByRe" (fun () ->
          (* assert_string
               (replaceByRe [%re "/[aeiou]/g"] "x" "vowels be gone")
               "vxwxls bx gxnx";
             assert_string
               (replaceByRe [%re "/(\\w+) (\\w+)/"] "$2, $1" "Juan Fulano")
               "Fulano, Juan" *)
          ());
      case "unsafeReplaceBy0" (fun () ->
          (* let str = "beautiful vowels" in
             let re = [%re "/[aeiou]/g"] in
             let matchFn matchPart offset wholeString =
               Js.String.toUpperCase matchPart
             in

             let replaced = Js.String.unsafeReplaceBy0 re matchFn str in

             assert_string replaced "bEAUtifUl vOwEls" *)
          ());
      case "unsafeReplaceBy1" (fun () ->
          (* let str = "increment 23" in
             let re = [%re "/increment (\\d+)/g"] in
             let matchFn matchPart p1 offset wholeString =
               wholeString ^ " is " ^ string_of_int (int_of_string p1 + 1)
             in

             let replaced = Js.String.unsafeReplaceBy1 re matchFn str in
             assert_string replaced "increment 23 is 24" *)
          ());
      case "unsafeReplaceBy2" (fun () ->
          (* let str = "7 times 6" in
             let re = [%re "/(\\d+) times (\\d+)/"] in
             let matchFn matchPart p1 p2 offset wholeString =
               string_of_int (int_of_string p1 * int_of_string p2)
             in

             let replaced = Js.String.unsafeReplaceBy2 re matchFn str in
             assert_string replaced "42" *)
          ());
      case "search" (fun () ->
          (* assert_int (Js.String2.search [%re "/\\d+/"] "testing 1 2 3") 8;
             assert_int (Js.String2.search [%re "/\\d+/"] "no numbers") (-1) *)
          ());
      case "slice" (fun () ->
          assert_string (Js.String2.slice ~from:2 ~to_:5 "abcdefg") "cde";
          assert_string (Js.String2.slice ~from:2 ~to_:9 "abcdefg") "cdefg";
          (* assert_string (Js.String2.slice ~from:(-4) ~to_:(-2) "abcdefg") "de"; *)
          assert_string (Js.String2.slice ~from:5 ~to_:1 "abcdefg") "");
      case "sliceToEnd" (fun () ->
          assert_string (Js.String2.sliceToEnd ~from:4 "abcdefg") "efg";
          (* assert_string (Js.String2.sliceToEnd ~from:(-2) "abcdefg") "fg"; *)
          assert_string (Js.String2.sliceToEnd ~from:7 "abcdefg") "");
      case "split" (fun () ->
          (* assert_string_array (split "-" "2018-01-02") [| "2018"; "01"; "02" |];
             assert_string_array (split "," "a,b,,c") [| "a"; "b"; ""; "c" |];
             assert_string_array
               (split "::" "good::bad as great::awful")
               [| "good"; "bad as great"; "awful" |];
             assert_string_array
               (split ";" "has-no-delimiter")
               [| "has-no-delimiter" |] *)
          ());
      case "splitAtMost" (fun () ->
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
      case "splitByRe" (fun () ->
          (* assert_string_array (splitByRe [%re "/\\s*[,;]\\s*/"] "art; bed , cog ;dad") [| Some "art"; Some "bed"; Some "cog"; Some "dad" |];
             assert_string_array (splitByRe [%re "/[,;]/"] "has:no:match" [| Some "has:no:match" |] splitByRe [%re "/(#)(:)?/"] "a#b#:c") [|Some "a"; Some "#"; None; Some "b"; Some "#"; Some ":"; Some "c"; |]; *)
          ());
      case "splitByReAtMost" (fun () ->
          (* assert_string_array
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
               [| Some "a"; Some "#"; None |] *)
          ());
      case "startsWith" (fun () ->
          assert_bool (Js.String2.startsWith "ReScript" "Re") true;
          assert_bool (Js.String2.startsWith "ReScript" "") true;
          assert_bool (Js.String2.startsWith "JavaScript" "Re") false);
      case "startsWithFrom" (fun () ->
          (* assert_bool (Js.String2.startsWithFrom "cri" 3 "ReScript") true;
             assert_bool (Js.String2.startsWithFrom "" 3 "ReScript") true;
             assert_bool (Js.String2.startsWithFrom "Re" 2 "JavaScript") false *)
          ());
      case "substr" (fun () ->
          assert_string (Js.String2.substr ~from:3 "abcdefghij") "defghij";
          (* assert_string (Js.String2.substr ~from:(-3) "abcdefghij") "hij"; *)
          assert_string (Js.String2.substr ~from:12 "abcdefghij") "");
      case "substrAtMost" (fun () ->
          (* assert_string (Js.String2.substrAtMost ~from:3 ~length:4 "abcdefghij") "defghij"; *)
          (* assert_string (Js.String2.substrAtMost ~from:(-3) ~length:4 "abcdefghij") "hij"; *)
          (* assert_string (Js.String2.substrAtMost ~from:12 ~length:2 "abcdefghij") "" *)
          ());
      case "substring" (fun () ->
          assert_string (Js.String2.substring ~from:3 ~to_:6 "playground") "ygr";
          assert_string (Js.String2.substring ~from:6 ~to_:3 "playground") "ygr";
          assert_string
            (Js.String2.substring ~from:4 ~to_:12 "playground")
            "ground");
      case "substringToEnd" (fun () ->
          assert_string
            (Js.String2.substringToEnd ~from:4 "playground")
            "ground";
          assert_string
            (Js.String2.substringToEnd ~from:(-3) "playground")
            "playground";
          assert_string (Js.String2.substringToEnd ~from:12 "playground") "");
      case "toLowerCase" (fun () ->
          assert_string (Js.String2.toLowerCase "ABC") "abc"
          (* assert_string (Js.String2.toLowerCase {js|ΣΠ|js}) {js|σπ|js}; *)
          (* assert_string (Js.String2.toLowerCase {js|ΠΣ|js}) {js|πς|js} *));
      case "toUpperCase" (fun () ->
          assert_string (Js.String2.toUpperCase "abc") "ABC"
          (* assert_string (Js.String2.toUpperCase {js|Straße|js}) {js|STRASSE|js} *)
          (* assert_string (Js.String2.toLowerCase {js|πς|js}) {js|ΠΣ|js} *));
      case "trim" (fun () ->
          assert_string (Js.String2.trim "   abc def   ") "abc def";
          assert_string (Js.String2.trim "\n\r\t abc def \n\n\t\r ") "abc def");
      case "anchor" (fun () ->
          (* assert_string
             (anchor "page1" "Page One")
             "<a name=\"page1\">Page One</a>" *)
          ());
      case "link" (fun () ->
          (* assert_string
             (link "page2.html" "Go to page two")
             "<a href=\"page2.html\">Go to page two</a>" *)
          ());
    ] )

let () = Alcotest.run "Js tests" [ string2_tests; re_tests ]
