(* Ported from melange/jscomp/test/bs_array_test.ml *)

module A = Belt.Array
module L = Belt.List

(* skipped (melange-only): the Js.Array filter/mapi/reduce |. Js.log smoke test only checks console output *)

let add x y = x + y

let makeMatrixExn sx sy init =
  assert (sx >= 0 && sy >= 0);
  let res = A.makeUninitializedUnsafe sx [||] in
  for x = 0 to sx - 1 do
    let initY = A.makeUninitializedUnsafe sy init in
    for y = 0 to sy - 1 do
      A.setUnsafe initY y init
    done;
    A.setUnsafe res x initY
  done;
  res

let sumUsingForEach xs =
  let v = ref 0 in
  A.forEach xs (fun x -> v := !v + x);
  !v

let assert_reverse x =
  assert_array Alcotest.int (A.reverse x)
    (let u = A.copy x in
     A.reverseInPlace u;
     u)

let suites =
  [
    ( "Melange.Belt.Array",
      [
        test "get" (fun () ->
            let v = [| 1; 2 |] in
            assert_option Alcotest.int (Some 1) (A.get v 0);
            assert_option Alcotest.int (Some 2) (A.get v 1);
            assert_option Alcotest.int None (A.get v 2);
            assert_option Alcotest.int None (A.get v 3);
            assert_option Alcotest.int None (A.get v (-1)));
        test "getExn" (fun () ->
            (* exception type diverges: native raises Js.Exn.Error (documented) *)
            assert_raises_any (fun () -> A.getExn [| 0; 1 |] (-1));
            assert_raises_any (fun () -> A.getExn [| 0; 1 |] 2);
            let f = A.getExn [| 0; 1 |] in
            assert_pair Alcotest.int Alcotest.int (0, 1) (f 0, f 1));
        test "set and setExn" (fun () ->
            (* exception type diverges: native raises Js.Exn.Error (documented) *)
            assert_raises_any (fun () -> A.setExn [| 0; 1 |] (-1) 0);
            assert_raises_any (fun () -> A.setExn [| 0; 1 |] 2 0);
            assert_bool false (A.set [| 1; 2 |] 2 0);
            let v = [| 1; 2 |] in
            assert_bool true (A.set v 0 0);
            assert_int 0 (A.getExn v 0);
            let v = [| 1; 2 |] in
            assert_bool true (A.set v 1 0);
            assert_int 0 (A.getExn v 1);
            let v = [| 1; 2 |] in
            A.setExn v 0 0;
            assert_int 0 (A.getExn v 0);
            let v = [| 1; 2 |] in
            A.setExn v 1 0;
            assert_int 0 (A.getExn v 1));
        test "shuffle" (fun () ->
            let v = A.makeBy 3000 (fun i -> i) in
            let u = A.shuffle v in
            (* unlikely to be equal *)
            assert_bool false (u = v);
            assert_int (A.length v) (A.length u);
            assert_array_unordered Alcotest.int v u;
            let sum x = A.reduce x 0 add in
            assert_int (sum v) (sum u));
        test "range" (fun () ->
            assert_array Alcotest.int [| 0; 1; 2; 3 |] (A.range 0 3);
            assert_array Alcotest.int [||] (A.range 3 0);
            assert_array Alcotest.int [| 3 |] (A.range 3 3));
        test "rangeBy" (fun () ->
            assert_array Alcotest.int [| 0; 3; 6; 9 |] (A.rangeBy 0 10 ~step:3);
            assert_array Alcotest.int [| 0; 3; 6; 9; 12 |] (A.rangeBy 0 12 ~step:3);
            assert_array Alcotest.int [||] (A.rangeBy 33 0 ~step:1);
            assert_array Alcotest.int [||] (A.rangeBy 33 0 ~step:(-1));
            assert_array Alcotest.int [||] (A.rangeBy 3 12 ~step:(-1));
            assert_array Alcotest.int [||] (A.rangeBy 3 3 ~step:0);
            assert_array Alcotest.int [| 3 |] (A.rangeBy 3 3 ~step:1));
        test "reduceReverse, reduceWithIndex and reduceReverse2" (fun () ->
            assert_int 100 (A.reduceReverse [||] 100 ( - ));
            assert_int 97 (A.reduceReverse [| 1; 2 |] 100 ( - ));
            assert_int 90 (A.reduceReverse [| 1; 2; 3; 4 |] 100 ( - ));
            assert_int 16 (A.reduceWithIndex [| 1; 2; 3; 4 |] 0 (fun acc x i -> acc + x + i));
            assert_int 6 (A.reduceReverse2 [| 1; 2; 3 |] [| 1; 2 |] 0 (fun acc x y -> acc + x + y)));
        test "makeBy" (fun () ->
            assert_array Alcotest.int [||] (A.makeBy 0 (fun _ -> 1));
            assert_array Alcotest.int [| 0; 1; 2 |] (A.makeBy 3 (fun i -> i)));
        test "makeMatrixExn (via makeUninitializedUnsafe and setUnsafe)" (fun () ->
            assert_array (Alcotest.array Alcotest.int)
              [| [| 1; 1; 1; 1 |]; [| 1; 1; 1; 1 |]; [| 1; 1; 1; 1 |] |]
              (makeMatrixExn 3 4 1);
            assert_array (Alcotest.array Alcotest.int) [| [||]; [||]; [||] |] (makeMatrixExn 3 0 0);
            assert_array (Alcotest.array Alcotest.int) [||] (makeMatrixExn 0 3 1);
            assert_array (Alcotest.array Alcotest.int) [| [| 1 |] |] (makeMatrixExn 1 1 1));
        test "copy, map and mapWithIndex" (fun () ->
            assert_array Alcotest.int [||] (A.copy [||]);
            assert_array Alcotest.int [||] (A.map [||] succ);
            assert_array Alcotest.int [||] (A.mapWithIndex [||] add);
            assert_array Alcotest.int [| 1; 3; 5 |] (A.mapWithIndex [| 1; 2; 3 |] add);
            assert_array Alcotest.int [| 2; 3; 4 |] (A.map [| 1; 2; 3 |] succ));
        test "List.fromArray and List.toArray" (fun () ->
            assert_list Alcotest.int [] (L.fromArray [||]);
            assert_list Alcotest.int [ 1 ] (L.fromArray [| 1 |]);
            assert_list Alcotest.int [ 1; 2; 3 ] (L.fromArray [| 1; 2; 3 |]);
            assert_array Alcotest.int [||] (L.toArray []);
            assert_array Alcotest.int [| 1 |] (L.toArray [ 1 ]);
            assert_array Alcotest.int [| 1; 2 |] (L.toArray [ 1; 2 ]);
            assert_array Alcotest.int [| 1; 2; 3 |] (L.toArray [ 1; 2; 3 ]));
        test "keep and keepMap" (fun () ->
            let v = A.makeBy 10 (fun i -> i) in
            let v0 = A.keep v (fun x -> x mod 2 = 0) in
            let v1 = A.keep v (fun x -> x mod 3 = 0) in
            let v2 = A.keepMap v (fun x -> if x mod 2 = 0 then Some (x + 1) else None) in
            assert_array Alcotest.int [| 0; 2; 4; 6; 8 |] v0;
            assert_array Alcotest.int [| 0; 3; 6; 9 |] v1;
            assert_array Alcotest.int [| 1; 3; 5; 7; 9 |] v2);
        test "partition" (fun () ->
            let a = [| 1; 2; 3; 4; 5 |] in
            let v0, v1 = A.partition a (fun x -> x mod 2 = 0) in
            assert_array Alcotest.int [| 2; 4 |] v0;
            assert_array Alcotest.int [| 1; 3; 5 |] v1;
            let v0, v1 = A.partition a (fun x -> x = 2) in
            assert_array Alcotest.int [| 2 |] v0;
            assert_array Alcotest.int [| 1; 3; 4; 5 |] v1;
            let v0, v1 = A.partition [||] (fun _ -> false) in
            assert_array Alcotest.int [||] v0;
            assert_array Alcotest.int [||] v1);
        test "slice" (fun () ->
            let a = [| 1; 2; 3; 4; 5 |] in
            assert_array Alcotest.int [| 1; 2 |] (A.slice a ~offset:0 ~len:2);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (A.slice a ~offset:0 ~len:5);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (A.slice a ~offset:0 ~len:15);
            assert_array Alcotest.int [||] (A.slice a ~offset:5 ~len:1);
            assert_array Alcotest.int [| 5 |] (A.slice a ~offset:4 ~len:1);
            assert_array Alcotest.int [| 5 |] (A.slice a ~offset:(-1) ~len:1);
            assert_array Alcotest.int [| 5 |] (A.slice a ~offset:(-1) ~len:2);
            assert_array Alcotest.int [| 4 |] (A.slice a ~offset:(-2) ~len:1);
            assert_array Alcotest.int [| 4; 5 |] (A.slice a ~offset:(-2) ~len:2);
            assert_array Alcotest.int [| 4; 5 |] (A.slice a ~offset:(-2) ~len:3);
            assert_array Alcotest.int [| 1; 2; 3 |] (A.slice a ~offset:(-10) ~len:3);
            assert_array Alcotest.int [| 1; 2; 3; 4 |] (A.slice a ~offset:(-10) ~len:4);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (A.slice a ~offset:(-10) ~len:5);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (A.slice a ~offset:(-10) ~len:6);
            assert_array Alcotest.int [||] (A.slice a ~offset:0 ~len:0);
            assert_array Alcotest.int [||] (A.slice a ~offset:0 ~len:(-1)));
        test "sliceToEnd" (fun () ->
            let a = [| 1; 2; 3; 4; 5 |] in
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (A.sliceToEnd a 0);
            assert_array Alcotest.int [||] (A.sliceToEnd a 5);
            assert_array Alcotest.int [| 5 |] (A.sliceToEnd a 4);
            assert_array Alcotest.int [| 5 |] (A.sliceToEnd a (-1));
            assert_array Alcotest.int [| 4; 5 |] (A.sliceToEnd a (-2));
            assert_array Alcotest.int [| 1; 2; 3; 4; 5 |] (A.sliceToEnd a (-10));
            assert_array Alcotest.int [||] (A.sliceToEnd a 6));
        test "fill" (fun () ->
            let a = A.makeBy 10 (fun x -> x) in
            A.fill a ~offset:0 ~len:3 0;
            assert_array Alcotest.int [| 0; 0; 0; 3; 4; 5; 6; 7; 8; 9 |] (A.copy a);
            A.fill a ~offset:2 ~len:8 1;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 1; 1 |] (A.copy a);
            A.fill a ~offset:8 ~len:1 9;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 9; 1 |] (A.copy a);
            A.fill a ~offset:8 ~len:2 9;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 9; 9 |] (A.copy a);
            A.fill a ~offset:8 ~len:3 12;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 12; 12 |] (A.copy a);
            A.fill a ~offset:(-2) ~len:3 11;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 1; 11; 11 |] (A.copy a);
            A.fill a ~offset:(-3) ~len:3 10;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 10; 10; 10 |] (A.copy a);
            A.fill a ~offset:(-3) ~len:1 7;
            assert_array Alcotest.int [| 0; 0; 1; 1; 1; 1; 1; 7; 10; 10 |] (A.copy a);
            A.fill a ~offset:(-13) ~len:1 7;
            assert_array Alcotest.int [| 7; 0; 1; 1; 1; 1; 1; 7; 10; 10 |] (A.copy a);
            A.fill a ~offset:(-13) ~len:12 7;
            assert_array Alcotest.int (A.make 10 7) (A.copy a);
            A.fill a ~offset:0 ~len:(-1) 2;
            assert_array Alcotest.int (A.make 10 7) (A.copy a);
            let b = [| 1; 2; 3 |] in
            A.fill b ~offset:0 ~len:0 0;
            assert_array Alcotest.int [| 1; 2; 3 |] b;
            A.fill b ~offset:4 ~len:1 0;
            assert_array Alcotest.int [| 1; 2; 3 |] b);
        test "blit and make" (fun () ->
            let a0 = A.makeBy 10 (fun x -> x) in
            let b0 = A.make 10 3 in
            A.blit ~src:a0 ~srcOffset:1 ~dst:b0 ~dstOffset:2 ~len:5;
            assert_array Alcotest.int [| 3; 3; 1; 2; 3; 4; 5; 3; 3; 3 |] (A.copy b0);
            A.blit ~src:a0 ~srcOffset:(-1) ~dst:b0 ~dstOffset:2 ~len:5;
            assert_array Alcotest.int [| 3; 3; 9; 2; 3; 4; 5; 3; 3; 3 |] (A.copy b0);
            A.blit ~src:a0 ~srcOffset:(-1) ~dst:b0 ~dstOffset:(-2) ~len:5;
            assert_array Alcotest.int [| 3; 3; 9; 2; 3; 4; 5; 3; 9; 3 |] (A.copy b0);
            A.blit ~src:a0 ~srcOffset:(-2) ~dst:b0 ~dstOffset:(-2) ~len:2;
            assert_array Alcotest.int [| 3; 3; 9; 2; 3; 4; 5; 3; 8; 9 |] (A.copy b0);
            A.blit ~src:a0 ~srcOffset:(-11) ~dst:b0 ~dstOffset:(-11) ~len:100;
            assert_array Alcotest.int a0 (A.copy b0);
            A.blit ~src:a0 ~srcOffset:(-11) ~dst:b0 ~dstOffset:(-11) ~len:2;
            assert_array Alcotest.int a0 (A.copy b0);
            let aa = A.makeBy 10 (fun x -> x) in
            A.blit ~src:aa ~srcOffset:(-1) ~dst:aa ~dstOffset:1 ~len:2;
            assert_array Alcotest.int [| 0; 9; 2; 3; 4; 5; 6; 7; 8; 9 |] (A.copy aa);
            A.blit ~src:aa ~srcOffset:(-2) ~dst:aa ~dstOffset:1 ~len:2;
            assert_array Alcotest.int [| 0; 8; 9; 3; 4; 5; 6; 7; 8; 9 |] (A.copy aa);
            A.blit ~src:aa ~srcOffset:(-5) ~dst:aa ~dstOffset:4 ~len:3;
            assert_array Alcotest.int [| 0; 8; 9; 3; 5; 6; 7; 7; 8; 9 |] (A.copy aa);
            A.blit ~src:aa ~srcOffset:4 ~dst:aa ~dstOffset:5 ~len:3;
            assert_array Alcotest.int [| 0; 8; 9; 3; 5; 5; 6; 7; 8; 9 |] (A.copy aa);
            assert_array Alcotest.int [||] (A.make 0 3);
            assert_array Alcotest.int [||] (A.make (-1) 3);
            let c = [| 0; 1; 2 |] in
            A.blit ~src:c ~srcOffset:4 ~dst:c ~dstOffset:1 ~len:1;
            assert_array Alcotest.int [| 0; 1; 2 |] c);
        test "zip, zipBy and unzip" (fun () ->
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.int)
              [| (1, 2); (2, 3); (3, 4) |]
              (A.zip [| 1; 2; 3 |] [| 2; 3; 4; 1 |]);
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.int)
              [| (2, 1); (3, 2); (4, 3) |]
              (A.zip [| 2; 3; 4; 1 |] [| 1; 2; 3 |]);
            assert_array Alcotest.int [| 1; 1; 1 |] (A.zipBy [| 2; 3; 4; 1 |] [| 1; 2; 3 |] ( - ));
            assert_array Alcotest.int (A.map [| 1; 1; 1 |] (fun x -> -x)) (A.zipBy [| 1; 2; 3 |] [| 2; 3; 4; 1 |] ( - ));
            assert_pair (Alcotest.array Alcotest.int) (Alcotest.array Alcotest.int)
              ([| 1; 2; 3 |], [| 2; 3; 4 |])
              (A.unzip [| (1, 2); (2, 3); (3, 4) |]));
        test "forEach, every, some, eq and forEachWithIndex" (fun () ->
            assert_int 10 (sumUsingForEach [| 0; 1; 2; 3; 4 |]);
            assert_bool false (A.every [| 0; 1; 2; 3; 4 |] (fun x -> x > 2));
            assert_bool true (A.some [| 1; 3; 7; 8 |] (fun x -> x mod 2 = 0));
            assert_bool false (A.some [| 1; 3; 7 |] (fun x -> x mod 2 = 0));
            assert_bool false (A.eq [| 0; 1 |] [| 1 |] ( = ));
            let c = ref 0 in
            A.forEachWithIndex [| 1; 1; 1 |] (fun i v -> c := !c + i + v);
            assert_int 6 !c);
        test "reverse and reverseInPlace" (fun () ->
            assert_reverse [||];
            assert_reverse [| 1 |];
            assert_reverse [| 1; 2 |];
            assert_reverse [| 1; 2; 3 |];
            assert_reverse [| 1; 2; 3; 4 |]);
        test "every2 and some2" (fun () ->
            let every2 xs ys = A.every2 (L.toArray xs) (L.toArray ys) in
            let some2 xs ys = A.some2 (L.toArray xs) (L.toArray ys) in
            assert_bool true (every2 [] [ 1 ] (fun x y -> x > y));
            assert_bool true (every2 [ 2; 3 ] [ 1 ] (fun x y -> x > y));
            assert_bool true (every2 [ 2 ] [ 1 ] (fun x y -> x > y));
            assert_bool false (every2 [ 2; 3 ] [ 1; 4 ] (fun x y -> x > y));
            assert_bool true (every2 [ 2; 3 ] [ 1; 0 ] (fun x y -> x > y));
            assert_bool false (some2 [] [ 1 ] (fun x y -> x > y));
            assert_bool true (some2 [ 2; 3 ] [ 1 ] (fun x y -> x > y));
            assert_bool true (some2 [ 2; 3 ] [ 1; 4 ] (fun x y -> x > y));
            assert_bool false (some2 [ 0; 3 ] [ 1; 4 ] (fun x y -> x > y));
            assert_bool true (some2 [ 0; 3 ] [ 3; 2 ] (fun x y -> x > y)));
        test "concat and concatMany" (fun () ->
            assert_array Alcotest.int [| 1; 2; 3 |] (A.concat [||] [| 1; 2; 3 |]);
            assert_array Alcotest.int [||] (A.concat [||] [||]);
            assert_array Alcotest.int [| 3; 2; 1; 2; 3 |] (A.concat [| 3; 2 |] [| 1; 2; 3 |]);
            assert_array Alcotest.int [| 3; 2; 1; 2; 3 |] (A.concatMany [| [| 3; 2 |]; [| 1; 2; 3 |] |]);
            assert_array Alcotest.int [| 3; 2; 1; 2; 3; 0 |]
              (A.concatMany [| [| 3; 2 |]; [| 1; 2; 3 |]; [||]; [| 0 |] |]);
            assert_array Alcotest.int [| 3; 2; 1; 2; 3; 0 |]
              (A.concatMany [| [||]; [| 3; 2 |]; [| 1; 2; 3 |]; [||]; [| 0 |] |]);
            assert_array Alcotest.int [||] (A.concatMany [| [||]; [||] |]));
        test "cmp" (fun () ->
            assert_bool true (A.cmp [| 1; 2; 3 |] [| 0; 1; 2; 3 |] compare < 0);
            assert_bool true (A.cmp [| 0; 1; 2; 3 |] [| 1; 2; 3 |] compare > 0);
            assert_bool true (A.cmp [| 1; 2; 3 |] [| 0; 1; 2 |] (fun x y -> compare x y) > 0);
            assert_bool true (A.cmp [| 1; 2; 3 |] [| 1; 2; 3 |] (fun x y -> compare x y) = 0);
            assert_bool true (A.cmp [| 1; 2; 4 |] [| 1; 2; 3 |] (fun x y -> compare x y) > 0));
        test "getBy" (fun () ->
            assert_option Alcotest.int (Some 2) (A.getBy [| 1; 2; 3 |] (fun x -> x > 1));
            assert_option Alcotest.int None (A.getBy [| 1; 2; 3 |] (fun x -> x > 3)));
        test "getIndexBy" (fun () ->
            assert_option Alcotest.int (Some 1) (A.getIndexBy [| 1; 2; 3 |] (fun x -> x > 1));
            assert_option Alcotest.int None (A.getIndexBy [| 1; 2; 3 |] (fun x -> x > 3)));
        (* skipped (documented divergence): Belt.Array.push is a no-op natively *)
      ] );
  ]
