let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let assert_option x left right =
  Alcotest.check (Alcotest.option x) "should be equal" right left

let assert_array ty left right =
  Alcotest.check (Alcotest.array ty) "should be equal" right left

let assert_string_array = assert_array Alcotest.string
let assert_array_int = assert_array Alcotest.int

let assert_dict_entries type_ left right =
  Alcotest.check
    (Alcotest.array (Alcotest.pair Alcotest.string type_))
    "should be equal" right left

let assert_int_dict_entries = assert_dict_entries Alcotest.int
let assert_string_dict_entries = assert_dict_entries Alcotest.string
let assert_option_int = assert_option Alcotest.int
(* let assert_option_string = assert_option Alcotest.string *)

let assert_int left right =
  Alcotest.check Alcotest.int "should be equal" right left

let assert_float left right =
  Alcotest.check (Alcotest.float 2.) "should be equal" right left

let assert_bool left right =
  Alcotest.check Alcotest.bool "should be equal" right left

let case title (fn : unit -> unit) = Alcotest_lwt.test_case_sync title `Quick fn
let case_async title fn = Alcotest_lwt.test_case title `Quick fn

let re_tests =
  ( "Js.Re",
    [
      case "captures" (fun () ->
          let abc_regex = Js.Re.fromString "abc" in
          let result = Js.Re.exec_ abc_regex "abcdefabcdef" |> Option.get in
          let matches = Js.Re.captures result |> Array.map Option.get in
          assert_string_array matches [| "abc" |]);
      case "exec" (fun () ->
          let regex = Js.Re.fromString ".ats" in
          let input = "cats and bats" in
          let regex_and_capture =
            Js.Re.exec_ regex input |> Option.get |> Js.Re.captures
            |> Array.map Option.get
          in
          assert_string_array regex_and_capture [| "cats" |];
          assert_string_array regex_and_capture [| "cats" |];
          assert_string_array regex_and_capture [| "cats" |]);
      case "exec with global" (fun () ->
          let regex = Js.Re.fromStringWithFlags ~flags:"g" ".ats" in
          let input = "cats and bats and mats" in
          assert_bool (Js.Re.global regex) true;
          assert_string_array
            (Js.Re.exec_ regex input |> Option.get |> Js.Re.captures
           |> Array.map Option.get)
            [| "cats" |];
          assert_string_array
            (Js.Re.exec_ regex input |> Option.get |> Js.Re.captures
           |> Array.map Option.get)
            [| "bats" |];
          assert_string_array
            (Js.Re.exec_ regex input |> Option.get |> Js.Re.captures
           |> Array.map Option.get)
            [| "mats" |]);
      case "modifier: end ($)" (fun () ->
          let regex = Js.Re.fromString "cat$" in
          assert_bool (Js.Re.test_ regex "The cat and mouse") false;
          assert_bool (Js.Re.test_ regex "The mouse and cat") true);
      case "modifier: more than one (+)" (fun () ->
          let regex = Js.Re.fromStringWithFlags ~flags:"i" "boo+(hoo+)+" in
          assert_bool (Js.Re.test_ regex "Boohoooohoohooo") true);
      case "global (g) and caseless (i)" (fun () ->
          let regex = Js.Re.fromStringWithFlags ~flags:"gi" "Hello" in
          let result = Js.Re.exec_ regex "Hello gello! hello" |> Option.get in
          let matches = Js.Re.captures result |> Array.map Option.get in
          assert_string_array matches [| "Hello" |];
          let result = Js.Re.exec_ regex "Hello gello! hello" |> Option.get in
          let matches = Js.Re.captures result |> Array.map Option.get in
          assert_string_array matches [| "hello" |]);
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
              assert_int (Js.Re.lastIndex regex) 5
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
          assert_option_int (Js.String2.codePointAt "lola" 1) (Some 111);
          (* assert_option_int (Js.String2.codePointAt {js|¿😺?|js} 1) (Some 0x1f63a); *)
          assert_option_int (Js.String2.codePointAt "abc" 5) None);
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
      case "match" (fun () ->
          let unsafe_match r s = Js.String2.match_ r s |> Stdlib.Option.get in
          assert_string_array
            (unsafe_match "The better bats" [%re "/b[aeiou]t/"])
            [| "bet" |]);
      case "match" (fun () ->
          let unsafe_match s r =
            Js.String2.match_ r s |> Stdlib.Option.value ~default:[||]
          in
          assert_string_array
            (unsafe_match [%re "/b[aeiou]t/"] "The better bats")
            [| "bet" |];
          assert_string_array
            (unsafe_match [%re "/b[aeiou]t/g"] "The better bats")
            [| "bet"; "bat" |];
          assert_string_array
            (unsafe_match [%re "/(\\d+)-(\\d+)-(\\d+)/"] "Today is 2018-04-05.")
            [| "2018-04-05"; "2018"; "04"; "05" |];
          assert_string_array
            (unsafe_match [%re "/b[aeiou]g/"] "The large container.")
            [||]);
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
          assert_string (Js.String2.replaceByRe "david" [%re "/d/"] "x") "xavid"
          (* assert_string
             (Js.String2.replaceByRe [%re "/(\\w+) (\\w+)/"] "$2, $1"
                "Juan Fulano")
             "Fulano, Juan" *));
      case "replaceByRe with global" (fun () ->
          assert_string
            (Js.String2.replaceByRe "vowels be gone" [%re "/[aeiou]/g"] "x")
            "vxwxls bx gxnx");
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
          let unsafe_splitByRe r s =
            Js.String2.splitByRe r s |> Stdlib.Array.map Stdlib.Option.get
          in
          assert_string_array
            (unsafe_splitByRe "art; bed , cog ;dad" [%re "/\\s*[,;]\\s*/"])
            [| "art"; "bed"; "cog"; "dad" |];
          assert_string_array
            (unsafe_splitByRe "has:no:match" [%re "/[,;]/"])
            [| "has:no:match" |];
          assert_string_array
            (unsafe_splitByRe "a#b#c" [%re "/(#)(:)?/g"])
            [| "a"; "b"; "c" |]);
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

