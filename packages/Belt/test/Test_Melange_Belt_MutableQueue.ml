(* Ported from melange jscomp/test/bs_queue_test.ml *)

module Q = Belt.MutableQueue

let ( ++ ) q x =
  Q.add q x;
  q

let suites =
  [
    ( "Melange.Belt.MutableQueue",
      [
        test "add and popExn" (fun () ->
            let q = Q.make () in
            assert_array Alcotest.int [||] (Q.toArray q);
            assert_int 0 (Q.size q);
            assert_array Alcotest.int [| 1 |] (Q.toArray (q ++ 1));
            assert_int 1 (Q.size q);
            assert_array Alcotest.int [| 1; 2 |] (Q.toArray (q ++ 2));
            assert_int 2 (Q.size q);
            assert_array Alcotest.int [| 1; 2; 3 |] (Q.toArray (q ++ 3));
            assert_int 3 (Q.size q);
            assert_array Alcotest.int [| 1; 2; 3; 4 |] (Q.toArray (q ++ 4));
            assert_int 4 (Q.size q);
            assert_int 1 (Q.popExn q);
            assert_array Alcotest.int [| 2; 3; 4 |] (Q.toArray q);
            assert_int 3 (Q.size q);
            assert_int 2 (Q.popExn q);
            assert_array Alcotest.int [| 3; 4 |] (Q.toArray q);
            assert_int 2 (Q.size q);
            assert_int 3 (Q.popExn q);
            assert_array Alcotest.int [| 4 |] (Q.toArray q);
            assert_int 1 (Q.size q);
            assert_int 4 (Q.popExn q);
            assert_array Alcotest.int [||] (Q.toArray q);
            assert_int 0 (Q.size q);
            assert_raises_not_found (fun () -> Q.popExn q));
        test "popExn on singleton" (fun () ->
            let q = Q.make () in
            assert_int 1 (Q.popExn (q ++ 1));
            assert_raises_not_found (fun () -> Q.popExn q);
            assert_int 2 (Q.popExn (q ++ 2));
            assert_raises_not_found (fun () -> Q.popExn q);
            assert_int 0 (Q.size q));
        test "peekExn" (fun () ->
            let q = Q.make () in
            assert_int 1 (Q.peekExn (q ++ 1));
            assert_int 1 (Q.peekExn (q ++ 2));
            assert_int 1 (Q.peekExn (q ++ 3));
            assert_int 1 (Q.peekExn q);
            assert_int 1 (Q.popExn q);
            assert_int 2 (Q.peekExn q);
            assert_int 2 (Q.popExn q);
            assert_int 3 (Q.peekExn q);
            assert_int 3 (Q.popExn q);
            assert_raises_not_found (fun () -> Q.peekExn q);
            assert_raises_not_found (fun () -> Q.peekExn q));
        test "clear" (fun () ->
            let q = Q.make () in
            for i = 1 to 10 do
              Q.add q i
            done;
            Q.clear q;
            assert_int 0 (Q.size q);
            assert_raises_not_found (fun () -> Q.popExn q);
            assert_bool true (q = Q.make ());
            Q.add q 42;
            assert_int 42 (Q.popExn q));
        test "copy" (fun () ->
            let q1 = Q.make () in
            for i = 1 to 10 do
              Q.add q1 i
            done;
            let q2 = Q.copy q1 in
            assert_array Alcotest.int [| 1; 2; 3; 4; 5; 6; 7; 8; 9; 10 |] (Q.toArray q1);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5; 6; 7; 8; 9; 10 |] (Q.toArray q2);
            assert_int 10 (Q.size q1);
            assert_int 10 (Q.size q2);
            for i = 1 to 10 do
              assert_int i (Q.popExn q1)
            done;
            for i = 1 to 10 do
              assert_int i (Q.popExn q2)
            done);
        test "isEmpty and size" (fun () ->
            let q = Q.make () in
            assert_bool true (Q.isEmpty q);
            for i = 1 to 10 do
              Q.add q i;
              assert_int i (Q.size q);
              assert_bool false (Q.isEmpty q)
            done;
            for i = 10 downto 1 do
              assert_int i (Q.size q);
              assert_bool false (Q.isEmpty q);
              ignore (Q.popExn q : int)
            done;
            assert_int 0 (Q.size q);
            assert_bool true (Q.isEmpty q));
        test "forEach" (fun () ->
            let q = Q.make () in
            for i = 1 to 10 do
              Q.add q i
            done;
            let i = ref 1 in
            Q.forEach q (fun j ->
                assert_int !i j;
                incr i));
        test "transfer both empty" (fun () ->
            let q1 = Q.make () and q2 = Q.make () in
            assert_int 0 (Q.size q1);
            assert_array Alcotest.int [||] (Q.toArray q1);
            assert_int 0 (Q.size q2);
            assert_array Alcotest.int [||] (Q.toArray q2);
            Q.transfer q1 q2;
            assert_int 0 (Q.size q1);
            assert_array Alcotest.int [||] (Q.toArray q1);
            assert_int 0 (Q.size q2);
            assert_array Alcotest.int [||] (Q.toArray q2));
        test "transfer into empty" (fun () ->
            let q1 = Q.make () and q2 = Q.make () in
            for i = 1 to 4 do
              Q.add q1 i
            done;
            assert_int 4 (Q.size q1);
            assert_array Alcotest.int [| 1; 2; 3; 4 |] (Q.toArray q1);
            assert_int 0 (Q.size q2);
            assert_array Alcotest.int [||] (Q.toArray q2);
            Q.transfer q1 q2;
            assert_int 0 (Q.size q1);
            assert_array Alcotest.int [||] (Q.toArray q1);
            assert_int 4 (Q.size q2);
            assert_array Alcotest.int [| 1; 2; 3; 4 |] (Q.toArray q2));
        test "transfer from empty" (fun () ->
            let q1 = Q.make () and q2 = Q.make () in
            for i = 5 to 8 do
              Q.add q2 i
            done;
            assert_int 0 (Q.size q1);
            assert_array Alcotest.int [||] (Q.toArray q1);
            assert_int 4 (Q.size q2);
            assert_array Alcotest.int [| 5; 6; 7; 8 |] (Q.toArray q2);
            Q.transfer q1 q2;
            assert_int 0 (Q.size q1);
            assert_array Alcotest.int [||] (Q.toArray q1);
            assert_int 4 (Q.size q2);
            assert_array Alcotest.int [| 5; 6; 7; 8 |] (Q.toArray q2));
        test "transfer both non-empty and reduce" (fun () ->
            let q1 = Q.make () and q2 = Q.make () in
            for i = 1 to 4 do
              Q.add q1 i
            done;
            for i = 5 to 8 do
              Q.add q2 i
            done;
            assert_int 4 (Q.size q1);
            assert_array Alcotest.int [| 1; 2; 3; 4 |] (Q.toArray q1);
            assert_int 4 (Q.size q2);
            assert_array Alcotest.int [| 5; 6; 7; 8 |] (Q.toArray q2);
            Q.transfer q1 q2;
            assert_int 0 (Q.size q1);
            assert_array Alcotest.int [||] (Q.toArray q1);
            let v = [| 5; 6; 7; 8; 1; 2; 3; 4 |] in
            assert_int 8 (Q.size q2);
            assert_array Alcotest.int v (Q.toArray q2);
            assert_int (Belt.Array.reduce v 0 (fun x y -> x - y)) (Q.reduce q2 0 (fun x y -> x - y)));
        test "fromArray and map" (fun () ->
            let q = Q.fromArray [| 1; 2; 3; 4 |] in
            let q1 = Q.map q (fun x -> x - 1) in
            assert_array Alcotest.int [| 0; 1; 2; 3 |] (Q.toArray q1);
            assert_bool true (Q.isEmpty (Q.fromArray [||]));
            assert_bool true (Q.isEmpty (Q.map (Q.fromArray [||]) (fun x -> x + 1))));
      ] );
  ]
