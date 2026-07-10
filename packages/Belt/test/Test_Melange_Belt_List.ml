(* Ported from melange/jscomp/test/bs_list_test.ml *)

module N = Belt.List
module A = Belt.Array

let sum xs =
  let v = ref 0 in
  N.forEach xs (fun x -> v := !v + x);
  !v

let sum2 xs ys =
  let v = ref 0 in
  N.forEach2 xs ys (fun x y -> v := !v + x + y);
  !v

let mod2 x = x mod 2 = 0
let evenIndex _x i = i mod 2 = 0
let id : int -> int = fun x -> x
let add a b = a + b
let succx x = x + 1
let length_10_id = N.makeBy 10 id
let length_8_id = N.makeBy 8 id
let assert_int_list expected actual = assert_list Alcotest.int expected actual
let int_string_pair = Alcotest.pair Alcotest.int Alcotest.string

let suites =
  [
    ( "Melange.Belt.List",
      [
        test "makeBy, getExn, map and getBy" (fun () ->
            let u = N.makeBy 5 (fun i -> i * i) in
            for i = 0 to 4 do
              assert_int (i * i) (N.getExn u i)
            done;
            assert_int_list [ 1; 2; 5; 10; 17 ] (N.map u (fun i -> i + 1));
            assert_option Alcotest.int (Some 4) (N.getBy [ 1; 4; 3; 2 ] (fun x -> x mod 2 = 0));
            assert_option Alcotest.int None (N.getBy [ 1; 4; 3; 2 ] (fun x -> x mod 5 = 0)));
        test "flatten" (fun () ->
            assert_int_list [ 1; 2; 3; 0; 1; 2; 3 ] (N.flatten [ [ 1 ]; [ 2 ]; [ 3 ]; []; N.makeBy 4 (fun i -> i) ]);
            assert_int_list [] (N.flatten []);
            assert_int_list [ 2; 1; 2 ] (N.flatten [ []; []; [ 2 ]; [ 1 ]; [ 2 ]; [] ]));
        test "concatMany" (fun () ->
            assert_int_list [ 1; 2; 3; 0; 1; 2; 3 ]
              (N.concatMany [| [ 1 ]; [ 2 ]; [ 3 ]; []; N.makeBy 4 (fun i -> i) |]);
            assert_int_list [] (N.concatMany [||]);
            assert_int_list [ 2; 1; 2 ] (N.concatMany [| []; []; [ 2 ]; [ 1 ]; [ 2 ]; [] |]);
            assert_int_list [ 2; 3; 1; 2 ] (N.concatMany [| []; []; [ 2; 3 ]; [ 1 ]; [ 2 ]; [] |]);
            assert_int_list [ 1; 2; 3 ] (N.concatMany [| [ 1; 2; 3 ] |]));
        test "concat" (fun () ->
            assert_array Alcotest.int
              (A.concat (A.makeBy 100 (fun i -> i)) (A.makeBy 100 (fun i -> i)))
              (N.toArray (N.concat (N.makeBy 100 (fun i -> i)) (N.makeBy 100 (fun i -> i))));
            assert_int_list [ 1 ] (N.concat [ 1 ] []);
            assert_int_list [ 1 ] (N.concat [] [ 1 ]));
        test "zip" (fun () ->
            let pair = Alcotest.pair Alcotest.int Alcotest.int in
            assert_list pair [ (1, 3); (2, 4) ] (N.zip [ 1; 2; 3 ] [ 3; 4 ]);
            assert_list pair [] (N.zip [] [ 1 ]);
            assert_list pair [] (N.zip [] []);
            assert_list pair [] (N.zip [ 1; 2; 3 ] []);
            assert_list pair [ (1, 2); (2, 3); (3, 4) ] (N.zip [ 1; 2; 3 ] [ 2; 3; 4 ]));
        test "partition" (fun () ->
            let pair_of_lists = Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int) in
            Alcotest.check pair_of_lists "should be equal"
              ([ 2; 2; 4 ], [ 1; 3; 3 ])
              (N.partition [ 1; 2; 3; 2; 3; 4 ] mod2);
            Alcotest.check pair_of_lists "should be equal" ([ 2; 2; 2; 4 ], []) (N.partition [ 2; 2; 2; 4 ] mod2);
            Alcotest.check pair_of_lists "should be equal"
              ([], [ 2; 2; 2; 4 ])
              (N.partition [ 2; 2; 2; 4 ] (fun x -> not (mod2 x)));
            Alcotest.check pair_of_lists "should be equal" ([], []) (N.partition [] mod2));
        test "unzip" (fun () ->
            let pair_of_lists = Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int) in
            Alcotest.check pair_of_lists "should be equal" ([], []) (N.unzip []);
            Alcotest.check pair_of_lists "should be equal" ([ 1 ], [ 2 ]) (N.unzip [ (1, 2) ]);
            Alcotest.check pair_of_lists "should be equal" ([ 1; 3 ], [ 2; 4 ]) (N.unzip [ (1, 2); (3, 4) ]));
        test "keep" (fun () ->
            assert_int_list [ 2; 4 ] (N.keep [ 1; 2; 3; 4 ] mod2);
            assert_int_list [] (N.keep [ 1; 3; 41 ] mod2);
            assert_int_list [] (N.keep [] mod2);
            assert_int_list [ 2; 2; 2; 4; 6 ] (N.keep [ 2; 2; 2; 4; 6 ] mod2));
        test "keepWithIndex" (fun () ->
            assert_int_list [] (N.keepWithIndex [] evenIndex);
            assert_int_list [ 1; 3 ] (N.keepWithIndex [ 1; 2; 3; 4 ] evenIndex);
            assert_int_list [ 0; 2; 4; 6 ] (N.keepWithIndex [ 0; 1; 2; 3; 4; 5; 6; 7 ] evenIndex));
        test "map" (fun () ->
            assert_int_list [ 0; 2; 4; 6; 8 ] (N.map (N.makeBy 5 id) (fun x -> x * 2));
            assert_int_list [] (N.map [] id);
            assert_int_list [ -1 ] (N.map [ 1 ] (fun x -> -x)));
        test "zipBy and mapReverse2" (fun () ->
            let b = length_10_id in
            let c = length_8_id in
            let d = N.makeBy 10 (fun x -> 2 * x) in
            let map2_add x y = N.zipBy x y add in
            assert_int_list d (map2_add length_10_id b);
            assert_int_list [] (map2_add [] [ 1 ]);
            assert_int_list [] (map2_add [ 1 ] []);
            assert_int_list [] (map2_add [] []);
            assert_int_list (N.concat (N.map c (fun x -> x * 2)) [ 16; 18 ]) (map2_add length_10_id b);
            assert_int_list (N.mapWithIndex length_8_id (fun i x -> i + x)) (map2_add length_10_id length_8_id);
            assert_int_list
              (N.map length_10_id (fun x -> x * 2))
              (N.reverse (N.mapReverse2 length_10_id length_10_id add));
            let xs = N.reverse (N.mapReverse2 length_8_id length_10_id add) in
            assert_int 8 (N.length xs);
            assert_int_list (N.zipBy length_10_id length_8_id add) xs;
            assert_int_list [ 4; 2 ] (N.mapReverse2 [ 1; 2; 3 ] [ 1; 2 ] (fun x y -> x + y)));
        test "take" (fun () ->
            let int_list = Alcotest.list Alcotest.int in
            assert_option int_list (Some [ 1; 2 ]) (N.take [ 1; 2; 3 ] 2);
            assert_option int_list None (N.take [] 1);
            assert_option int_list None (N.take [ 1; 2 ] 3);
            assert_option int_list (Some [ 1; 2 ]) (N.take [ 1; 2 ] 2);
            assert_option int_list (Some length_8_id) (N.take length_10_id 8);
            assert_option int_list (Some []) (N.take length_10_id 0);
            assert_option int_list None (N.take length_8_id (-2)));
        test "drop" (fun () ->
            let int_list = Alcotest.list Alcotest.int in
            assert_option int_list (Some []) (N.drop length_10_id 10);
            assert_option int_list (Some [ 8; 9 ]) (N.drop length_10_id 8);
            assert_option int_list (Some length_10_id) (N.drop length_10_id 0);
            assert_option int_list None (N.drop length_8_id (-1)));
        test "splitAt" (fun () ->
            let split = Alcotest.option (Alcotest.pair (Alcotest.list Alcotest.int) (Alcotest.list Alcotest.int)) in
            let a = N.makeBy 5 id in
            Alcotest.check split "should be equal" None (N.splitAt [] 1);
            Alcotest.check split "should be equal" None (N.splitAt a 6);
            Alcotest.check split "should be equal" (Some (a, [])) (N.splitAt a 5);
            Alcotest.check split "should be equal" (Some ([ 0; 1; 2; 3 ], [ 4 ])) (N.splitAt a 4);
            Alcotest.check split "should be equal" (Some ([ 0; 1; 2 ], [ 3; 4 ])) (N.splitAt a 3);
            Alcotest.check split "should be equal" (Some ([ 0; 1 ], [ 2; 3; 4 ])) (N.splitAt a 2);
            Alcotest.check split "should be equal" (Some ([ 0 ], [ 1; 2; 3; 4 ])) (N.splitAt a 1);
            Alcotest.check split "should be equal" (Some ([], a)) (N.splitAt a 0);
            Alcotest.check split "should be equal" None (N.splitAt a (-1)));
        test "hasAssoc, removeAssoc, setAssoc and getAssoc" (fun () ->
            let eqx x y = (x : int) = y in
            assert_bool true (N.hasAssoc [ (1, "1"); (2, "2"); (3, "3") ] 2 ( = ));
            assert_bool false (N.hasAssoc [ (1, "1"); (2, "2"); (3, "3") ] 4 ( = ));
            assert_bool true (N.hasAssoc [ (1, "1"); (2, "2"); (3, "3") ] 4 (fun x y -> x + 1 = y));
            assert_list int_string_pair [ (1, "1"); (2, "2") ] (N.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 3 ( = ));
            assert_list int_string_pair [ (2, "2"); (3, "3") ] (N.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 1 ( = ));
            assert_list int_string_pair [ (1, "1"); (3, "3") ] (N.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 2 ( = ));
            assert_list int_string_pair
              [ (1, "1"); (2, "2"); (3, "3") ]
              (N.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 0 ( = ));
            assert_list int_string_pair [ (1, "1"); (2, "2") ] (N.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 3 eqx);
            assert_list int_string_pair [ (2, "2"); (3, "3") ] (N.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 1 eqx);
            assert_list int_string_pair [ (1, "1"); (3, "3") ] (N.removeAssoc [ (1, "1"); (2, "2"); (3, "3") ] 2 eqx);
            assert_list int_string_pair [] (N.removeAssoc [] 2 eqx);
            let ll = [ (1, "1"); (2, "2"); (3, "3") ] in
            let ll0 = N.removeAssoc ll 0 eqx in
            assert_bool true (ll == ll0);
            let ll1 = N.setAssoc ll 2 "22" ( = ) in
            assert_list int_string_pair [ (1, "1"); (2, "22"); (3, "3") ] ll1;
            let ll2 = N.setAssoc ll1 22 "2" ( = ) in
            assert_bool true (ll2 = (22, "2") :: ll1);
            assert_bool true (N.tailExn ll2 == ll1);
            assert_bool true (N.setAssoc [ (1, "a"); (2, "b"); (3, "c") ] 2 "x" ( = ) = [ (1, "a"); (2, "x"); (3, "c") ]);
            assert_bool true (N.setAssoc [ (1, "a"); (3, "c") ] 2 "2" ( = ) = [ (2, "2"); (1, "a"); (3, "c") ]);
            assert_list int_string_pair [ (1, "1") ] (N.setAssoc [] 1 "1" ( = ));
            (* skipped (melange-only): [%debugger] *)
            assert_list int_string_pair [ (1, "1") ] (N.setAssoc [ (1, "2") ] 1 "1" ( = ));
            assert_list int_string_pair [ (0, "0"); (1, "1") ] (N.setAssoc [ (0, "0"); (1, "2") ] 1 "1" ( = ));
            assert_bool true (N.getAssoc [ (1, "a"); (2, "b"); (3, "c") ] 2 ( = ) = Some "b");
            assert_bool true (N.getAssoc [ (1, "a"); (2, "b"); (3, "c") ] 4 ( = ) = None));
        test "head, tail, headExn, tailExn and getExn" (fun () ->
            assert_option Alcotest.int (Some 0) (N.head length_10_id);
            assert_option (Alcotest.list Alcotest.int) (N.drop length_10_id 1) (N.tail length_10_id);
            assert_option Alcotest.int None (N.head []);
            (* exception type diverges: native raises Js.Exn.Error (documented) *)
            assert_raises_any (fun () -> N.headExn []);
            assert_raises_any (fun () -> N.tailExn []);
            assert_raises_any (fun () -> N.getExn [ 0; 1 ] (-1));
            assert_raises_any (fun () -> N.getExn [ 0; 1 ] 2);
            assert_int_list [ 0; 1 ] (N.map [ 0; 1 ] (fun i -> N.getExn [ 0; 1 ] i));
            assert_int 1 (N.headExn [ 1 ]);
            assert_int_list [] (N.tailExn [ 1 ]));
        test "get, forEachWithIndex, mapWithIndex and makeBy" (fun () ->
            N.forEachWithIndex length_10_id (fun i x -> assert_option Alcotest.int (Some x) (N.get length_10_id i));
            assert_option (Alcotest.list Alcotest.int) None (N.tail []);
            assert_option (Alcotest.list Alcotest.int) None (N.drop [] 3);
            assert_int_list [] (N.mapWithIndex [] (fun i x -> i + x));
            assert_option Alcotest.int None (N.get length_10_id (-1));
            assert_option Alcotest.int None (N.get length_10_id 12);
            assert_int 0 (sum []);
            assert_int 45 (sum length_10_id);
            assert_int_list [] (N.makeBy 0 id));
        test "reverse and mapReverse" (fun () ->
            assert_int_list length_10_id (N.reverse (N.reverse length_10_id));
            assert_int_list length_8_id (N.reverse (N.reverse length_8_id));
            assert_int_list [] (N.reverse []);
            assert_int_list (N.map length_10_id succx) (N.reverse (N.mapReverse length_10_id succx)));
        test "reduce, reduceReverse and reduceWithIndex" (fun () ->
            assert_int 45 (N.reduce length_10_id 0 add);
            assert_int 45 (N.reduceReverse length_10_id 0 add);
            assert_int (0 + (9_999 * 5_000)) (N.reduceReverse (N.makeBy 10_000 (fun i -> i)) 0 ( + ));
            assert_bool true (N.reduceReverse [ 1; 2; 3; 4 ] 0 ( + ) = 10);
            assert_bool true (N.reduceReverse [ 1; 2; 3; 4 ] 10 ( - ) = 0);
            assert_bool true (N.reduceReverse [ 1; 2; 3; 4 ] [] N.add = [ 1; 2; 3; 4 ]);
            assert_bool true (N.reduce [ 1; 2; 3; 4 ] 0 ( + ) = 10);
            assert_bool true (N.reduce [ 1; 2; 3; 4 ] 10 ( - ) = 0);
            assert_bool true (N.reduce [ 1; 2; 3; 4 ] [] N.add = [ 4; 3; 2; 1 ]);
            assert_bool true (N.reduceWithIndex [ 1; 2; 3; 4 ] 0 (fun acc x i -> acc + x + i) = 16));
        test "forEach2, reduce2 and reduceReverse2" (fun () ->
            assert_int 90 (sum2 length_10_id length_10_id);
            assert_int 56 (sum2 length_8_id length_10_id);
            assert_int 56 (sum2 length_10_id length_8_id);
            assert_int 56 (N.reduce2 length_10_id length_8_id 0 (fun acc x y -> acc + x + y));
            assert_int 18 (N.reduce2 [ 1; 2; 3 ] [ 2; 4; 6 ] 0 (fun a b c -> a + b + c));
            assert_int 56 (N.reduceReverse2 length_10_id length_8_id 0 (fun acc x y -> acc + x + y));
            assert_int 90 (N.reduceReverse2 length_10_id length_10_id 0 (fun acc x y -> acc + x + y));
            assert_int 6 (N.reduceReverse2 [ 1; 2; 3 ] [ 1; 2 ] 0 (fun acc x y -> acc + x + y));
            let a = N.makeBy 10_000 (fun i -> i) in
            assert_bool true (N.reduceReverse2 a (0 :: a) 0 (fun acc x y -> acc + x + y) = (9_999 * 10_000) - 9999));
        test "every, some and has" (fun () ->
            assert_bool true (N.every [ 2; 4; 6 ] mod2);
            assert_bool false (N.every [ 1 ] mod2);
            assert_bool true (N.every [] mod2);
            assert_bool true (N.some [ 1; 2; 5 ] mod2);
            assert_bool false (N.some [ 1; 3; 5 ] mod2);
            assert_bool false (N.some [] mod2);
            assert_bool true (N.has [ 1; 2; 3 ] "2" (fun x s -> string_of_int x = s));
            assert_bool false (N.has [ 1; 2; 3 ] "0" (fun x s -> string_of_int x = s)));
        test "every2 and some2" (fun () ->
            assert_bool true (N.every2 [] [ 1 ] (fun x y -> x > y));
            assert_bool true (N.every2 [ 2; 3 ] [ 1 ] (fun x y -> x > y));
            assert_bool true (N.every2 [ 2 ] [ 1 ] (fun x y -> x > y));
            assert_bool false (N.every2 [ 2; 3 ] [ 1; 4 ] (fun x y -> x > y));
            assert_bool true (N.every2 [ 2; 3 ] [ 1; 0 ] (fun x y -> x > y));
            assert_bool false (N.some2 [] [ 1 ] (fun x y -> x > y));
            assert_bool true (N.some2 [ 2; 3 ] [ 1 ] (fun x y -> x > y));
            assert_bool true (N.some2 [ 2; 3 ] [ 1; 4 ] (fun x y -> x > y));
            assert_bool false (N.some2 [ 0; 3 ] [ 1; 4 ] (fun x y -> x > y));
            assert_bool true (N.some2 [ 0; 3 ] [ 3; 2 ] (fun x y -> x > y));
            assert_bool false (N.some2 [ 1; 2; 3 ] [ -1; -2 ] (fun x y -> x = y)));
        test "add" (fun () -> assert_int_list [ 2; 3 ] (N.add (N.add [] 3) 2));
        test "cmp and cmpByLength" (fun () ->
            assert_bool true (N.cmp [ 1; 2; 3 ] [ 0; 1; 2; 3 ] compare > 0);
            assert_bool true (N.cmp [ 1; 2; 3; 4 ] [ 1; 2; 3 ] compare > 0);
            assert_bool true (N.cmp [ 1; 2; 3 ] [ 1; 2; 3; 4 ] compare < 0);
            assert_bool true (N.cmp [ 1; 2; 3 ] [ 0; 1; 2 ] (fun x y -> compare x y) > 0);
            assert_bool true (N.cmp [ 1; 2; 3 ] [ 1; 2; 3 ] (fun x y -> compare x y) = 0);
            assert_bool true (N.cmp [ 1; 2; 4 ] [ 1; 2; 3 ] (fun x y -> compare x y) > 0);
            assert_bool true (N.cmpByLength [] [] = 0);
            assert_bool true (N.cmpByLength [ 1 ] [] > 0);
            assert_bool true (N.cmpByLength [] [ 1 ] < 0);
            assert_bool true (N.cmpByLength [ 1; 2 ] [ 1 ] > 0);
            assert_bool true (N.cmpByLength [ 1 ] [ 1; 2 ] < 0);
            assert_bool true (N.cmpByLength [ 1; 3 ] [ 1; 2 ] = 0));
        test "make" (fun () ->
            let makeTest n = assert_int_list (N.makeBy n (fun _ -> 3)) (N.make n 3) in
            makeTest 0;
            makeTest 1;
            makeTest 2;
            makeTest 3);
        test "sort" (fun () ->
            let cmp a b = a - b in
            assert_int_list [ 2; 3; 4; 5 ] (N.sort [ 5; 4; 3; 2 ] cmp);
            assert_int_list [ 1; 3; 3; 9; 37 ] (N.sort [ 3; 9; 37; 3; 1 ] cmp));
        test "eq" (fun () ->
            assert_bool false (N.eq [ 1; 2; 3 ] [ 1; 2 ] (fun x y -> x = y));
            assert_bool true (N.eq [ 1; 2; 3 ] [ 1; 2; 3 ] (fun x y -> x = y));
            assert_bool false (N.eq [ 1; 2; 3 ] [ 1; 2; 4 ] (fun x y -> x = y));
            assert_bool false (N.eq [ 1; 2; 3 ] [ 1; 2; 3; 4 ] ( = )));
        test "keepMap" (fun () ->
            let u0 = N.makeBy 20 (fun x -> x) in
            let u1 = N.keepMap u0 (fun x -> if x mod 7 = 0 then Some (x + 1) else None) in
            assert_int_list [ 1; 8; 15 ] u1;
            assert_bool true (N.keepMap [ 1; 2; 3; 4 ] (fun x -> if x mod 2 = 0 then Some (-x) else None) = [ -2; -4 ]);
            assert_bool true (N.keepMap [ 1; 2; 3; 4 ] (fun x -> if x mod 5 = 0 then Some x else None) = []));
      ] );
  ]