let array_tests =
  ( "Js.Array",
    [
      case "from" (fun () ->
          Alcotest.check_raises "Js.Array.from"
            (Js.Not_implemented
               "'Js.Array.from' is not implemented in native under \
                server-reason-react.js") (fun () -> Js.Array.from 3));
    ] )

let obj () = Js.Dict.fromList [ ("foo", 43); ("bar", 86) ]
let long_obj () = Js.Dict.fromList [ ("david", 99); ("foo", 43); ("bar", 86) ]

let obj_duplicated () =
  Js.Dict.fromList [ ("foo", 43); ("bar", 86); ("bar", 1) ]

let dict_tests =
  ( "Js.Dict",
    [
      case "empty" (fun _ ->
          assert_string_dict_entries (Js.Dict.entries (Js.Dict.empty ())) [||]);
      case "get" (fun _ ->
          assert_option_int (Js.Dict.get (obj ()) "foo") (Some 43));
      case "get from missing property" (fun _ ->
          assert_option_int (Js.Dict.get (obj ()) "baz") None);
      case "unsafe_get" (fun _ ->
          assert_int (Js.Dict.unsafeGet (obj ()) "foo") 43);
      case "set" (fun _ ->
          let o = Js.Dict.empty () in
          Js.Dict.set o "foo" 36;
          assert_option_int (Js.Dict.get o "foo") (Some 36));
      case "keys" (fun _ ->
          assert_string_array
            (Js.Dict.keys (long_obj ()))
            [| "bar"; "david"; "foo" |]);
      case "keys duplicated" (fun _ ->
          assert_string_array
            (Js.Dict.keys (obj_duplicated ()))
            [| "bar"; "bar"; "foo" |]);
      case "entries" (fun _ ->
          assert_int_dict_entries
            (Js.Dict.entries (obj ()))
            [| ("bar", 86); ("foo", 43) |]);
      case "values" (fun _ ->
          assert_array_int (Js.Dict.values (obj ())) [| 86; 43 |]);
      case "values duplicated" (fun _ ->
          assert_array_int (Js.Dict.values (obj_duplicated ())) [| 86; 1; 43 |]);
      case "fromList - []" (fun _ ->
          assert_int_dict_entries (Js.Dict.entries (Js.Dict.fromList [])) [||]);
      case "fromList" (fun _ ->
          assert_int_dict_entries
            (Js.Dict.entries (Js.Dict.fromList [ ("x", 23); ("y", 46) ]))
            [| ("x", 23); ("y", 46) |]);
      case "fromArray - []" (fun _ ->
          assert_int_dict_entries (Js.Dict.entries (Js.Dict.fromArray [||])) [||]);
      case "fromArray" (fun _ ->
          assert_int_dict_entries
            (Js.Dict.entries (Js.Dict.fromArray [| ("x", 23); ("y", 46) |]))
            [| ("x", 23); ("y", 46) |]);
      case "map" (fun _ ->
          let prices =
            Js.Dict.fromList [ ("pen", 1); ("book", 5); ("stapler", 7) ]
          in
          let discount price = price * 10 in
          let salePrices = Js.Dict.map discount prices in
          assert_int_dict_entries
            (Js.Dict.entries salePrices)
            [| ("book", 50); ("stapler", 70); ("pen", 10) |]);
    ] )

