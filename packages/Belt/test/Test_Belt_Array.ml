let suites =
  [
    ( "Array",
      [
        test "get and set bounds" (fun () ->
            let values = [| 1; 2 |] in
            assert_option Alcotest.int (Some 1) (Belt.Array.get values 0);
            assert_option Alcotest.int (Some 2) (Belt.Array.get values 1);
            assert_option Alcotest.int None (Belt.Array.get values 2);
            assert_option Alcotest.int None (Belt.Array.get values 3);
            assert_option Alcotest.int None (Belt.Array.get values (-1));
            assert_option Alcotest.int (Some 1) (Js.Undefined.toOption (Belt.Array.getUndefined values 0));
            assert_option Alcotest.int None (Js.Undefined.toOption (Belt.Array.getUndefined values 2));
            assert_raises_any (fun () -> ignore (Belt.Array.getExn [| 0; 1 |] (-1)));
            assert_raises_any (fun () -> ignore (Belt.Array.getExn [| 0; 1 |] 2));
            assert_int 0 (Belt.Array.getExn [| 0; 1 |] 0);
            assert_int 1 (Belt.Array.getExn [| 0; 1 |] 1);
            assert_raises_any (fun () -> Belt.Array.setExn [| 0; 1 |] (-1) 0);
            assert_raises_any (fun () -> Belt.Array.setExn [| 0; 1 |] 2 0);
            assert_bool false (Belt.Array.set [| 1; 2 |] 2 0);
            let left = [| 1; 2 |] in
            assert_bool true (Belt.Array.set left 0 0);
            assert_int 0 (Belt.Array.getExn left 0);
            let right = [| 1; 2 |] in
            assert_bool true (Belt.Array.set right 1 0);
            assert_int 0 (Belt.Array.getExn right 1);
            let exn_left = [| 1; 2 |] in
            Belt.Array.setExn exn_left 0 0;
            assert_int 0 (Belt.Array.getExn exn_left 0);
            let exn_right = [| 1; 2 |] in
            Belt.Array.setExn exn_right 1 0;
            assert_int 0 (Belt.Array.getExn exn_right 1));
        test "shuffle preserves contents" (fun () ->
            let original = Belt.Array.makeBy 3000 (fun i -> i) in
            let shuffled = Belt.Array.shuffle original in
            assert_bool false (original = shuffled);
            assert_int (Belt.Array.reduce original 0 ( + )) (Belt.Array.reduce shuffled 0 ( + )));
        test "range helpers" (fun () ->
            assert_array Alcotest.int [| 0; 1; 2; 3 |] (Belt.Array.range 0 3);
            assert_array Alcotest.int [||] (Belt.Array.range 3 0);
            assert_array Alcotest.int [| 3 |] (Belt.Array.range 3 3);
            assert_array Alcotest.int [| 0; 3; 6; 9 |] (Belt.Array.rangeBy 0 10 ~step:3);
            assert_array Alcotest.int [| 0; 3; 6; 9; 12 |] (Belt.Array.rangeBy 0 12 ~step:3);
            assert_array Alcotest.int [||] (Belt.Array.rangeBy 33 0 ~step:1);
            assert_array Alcotest.int [||] (Belt.Array.rangeBy 33 0 ~step:(-1));
            assert_array Alcotest.int [||] (Belt.Array.rangeBy 3 12 ~step:(-1));
            assert_array Alcotest.int [||] (Belt.Array.rangeBy 3 3 ~step:0);
            assert_array Alcotest.int [| 3 |] (Belt.Array.rangeBy 3 3 ~step:1));
        test "reductions" (fun () ->
            assert_int 100 (Belt.Array.reduceReverse [||] 100 ( - ));
            assert_int 97 (Belt.Array.reduceReverse [| 1; 2 |] 100 ( - ));
            assert_int 90 (Belt.Array.reduceReverse [| 1; 2; 3; 4 |] 100 ( - ));
            assert_int 16 (Belt.Array.reduceWithIndex [| 1; 2; 3; 4 |] 0 (fun acc value index -> acc + value + index));
            assert_int 6
              (Belt.Array.reduceReverse2 [| 1; 2; 3 |] [| 1; 2 |] 0 (fun acc left right -> acc + left + right)));
        test "construction copy and conversions" (fun () ->
            let make_matrix width height value =
              let outer = Belt.Array.makeUninitializedUnsafe width [||] in
              for x = 0 to width - 1 do
                let inner = Belt.Array.makeUninitializedUnsafe height value in
                for y = 0 to height - 1 do
                  Belt.Array.setUnsafe inner y value
                done;
                Belt.Array.setUnsafe outer x inner
              done;
              outer
            in
            let undefined_array : int Js.undefined array = Belt.Array.makeUninitialized 1 in
            assert_int 1 (Belt.Array.length undefined_array);
            assert_array (Alcotest.option Alcotest.int) [| None |]
              (Belt.Array.mapU undefined_array Js.Undefined.toOption);
            assert_array Alcotest.int [||] (Belt.Array.makeBy 0 (fun _ -> 1));
            assert_array Alcotest.int [| 0; 1; 2 |] (Belt.Array.makeBy 3 (fun i -> i));
            assert_array (Alcotest.array Alcotest.int)
              [| [| 1; 1; 1; 1 |]; [| 1; 1; 1; 1 |]; [| 1; 1; 1; 1 |] |]
              (make_matrix 3 4 1);
            assert_array (Alcotest.array Alcotest.int) [| [||]; [||]; [||] |] (make_matrix 3 0 0);
            assert_array (Alcotest.array Alcotest.int) [||] (make_matrix 0 3 1);
            assert_array (Alcotest.array Alcotest.int) [| [| 1 |] |] (make_matrix 1 1 1);
            assert_array Alcotest.int [||] (Belt.Array.copy [||]);
            assert_array Alcotest.int [||] (Belt.Array.map [||] succ);
            assert_array Alcotest.int [||] (Belt.Array.mapWithIndex [||] ( + ));
            assert_array Alcotest.int [| 1; 3; 5 |] (Belt.Array.mapWithIndex [| 1; 2; 3 |] ( + ));
            assert_list Alcotest.int [] (Belt.List.fromArray [||]);
            assert_list Alcotest.int [ 1 ] (Belt.List.fromArray [| 1 |]);
            assert_list Alcotest.int [ 1; 2; 3 ] (Belt.List.fromArray [| 1; 2; 3 |]);
            assert_array Alcotest.int [| 2; 3; 4 |] (Belt.Array.map [| 1; 2; 3 |] succ);
            assert_array Alcotest.int [||] (Belt.List.toArray []);
            assert_array Alcotest.int [| 1 |] (Belt.List.toArray [ 1 ]);
            assert_array Alcotest.int [| 1; 2 |] (Belt.List.toArray [ 1; 2 ]);
            assert_array Alcotest.int [| 1; 2; 3 |] (Belt.List.toArray [ 1; 2; 3 ]));
        test "callback once regressions" (fun () ->
            let seen_make = ref [] in
            let made =
              Belt.Array.makeByU 3 (fun i ->
                  seen_make := i :: !seen_make;
                  i * 2)
            in
            assert_array Alcotest.int [| 0; 2; 4 |] made;
            assert_list Alcotest.int [ 0; 1; 2 ] (List.rev !seen_make);
            let seen_map = ref [] in
            let mapped =
              Belt.Array.mapU [| 1; 2; 3 |] (fun value ->
                  seen_map := value :: !seen_map;
                  value + 10)
            in
            assert_array Alcotest.int [| 11; 12; 13 |] mapped;
            assert_list Alcotest.int [ 1; 2; 3 ] (List.rev !seen_map);
            let seen_map_with_index = ref [] in
            let mapped_with_index =
              Belt.Array.mapWithIndexU [| "a"; "b"; "c" |] (fun index value ->
                  seen_map_with_index := (index, value) :: !seen_map_with_index;
                  index)
            in
            assert_array Alcotest.int [| 0; 1; 2 |] mapped_with_index;
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.string)
              [ (0, "a"); (1, "b"); (2, "c") ]
              (List.rev !seen_map_with_index);
            let seen_zip = ref [] in
            let zipped =
              Belt.Array.zipByU [| 1; 2; 3 |] [| 10; 20 |] (fun left right ->
                  seen_zip := (left, right) :: !seen_zip;
                  left + right)
            in
            assert_array Alcotest.int [| 11; 22 |] zipped;
            assert_list (Alcotest.pair Alcotest.int Alcotest.int) [ (1, 10); (2, 20) ] (List.rev !seen_zip));
        test "keep keepMap and partition" (fun () ->
            let values = Belt.Array.makeBy 10 (fun i -> i) in
            assert_array Alcotest.int [| 0; 2; 4; 6; 8 |] (Belt.Array.keep values (fun value -> value mod 2 = 0));
            assert_array Alcotest.int [| 0; 3; 6; 9 |] (Belt.Array.keep values (fun value -> value mod 3 = 0));
            assert_array Alcotest.int [| 1; 3; 5; 7; 9 |]
              (Belt.Array.keepMap values (fun value -> if value mod 2 = 0 then Some (value + 1) else None));
            let evens, odds = Belt.Array.partition [| 1; 2; 3; 4; 5 |] (fun value -> value mod 2 = 0) in
            assert_array Alcotest.int [| 2; 4 |] evens;
            assert_array Alcotest.int [| 1; 3; 5 |] odds;
            let twos, rest = Belt.Array.partition [| 1; 2; 3; 4; 5 |] (fun value -> value = 2) in
            assert_array Alcotest.int [| 2 |] twos;
            assert_array Alcotest.int [| 1; 3; 4; 5 |] rest;
            let yes, no = Belt.Array.partition [||] (fun _ -> false) in
            assert_array Alcotest.int [||] yes;
            assert_array Alcotest.int [||] no);
        test "slice" (fun () ->
            let values = [| 1; 2; 3; 4; 5 |] in
            assert_array Alcotest.int [| 1; 2 |] (Belt.Array.slice values ~offset:0 ~len:2);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (Belt.Array.slice values ~offset:0 ~len:5);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (Belt.Array.slice values ~offset:0 ~len:15);
            assert_array Alcotest.int [||] (Belt.Array.slice values ~offset:5 ~len:1);
            assert_array Alcotest.int [| 5 |] (Belt.Array.slice values ~offset:4 ~len:1);
            assert_array Alcotest.int [| 5 |] (Belt.Array.slice values ~offset:(-1) ~len:1);
            assert_array Alcotest.int [| 5 |] (Belt.Array.slice values ~offset:(-1) ~len:2);
            assert_array Alcotest.int [| 4 |] (Belt.Array.slice values ~offset:(-2) ~len:1);
            assert_array Alcotest.int [| 4; 5 |] (Belt.Array.slice values ~offset:(-2) ~len:2);
            assert_array Alcotest.int [| 4; 5 |] (Belt.Array.slice values ~offset:(-2) ~len:3);
            assert_array Alcotest.int [| 1; 2; 3 |] (Belt.Array.slice values ~offset:(-10) ~len:3);
            assert_array Alcotest.int [| 1; 2; 3; 4 |] (Belt.Array.slice values ~offset:(-10) ~len:4);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (Belt.Array.slice values ~offset:(-10) ~len:5);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (Belt.Array.slice values ~offset:(-10) ~len:6);
            assert_array Alcotest.int [||] (Belt.Array.slice values ~offset:0 ~len:0);
            assert_array Alcotest.int [||] (Belt.Array.slice values ~offset:0 ~len:(-1)));
        test "sliceToEnd" (fun () ->
            let values = [| 1; 2; 3; 4; 5 |] in
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (Belt.Array.sliceToEnd values 0);
            assert_array Alcotest.int [||] (Belt.Array.sliceToEnd values 5);
            assert_array Alcotest.int [| 5 |] (Belt.Array.sliceToEnd values 4);
            assert_array Alcotest.int [| 5 |] (Belt.Array.sliceToEnd values (-1));
            assert_array Alcotest.int [| 4; 5 |] (Belt.Array.sliceToEnd values (-2));
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (Belt.Array.sliceToEnd values (-10));
            assert_array Alcotest.int [||] (Belt.Array.sliceToEnd values 6));
        test "fill" (fun () ->
            let values = Belt.Array.makeBy 10 (fun value -> value) in
            Belt.Array.fill values ~offset:0 ~len:3 0;
            assert_array Alcotest.int [| 0; 0; 0; 3; 4; 5; 6; 7; 8; 9 |] values;
            Belt.Array.fill values ~offset:2 ~len:8 1;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 1; 1 |] values;
            Belt.Array.fill values ~offset:8 ~len:1 9;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 9; 1 |] values;
            Belt.Array.fill values ~offset:8 ~len:2 9;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 9; 9 |] values;
            Belt.Array.fill values ~offset:8 ~len:3 12;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 12; 12 |] values;
            Belt.Array.fill values ~offset:(-2) ~len:3 11;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 11; 11 |] values;
            Belt.Array.fill values ~offset:(-3) ~len:3 10;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 10; 10; 10 |] values;
            Belt.Array.fill values ~offset:(-3) ~len:1 7;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 7; 10; 10 |] values;
            Belt.Array.fill values ~offset:(-13) ~len:1 7;
            assert_array Alcotest.int [| 7; 0; 1; 1; 1; 1; 1; 7; 10; 10 |] values;
            Belt.Array.fill values ~offset:(-13) ~len:12 7;
            assert_array Alcotest.int (Array.make 10 7) values;
            Belt.Array.fill values ~offset:0 ~len:(-1) 2;
            assert_array Alcotest.int (Array.make 10 7) values;
            let small = [| 1; 2; 3 |] in
            Belt.Array.fill small ~offset:0 ~len:0 0;
            assert_array Alcotest.int [| 1; 2; 3 |] small;
            Belt.Array.fill small ~offset:4 ~len:1 0;
            assert_array Alcotest.int [| 1; 2; 3 |] small);
        test "blit" (fun () ->
            let src = Belt.Array.makeBy 10 (fun value -> value) in
            let dst = Belt.Array.make 10 3 in
            Belt.Array.blit ~src ~srcOffset:1 ~dst ~dstOffset:2 ~len:5;
            assert_array Alcotest.int [| 3; 3; 1; 2; 3; 4; 5; 3; 3; 3 |] dst;
            Belt.Array.blit ~src ~srcOffset:(-1) ~dst ~dstOffset:2 ~len:5;
            assert_array Alcotest.int [| 3; 3; 9; 2; 3; 4; 5; 3; 3; 3 |] dst;
            Belt.Array.blit ~src ~srcOffset:(-1) ~dst ~dstOffset:(-2) ~len:5;
            assert_array Alcotest.int [| 3; 3; 9; 2; 3; 4; 5; 3; 9; 3 |] dst;
            Belt.Array.blit ~src ~srcOffset:(-2) ~dst ~dstOffset:(-2) ~len:2;
            assert_array Alcotest.int [| 3; 3; 9; 2; 3; 4; 5; 3; 8; 9 |] dst;
            Belt.Array.blit ~src ~srcOffset:(-11) ~dst ~dstOffset:(-11) ~len:100;
            assert_array Alcotest.int src dst;
            Belt.Array.blit ~src ~srcOffset:(-11) ~dst ~dstOffset:(-11) ~len:2;
            assert_array Alcotest.int src dst;
            let overlap = Belt.Array.makeBy 10 (fun value -> value) in
            Belt.Array.blit ~src:overlap ~srcOffset:(-1) ~dst:overlap ~dstOffset:1 ~len:2;
            assert_array Alcotest.int [| 0; 9; 2; 3; 4; 5; 6; 7; 8; 9 |] overlap;
            Belt.Array.blit ~src:overlap ~srcOffset:(-2) ~dst:overlap ~dstOffset:1 ~len:2;
            assert_array Alcotest.int [| 0; 8; 9; 3; 4; 5; 6; 7; 8; 9 |] overlap;
            Belt.Array.blit ~src:overlap ~srcOffset:(-5) ~dst:overlap ~dstOffset:4 ~len:3;
            assert_array Alcotest.int [| 0; 8; 9; 3; 5; 6; 7; 7; 8; 9 |] overlap;
            Belt.Array.blit ~src:overlap ~srcOffset:4 ~dst:overlap ~dstOffset:5 ~len:3;
            assert_array Alcotest.int [| 0; 8; 9; 3; 5; 5; 6; 7; 8; 9 |] overlap;
            assert_array Alcotest.int [||] (Belt.Array.make 0 3);
            assert_array Alcotest.int [||] (Belt.Array.make (-1) 3);
            let untouched = [| 0; 1; 2 |] in
            Belt.Array.blit ~src:untouched ~srcOffset:4 ~dst:untouched ~dstOffset:1 ~len:1;
            assert_array Alcotest.int [| 0; 1; 2 |] untouched);
        test "zip and unzip" (fun () ->
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.int)
              [| (1, 2); (2, 3); (3, 4) |]
              (Belt.Array.zip [| 1; 2; 3 |] [| 2; 3; 4; 1 |]);
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.int)
              [| (2, 1); (3, 2); (4, 3) |]
              (Belt.Array.zip [| 2; 3; 4; 1 |] [| 1; 2; 3 |]);
            assert_array Alcotest.int [| 1; 1; 1 |] (Belt.Array.zipBy [| 2; 3; 4; 1 |] [| 1; 2; 3 |] ( - ));
            assert_array Alcotest.int [| -1; -1; -1 |] (Belt.Array.zipBy [| 1; 2; 3 |] [| 2; 3; 4; 1 |] ( - ));
            let left, right = Belt.Array.unzip [| (1, 2); (2, 3); (3, 4) |] in
            assert_array Alcotest.int [| 1; 2; 3 |] left;
            assert_array Alcotest.int [| 2; 3; 4 |] right);
        test "iteration predicates and reverse" (fun () ->
            let sum = ref 0 in
            Belt.Array.forEach [| 0; 1; 2; 3; 4 |] (fun value -> sum := !sum + value);
            assert_int 10 !sum;
            assert_bool false (Belt.Array.every [| 0; 1; 2; 3; 4 |] (fun value -> value > 2));
            assert_bool true (Belt.Array.some [| 1; 3; 7; 8 |] (fun value -> value mod 2 = 0));
            assert_bool false (Belt.Array.some [| 1; 3; 7 |] (fun value -> value mod 2 = 0));
            assert_bool false (Belt.Array.eq [| 0; 1 |] [| 1 |] ( = ));
            let indexed_sum = ref 0 in
            Belt.Array.forEachWithIndex [| 1; 1; 1 |] (fun index value -> indexed_sum := !indexed_sum + index + value);
            assert_int 6 !indexed_sum;
            List.iter
              (fun values ->
                let reversed = Belt.Array.reverse values in
                let in_place = Belt.Array.copy values in
                Belt.Array.reverseInPlace in_place;
                assert_array Alcotest.int reversed in_place)
              [ [||]; [| 1 |]; [| 1; 2 |]; [| 1; 2; 3 |]; [| 1; 2; 3; 4 |] ]);
        test "every2 and some2" (fun () ->
            assert_bool true (Belt.Array.every2 [||] [| 1 |] (fun left right -> left > right));
            assert_bool true (Belt.Array.every2 [| 2; 3 |] [| 1 |] (fun left right -> left > right));
            assert_bool true (Belt.Array.every2 [| 2 |] [| 1 |] (fun left right -> left > right));
            assert_bool false (Belt.Array.every2 [| 2; 3 |] [| 1; 4 |] (fun left right -> left > right));
            assert_bool true (Belt.Array.every2 [| 2; 3 |] [| 1; 0 |] (fun left right -> left > right));
            assert_bool false (Belt.Array.some2 [||] [| 1 |] (fun left right -> left > right));
            assert_bool true (Belt.Array.some2 [| 2; 3 |] [| 1 |] (fun left right -> left > right));
            assert_bool true (Belt.Array.some2 [| 2; 3 |] [| 1; 4 |] (fun left right -> left > right));
            assert_bool false (Belt.Array.some2 [| 0; 3 |] [| 1; 4 |] (fun left right -> left > right));
            assert_bool true (Belt.Array.some2 [| 0; 3 |] [| 3; 2 |] (fun left right -> left > right)));
        test "concat and concatMany" (fun () ->
            let left = [| 3; 4 |] in
            let right = [| 1; 2 |] in
            let empty_left = Belt.Array.concat [||] right in
            let empty_right = Belt.Array.concat left [||] in
            assert_array Alcotest.int [| 1; 2; 3 |] (Belt.Array.concat [||] [| 1; 2; 3 |]);
            assert_array Alcotest.int [||] (Belt.Array.concat [||] [||]);
            assert_array Alcotest.int [| 3; 2; 1; 2; 3 |] (Belt.Array.concat [| 3; 2 |] [| 1; 2; 3 |]);
            assert_array Alcotest.int [| 3; 2; 1; 2; 3 |] (Belt.Array.concatMany [| [| 3; 2 |]; [| 1; 2; 3 |] |]);
            assert_array Alcotest.int [| 3; 2; 1; 2; 3; 0 |]
              (Belt.Array.concatMany [| [| 3; 2 |]; [| 1; 2; 3 |]; [||]; [| 0 |] |]);
            assert_array Alcotest.int [| 3; 2; 1; 2; 3; 0 |]
              (Belt.Array.concatMany [| [||]; [| 3; 2 |]; [| 1; 2; 3 |]; [||]; [| 0 |] |]);
            assert_array Alcotest.int [||] (Belt.Array.concatMany [| [||]; [||] |]);
            assert_array Alcotest.int [| 1; 2 |] empty_left;
            assert_array Alcotest.int [| 3; 4 |] empty_right;
            Belt.Array.setExn empty_left 0 99;
            Belt.Array.setExn empty_right 0 42;
            assert_array Alcotest.int [| 1; 2 |] right;
            assert_array Alcotest.int [| 3; 4 |] left);
        test "cmp and find helpers" (fun () ->
            assert_bool true (Belt.Array.cmp [| 1; 2; 3 |] [| 0; 1; 2; 3 |] compare < 0);
            assert_bool true (Belt.Array.cmp [| 0; 1; 2; 3 |] [| 1; 2; 3 |] compare > 0);
            assert_bool true (Belt.Array.cmp [| 1; 2; 3 |] [| 0; 1; 2 |] compare > 0);
            assert_bool true (Belt.Array.cmp [| 1; 2; 3 |] [| 1; 2; 3 |] compare = 0);
            assert_bool true (Belt.Array.cmp [| 1; 2; 4 |] [| 1; 2; 3 |] compare > 0);
            assert_option Alcotest.int (Some 2) (Belt.Array.getBy [| 1; 2; 3 |] (fun value -> value > 1));
            assert_option Alcotest.int None (Belt.Array.getBy [| 1; 2; 3 |] (fun value -> value > 3));
            assert_option Alcotest.int (Some 1) (Belt.Array.getIndexBy [| 1; 2; 3 |] (fun value -> value > 1));
            assert_option Alcotest.int None (Belt.Array.getIndexBy [| 1; 2; 3 |] (fun value -> value > 3)));
        test "unsafe allocation helpers" (fun () ->
            let values = Belt.Array.makeUninitializedUnsafe 5 "lola" in
            assert_string "lola" (Belt.Array.getUnsafe values 0);
            assert_string "lola" (Belt.Array.getUnsafe values 1);
            assert_string "lola" (Belt.Array.getUnsafe values 2);
            assert_string "lola" (Belt.Array.getUnsafe values 3);
            assert_string "lola" (Belt.Array.getUnsafe values 4);
            let truncated = Belt.Array.truncateToLengthUnsafe values 3 in
            assert_string "lola" (Belt.Array.getUnsafe truncated 0));
        test "push unsupported in native" (fun () ->
            let values = [||] in
            assert_bool true
              (match (Belt.Array.push [@alert "-not_implemented"]) values 3 with
              | `Do_not_use_Array_push_in_native -> true);
            assert_bool true
              (match (Belt.Array.push [@alert "-not_implemented"]) values 2 with
              | `Do_not_use_Array_push_in_native -> true);
            assert_bool true
              (match (Belt.Array.push [@alert "-not_implemented"]) values 1 with
              | `Do_not_use_Array_push_in_native -> true);
            assert_array Alcotest.int [||] values);
      ] );
  ]
