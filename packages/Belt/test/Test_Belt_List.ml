let sum values =
  let total = ref 0 in
  Belt.List.forEach values (fun value -> total := !total + value);
  !total

let sum2 left right =
  let total = ref 0 in
  Belt.List.forEach2 left right (fun x y -> total := !total + x + y);
  !total

let mod2 value = value mod 2 = 0
let even_index _ index = index mod 2 = 0
let id value = value
let add left right = left + right
let succ value = value + 1
let length_10_id = Belt.List.makeBy 10 id
let length_8_id = Belt.List.makeBy 8 id

let suites =
  [
    ( "List",
      [
        test "makeBy get and map" (fun () ->
            let values = Belt.List.makeBy 5 (fun index -> index * index) in
            for index = 0 to 4 do
              assert_int (index * index) (Belt.List.getExn values index)
            done;
            assert_list Alcotest.int [ 1; 2; 5; 10; 17 ] (Belt.List.map values (fun value -> value + 1));
            assert_option Alcotest.int (Some 4) (Belt.List.getBy [ 1; 4; 3; 2 ] (fun value -> value mod 2 = 0));
            assert_option Alcotest.int None (Belt.List.getBy [ 1; 4; 3; 2 ] (fun value -> value mod 5 = 0)));
        test "flatten" (fun () ->
            assert_list Alcotest.int [ 1; 2; 3; 0; 1; 2; 3 ]
              (Belt.List.flatten [ [ 1 ]; [ 2 ]; [ 3 ]; []; Belt.List.makeBy 4 (fun index -> index) ]);
            assert_list Alcotest.int [] (Belt.List.flatten []);
            assert_list Alcotest.int [ 2; 1; 2 ] (Belt.List.flatten [ []; []; [ 2 ]; [ 1 ]; [ 2 ]; [] ]));
        test "concatMany" (fun () ->
            assert_list Alcotest.int [ 1; 2; 3; 0; 1; 2; 3 ]
              (Belt.List.concatMany [| [ 1 ]; [ 2 ]; [ 3 ]; []; Belt.List.makeBy 4 (fun index -> index) |]);
            assert_list Alcotest.int [] (Belt.List.concatMany [||]);
            assert_list Alcotest.int [ 2; 1; 2 ] (Belt.List.concatMany [| []; []; [ 2 ]; [ 1 ]; [ 2 ]; [] |]);
            assert_list Alcotest.int [ 2; 3; 1; 2 ] (Belt.List.concatMany [| []; []; [ 2; 3 ]; [ 1 ]; [ 2 ]; [] |]);
            assert_list Alcotest.int [ 1; 2; 3 ] (Belt.List.concatMany [| [ 1; 2; 3 ] |]));
        test "concat" (fun () ->
            assert_list Alcotest.int
              (Array.to_list (Array.append (inclusive_range 0 99) (inclusive_range 0 99)))
              (Belt.List.toArray
                 (Belt.List.concat
                    (Belt.List.makeBy 100 (fun index -> index))
                    (Belt.List.makeBy 100 (fun index -> index)))
              |> Array.to_list);
            assert_list Alcotest.int [ 1 ] (Belt.List.concat [ 1 ] []);
            assert_list Alcotest.int [ 1 ] (Belt.List.concat [] [ 1 ]));
        test "zip and zipBy" (fun () ->
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.int)
              [ (1, 3); (2, 4) ]
              (Belt.List.zip [ 1; 2; 3 ] [ 3; 4 ]);
            assert_list (Alcotest.pair Alcotest.int Alcotest.int) [] (Belt.List.zip [] [ 1 ]);
            assert_list (Alcotest.pair Alcotest.int Alcotest.int) [] (Belt.List.zip [] []);
            assert_list (Alcotest.pair Alcotest.int Alcotest.int) [] (Belt.List.zip [ 1; 2; 3 ] []);
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.int)
              [ (1, 2); (2, 3); (3, 4) ]
              (Belt.List.zip [ 1; 2; 3 ] [ 2; 3; 4 ]);
            let zip_by_add left right = Belt.List.zipBy left right add in
            let doubled = Belt.List.makeBy 10 (fun index -> index * 2) in
            assert_list Alcotest.int doubled (zip_by_add length_10_id length_10_id);
            assert_list Alcotest.int [] (zip_by_add [] [ 1 ]);
            assert_list Alcotest.int [] (zip_by_add [ 1 ] []);
            assert_list Alcotest.int [] (zip_by_add [] []);
            assert_list Alcotest.int
              (Belt.List.concat (Belt.List.map length_8_id (fun value -> value * 2)) [ 16; 18 ])
              (zip_by_add length_10_id length_10_id);
            assert_list Alcotest.int
              (Belt.List.mapWithIndex length_8_id (fun index value -> index + value))
              (zip_by_add length_10_id length_8_id);
            assert_list Alcotest.int
              (Belt.List.map length_10_id (fun value -> value * 2))
              (Belt.List.reverse (Belt.List.mapReverse2 length_10_id length_10_id add));
            let reversed = Belt.List.reverse (Belt.List.mapReverse2 length_8_id length_10_id add) in
            assert_int 8 (Belt.List.length reversed);
            assert_list Alcotest.int (Belt.List.zipBy length_10_id length_8_id add) reversed;
            assert_list Alcotest.int [ 4; 2 ]
              (Belt.List.mapReverse2 [ 1; 2; 3 ] [ 1; 2 ] (fun left right -> left + right)));
        test "partition" (fun () ->
            assert_pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int)
              ([ 2; 2; 4 ], [ 1; 3; 3 ])
              (Belt.List.partition [ 1; 2; 3; 2; 3; 4 ] mod2);
            assert_pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int)
              ([ 2; 2; 2; 4 ], [])
              (Belt.List.partition [ 2; 2; 2; 4 ] mod2);
            assert_pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int)
              ([], [ 2; 2; 2; 4 ])
              (Belt.List.partition [ 2; 2; 2; 4 ] (fun value -> not (mod2 value)));
            assert_pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int) ([], []) (Belt.List.partition [] mod2));
        test "unzip" (fun () ->
            assert_pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int) ([], []) (Belt.List.unzip []);
            assert_pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int) ([ 1 ], [ 2 ])
              (Belt.List.unzip [ (1, 2) ]);
            assert_pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int)
              ([ 1; 3 ], [ 2; 4 ])
              (Belt.List.unzip [ (1, 2); (3, 4) ]));
        test "keep and keepWithIndex" (fun () ->
            assert_list Alcotest.int [ 2; 4 ] (Belt.List.keep [ 1; 2; 3; 4 ] mod2);
            assert_list Alcotest.int [] (Belt.List.keep [ 1; 3; 41 ] mod2);
            assert_list Alcotest.int [] (Belt.List.keep [] mod2);
            assert_list Alcotest.int [ 2; 2; 2; 4; 6 ] (Belt.List.keep [ 2; 2; 2; 4; 6 ] mod2);
            assert_list Alcotest.int [] (Belt.List.keepWithIndex [] even_index);
            assert_list Alcotest.int [ 1; 3 ] (Belt.List.keepWithIndex [ 1; 2; 3; 4 ] even_index);
            assert_list Alcotest.int [ 0; 2; 4; 6 ] (Belt.List.keepWithIndex [ 0; 1; 2; 3; 4; 5; 6; 7 ] even_index));
        test "map" (fun () ->
            assert_list Alcotest.int [ 0; 2; 4; 6; 8 ] (Belt.List.map (Belt.List.makeBy 5 id) (fun value -> value * 2));
            assert_list Alcotest.int [] (Belt.List.map [] id);
            assert_list Alcotest.int [ -1 ] (Belt.List.map [ 1 ] (fun value -> -value)));
        test "take drop and splitAt" (fun () ->
            assert_option (Alcotest.list Alcotest.int) (Some [ 1; 2 ]) (Belt.List.take [ 1; 2; 3 ] 2);
            assert_option (Alcotest.list Alcotest.int) None (Belt.List.take [] 1);
            assert_option (Alcotest.list Alcotest.int) None (Belt.List.take [ 1; 2 ] 3);
            assert_option (Alcotest.list Alcotest.int) (Some [ 1; 2 ]) (Belt.List.take [ 1; 2 ] 2);
            assert_option (Alcotest.list Alcotest.int) (Some length_8_id) (Belt.List.take length_10_id 8);
            assert_option (Alcotest.list Alcotest.int) (Some []) (Belt.List.take length_10_id 0);
            assert_option (Alcotest.list Alcotest.int) None (Belt.List.take length_8_id (-2));
            assert_option (Alcotest.list Alcotest.int) (Some []) (Belt.List.drop length_10_id 10);
            assert_option (Alcotest.list Alcotest.int) (Some [ 8; 9 ]) (Belt.List.drop length_10_id 8);
            assert_option (Alcotest.list Alcotest.int) (Some length_10_id) (Belt.List.drop length_10_id 0);
            assert_option (Alcotest.list Alcotest.int) None (Belt.List.drop length_8_id (-1));
            let values = Belt.List.makeBy 5 id in
            assert_option
              (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int))
              None (Belt.List.splitAt [] 1);
            assert_option
              (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int))
              None (Belt.List.splitAt values 6);
            assert_option
              (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int))
              (Some (values, []))
              (Belt.List.splitAt values 5);
            assert_option
              (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int))
              (Some ([ 0; 1; 2; 3 ], [ 4 ]))
              (Belt.List.splitAt values 4);
            assert_option
              (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int))
              (Some ([ 0; 1; 2 ], [ 3; 4 ]))
              (Belt.List.splitAt values 3);
            assert_option
              (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int))
              (Some ([ 0; 1 ], [ 2; 3; 4 ]))
              (Belt.List.splitAt values 2);
            assert_option
              (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int))
              (Some ([ 0 ], [ 1; 2; 3; 4 ]))
              (Belt.List.splitAt values 1);
            assert_option
              (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int))
              (Some ([], values))
              (Belt.List.splitAt values 0);
            assert_option
              (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int))
              None (Belt.List.splitAt values (-1)));
        test "association helpers" (fun () ->
            let eq_int left right = (left : int) = right in
            assert_bool true (Belt.List.hasAssoc [ (1, "1"); (2, "2"); (3, "3") ] 2 ( = ));
            assert_bool false (Belt.List.hasAssoc [ (1, "1"); (2, "2"); (3, "3") ] 4 ( = ));
            assert_bool true
              (Belt.List.hasAssoc [ (1, "1"); (2, "2"); (3, "3") ] 4 (fun left right -> left + 1 = right));
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (1, "1"); (2, "2") ]
              (Belt.List.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 3 ( = ));
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (2, "2"); (3, "3") ]
              (Belt.List.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 1 ( = ));
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (1, "1"); (3, "3") ]
              (Belt.List.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 2 ( = ));
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (1, "1"); (2, "2"); (3, "3") ]
              (Belt.List.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 0 ( = ));
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (1, "1"); (2, "2") ]
              (Belt.List.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 3 eq_int);
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (2, "2"); (3, "3") ]
              (Belt.List.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 1 eq_int);
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (1, "1"); (3, "3") ]
              (Belt.List.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 2 eq_int);
            assert_list (Alcotest.pair Alcotest.int Alcotest.string) [] (Belt.List.removeAssoc [] 2 eq_int);
            let values = [ (1, "1"); (2, "2"); (3, "3") ] in
            let untouched = Belt.List.removeAssoc values 0 eq_int in
            assert_same_physical values untouched;
            let updated = Belt.List.setAssoc values 2 "22" ( = ) in
            assert_list (Alcotest.pair Alcotest.int Alcotest.string) [ (1, "1"); (2, "22"); (3, "3") ] updated;
            let added = Belt.List.setAssoc updated 22 "2" ( = ) in
            assert_list (Alcotest.pair Alcotest.int Alcotest.string) ((22, "2") :: updated) added;
            assert_same_physical updated (Belt.List.tailExn added);
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (1, "a"); (2, "x"); (3, "c") ]
              (Belt.List.setAssoc [ (1, "a"); (2, "b"); (3, "c") ] 2 "x" ( = ));
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (2, "2"); (1, "a"); (3, "c") ]
              (Belt.List.setAssoc [ (1, "a"); (3, "c") ] 2 "2" ( = ));
            assert_list (Alcotest.pair Alcotest.int Alcotest.string) [ (1, "1") ] (Belt.List.setAssoc [] 1 "1" ( = ));
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (1, "1") ]
              (Belt.List.setAssoc [ (1, "2") ] 1 "1" ( = ));
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (0, "0"); (1, "1") ]
              (Belt.List.setAssoc [ (0, "0"); (1, "2") ] 1 "1" ( = ));
            assert_option Alcotest.string (Some "b") (Belt.List.getAssoc [ (1, "a"); (2, "b"); (3, "c") ] 2 ( = ));
            assert_option Alcotest.string None (Belt.List.getAssoc [ (1, "a"); (2, "b"); (3, "c") ] 4 ( = )));
        test "head tail and access" (fun () ->
            assert_pair (Alcotest.option Alcotest.int)
              (Alcotest.option (Alcotest.list Alcotest.int))
              (Some 0, Belt.List.drop length_10_id 1)
              (Belt.List.head length_10_id, Belt.List.tail length_10_id);
            assert_option Alcotest.int None (Belt.List.head []);
            assert_raises_any (fun () -> ignore (Belt.List.headExn []));
            assert_raises_any (fun () -> ignore (Belt.List.tailExn []));
            assert_raises_any (fun () -> ignore (Belt.List.getExn [ 0; 1 ] (-1)));
            assert_raises_any (fun () -> ignore (Belt.List.getExn [ 0; 1 ] 2));
            assert_list Alcotest.int [ 0; 1 ] (Belt.List.map [ 0; 1 ] (fun index -> Belt.List.getExn [ 0; 1 ] index));
            assert_int 1 (Belt.List.headExn [ 1 ]);
            assert_list Alcotest.int [] (Belt.List.tailExn [ 1 ]);
            Belt.List.forEachWithIndex length_10_id (fun index value ->
                assert_option Alcotest.int (Some value) (Belt.List.get length_10_id index));
            assert_option (Alcotest.list Alcotest.int) None (Belt.List.tail []);
            assert_option (Alcotest.list Alcotest.int) None (Belt.List.drop [] 3);
            assert_list Alcotest.int [] (Belt.List.mapWithIndex [] (fun index value -> index + value));
            assert_option Alcotest.int None (Belt.List.get length_10_id (-1));
            assert_option Alcotest.int None (Belt.List.get length_10_id 12);
            assert_int 0 (sum []);
            assert_int 45 (sum length_10_id);
            assert_list Alcotest.int [] (Belt.List.makeBy 0 id);
            assert_list Alcotest.int length_10_id (Belt.List.reverse (Belt.List.reverse length_10_id));
            assert_list Alcotest.int length_8_id (Belt.List.reverse (Belt.List.reverse length_8_id));
            assert_list Alcotest.int [] (Belt.List.reverse []);
            assert_list Alcotest.int (Belt.List.map length_10_id succ)
              (Belt.List.reverse (Belt.List.mapReverse length_10_id succ)));
        test "reductions" (fun () ->
            assert_int 45 (Belt.List.reduce length_10_id 0 add);
            assert_int 45 (Belt.List.reduceReverse length_10_id 0 add);
            assert_int (9999 * 5000) (Belt.List.reduceReverse (Belt.List.makeBy 10_000 (fun index -> index)) 0 ( + ));
            assert_int 90 (sum2 length_10_id length_10_id);
            assert_int 56 (sum2 length_8_id length_10_id);
            assert_int 56 (sum2 length_10_id length_8_id);
            assert_int 56 (Belt.List.reduce2 length_10_id length_8_id 0 (fun acc left right -> acc + left + right));
            assert_int 18 (Belt.List.reduce2 [ 1; 2; 3 ] [ 2; 4; 6 ] 0 (fun acc left right -> acc + left + right));
            assert_int 56
              (Belt.List.reduceReverse2 length_10_id length_8_id 0 (fun acc left right -> acc + left + right));
            assert_int 90
              (Belt.List.reduceReverse2 length_10_id length_10_id 0 (fun acc left right -> acc + left + right));
            assert_int 6 (Belt.List.reduceReverse2 [ 1; 2; 3 ] [ 1; 2 ] 0 (fun acc left right -> acc + left + right));
            assert_int 10 (Belt.List.reduceReverse [ 1; 2; 3; 4 ] 0 ( + ));
            assert_int 0 (Belt.List.reduceReverse [ 1; 2; 3; 4 ] 10 ( - ));
            assert_list Alcotest.int [ 1; 2; 3; 4 ] (Belt.List.reduceReverse [ 1; 2; 3; 4 ] [] Belt.List.add);
            assert_int 10 (Belt.List.reduce [ 1; 2; 3; 4 ] 0 ( + ));
            assert_int 0 (Belt.List.reduce [ 1; 2; 3; 4 ] 10 ( - ));
            assert_list Alcotest.int [ 4; 3; 2; 1 ] (Belt.List.reduce [ 1; 2; 3; 4 ] [] Belt.List.add);
            assert_int 16 (Belt.List.reduceWithIndex [ 1; 2; 3; 4 ] 0 (fun acc value index -> acc + value + index));
            assert_int 6 (Belt.List.reduceReverse2 [ 1; 2; 3 ] [ 1; 2 ] 0 (fun acc left right -> acc + left + right));
            let values = Belt.List.makeBy 10_000 (fun index -> index) in
            assert_int
              ((9999 * 10_000) - 9999)
              (Belt.List.reduceReverse2 values (0 :: values) 0 (fun acc left right -> acc + left + right)));
        test "predicates and comparison" (fun () ->
            assert_bool true (Belt.List.every [ 2; 4; 6 ] mod2);
            assert_bool false (Belt.List.every [ 1 ] mod2);
            assert_bool true (Belt.List.every [] mod2);
            assert_bool true (Belt.List.some [ 1; 2; 5 ] mod2);
            assert_bool false (Belt.List.some [ 1; 3; 5 ] mod2);
            assert_bool false (Belt.List.some [] mod2);
            assert_bool true (Belt.List.has [ 1; 2; 3 ] "2" (fun value text -> string_of_int value = text));
            assert_bool false (Belt.List.has [ 1; 2; 3 ] "0" (fun value text -> string_of_int value = text));
            assert_bool true (Belt.List.every2 [] [ 1 ] (fun left right -> left > right));
            assert_bool true (Belt.List.every2 [ 2; 3 ] [ 1 ] (fun left right -> left > right));
            assert_bool true (Belt.List.every2 [ 2 ] [ 1 ] (fun left right -> left > right));
            assert_bool false (Belt.List.every2 [ 2; 3 ] [ 1; 4 ] (fun left right -> left > right));
            assert_bool true (Belt.List.every2 [ 2; 3 ] [ 1; 0 ] (fun left right -> left > right));
            assert_bool false (Belt.List.some2 [] [ 1 ] (fun left right -> left > right));
            assert_bool true (Belt.List.some2 [ 2; 3 ] [ 1 ] (fun left right -> left > right));
            assert_bool true (Belt.List.some2 [ 2; 3 ] [ 1; 4 ] (fun left right -> left > right));
            assert_bool false (Belt.List.some2 [ 0; 3 ] [ 1; 4 ] (fun left right -> left > right));
            assert_bool true (Belt.List.some2 [ 0; 3 ] [ 3; 2 ] (fun left right -> left > right));
            assert_bool false (Belt.List.some2 [ 1; 2; 3 ] [ -1; -2 ] (fun left right -> left = right));
            assert_list Alcotest.int [ 2; 3 ] (Belt.List.add (Belt.List.add [] 3) 2);
            assert_bool true (Belt.List.cmp [ 1; 2; 3 ] [ 0; 1; 2; 3 ] compare > 0);
            assert_bool true (Belt.List.cmp [ 1; 2; 3; 4 ] [ 1; 2; 3 ] compare > 0);
            assert_bool true (Belt.List.cmp [ 1; 2; 3 ] [ 1; 2; 3; 4 ] compare < 0);
            assert_bool true (Belt.List.cmp [ 1; 2; 3 ] [ 0; 1; 2 ] compare > 0);
            assert_bool true (Belt.List.cmp [ 1; 2; 3 ] [ 1; 2; 3 ] compare = 0);
            assert_bool true (Belt.List.cmp [ 1; 2; 4 ] [ 1; 2; 3 ] compare > 0);
            assert_bool true (Belt.List.cmpByLength [] [] = 0);
            assert_bool true (Belt.List.cmpByLength [ 1 ] [] > 0);
            assert_bool true (Belt.List.cmpByLength [] [ 1 ] < 0);
            assert_bool true (Belt.List.cmpByLength [ 1; 2 ] [ 1 ] > 0);
            assert_bool true (Belt.List.cmpByLength [ 1 ] [ 1; 2 ] < 0);
            assert_bool true (Belt.List.cmpByLength [ 1; 3 ] [ 1; 2 ] = 0));
        test "make sort eq and keepMap" (fun () ->
            List.iter
              (fun length -> assert_list Alcotest.int (Belt.List.makeBy length (fun _ -> 3)) (Belt.List.make length 3))
              [ 0; 1; 2; 3 ];
            let cmp left right = left - right in
            assert_list Alcotest.int [ 2; 3; 4; 5 ] (Belt.List.sort [ 5; 4; 3; 2 ] cmp);
            assert_list Alcotest.int [ 1; 3; 3; 9; 37 ] (Belt.List.sort [ 3; 9; 37; 3; 1 ] cmp);
            assert_bool true (not (Belt.List.eq [ 1; 2; 3 ] [ 1; 2 ] ( = )));
            assert_bool true (Belt.List.eq [ 1; 2; 3 ] [ 1; 2; 3 ] ( = ));
            assert_bool true (not (Belt.List.eq [ 1; 2; 3 ] [ 1; 2; 4 ] ( = )));
            assert_bool true (not (Belt.List.eq [ 1; 2; 3 ] [ 1; 2; 3; 4 ] ( = )));
            let values = Belt.List.makeBy 20 (fun index -> index) in
            assert_list Alcotest.int [ 1; 8; 15 ]
              (Belt.List.keepMap values (fun value -> if value mod 7 = 0 then Some (value + 1) else None));
            assert_list Alcotest.int [ -2; -4 ]
              (Belt.List.keepMap [ 1; 2; 3; 4 ] (fun value -> if value mod 2 = 0 then Some (-value) else None));
            assert_list Alcotest.int []
              (Belt.List.keepMap [ 1; 2; 3; 4 ] (fun value -> if value mod 5 = 0 then Some value else None)));
      ] );
  ]