let promise_to_lwt (p : 'a Js.Promise.t) : 'a Lwt.t = Obj.magic p

let resolve _switch () =
  let value = "hi" in
  let resolved = Js.Promise.resolve value in
  resolved |> promise_to_lwt |> Lwt.map (assert_string value)

let all _switch () =
  let p0 = Js.Promise.make (fun ~resolve ~reject:_ -> resolve 5) in
  let p1 = Js.Promise.make (fun ~resolve ~reject:_ -> resolve 10) in
  let resolved = Js.Promise.all [| p0; p1 |] in
  resolved |> promise_to_lwt |> Lwt.map (assert_array_int [| 5; 10 |])

let set_timeout callback delay =
  let _ =
    Lwt.async (fun () ->
        let%lwt () = Lwt_unix.sleep delay in
        callback ();
        Lwt.return ())
  in
  ()

let all_async _switch () =
  let p0 =
    Js.Promise.make (fun ~resolve ~reject:_ ->
        set_timeout (fun () -> resolve 5) 0.5)
  in
  let p1 =
    Js.Promise.make (fun ~resolve ~reject:_ ->
        set_timeout (fun () -> resolve 99) 0.3)
  in
  let resolved = Js.Promise.all [| p0; p1 |] in
  resolved |> promise_to_lwt |> Lwt.map (assert_array_int [| 5; 99 |])

let race_async _switch () =
  let p0 =
    Js.Promise.make (fun ~resolve ~reject:_ ->
        set_timeout (fun () -> resolve "second") 0.5)
  in
  let p1 =
    Js.Promise.make (fun ~resolve ~reject:_ ->
        set_timeout (fun () -> resolve "first") 0.3)
  in
  let resolved = Js.Promise.race [| p0; p1 |] in
  resolved |> promise_to_lwt |> Lwt.map (assert_string "first")

let promise_tests =
  ( "Promise",
    [
      case_async "resolve" resolve;
      case_async "all" all;
      case_async "all_async" all_async;
      case_async "race_async" race_async;
    ] )

let float_tests =
  ( "Float",
    [
      case "string_of_float" (fun () ->
          assert_string (string_of_float 0.5) "0.5";
          assert_string (string_of_float 80.0) "80.";
          assert_string (string_of_float 80.) "80.";
          assert_string (Js.Float.toString 80.0) "80";
          assert_string (Js.Float.toString 80.1) "80.1";
          assert_string (string_of_float 80.0001) "80.0001";
          assert_string (Js.Float.toString 80.0001) "80.0001";
          assert_string (string_of_float 80.00000000001) "80.";
          assert_string (Js.Float.toString 80.00000000001) "80");
    ] )

let () =
  Alcotest_lwt.run "Js"
    [
      promise_tests;
      float_tests;
      string2_tests;
      re_tests;
      array_tests;
      dict_tests;
    ]
  |> Lwt_main.run
