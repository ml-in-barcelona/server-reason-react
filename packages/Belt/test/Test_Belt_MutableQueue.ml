let does_raise operation queue = match operation queue with exception _ -> true | _ -> false

let suites =
  [
    ( "MutableQueue",
      [
        test "push pop fifo" (fun () ->
            let queue = Belt.MutableQueue.make () in
            assert_array Alcotest.int [||] (Belt.MutableQueue.toArray queue);
            assert_int 0 (Belt.MutableQueue.size queue);
            Belt.MutableQueue.add queue 1;
            assert_array Alcotest.int [| 1 |] (Belt.MutableQueue.toArray queue);
            assert_int 1 (Belt.MutableQueue.size queue);
            Belt.MutableQueue.add queue 2;
            Belt.MutableQueue.add queue 3;
            Belt.MutableQueue.add queue 4;
            assert_array Alcotest.int [| 1; 2; 3; 4 |] (Belt.MutableQueue.toArray queue);
            assert_int 1 (Belt.MutableQueue.popExn queue);
            assert_array Alcotest.int [| 2; 3; 4 |] (Belt.MutableQueue.toArray queue);
            assert_int 2 (Belt.MutableQueue.popExn queue);
            assert_array Alcotest.int [| 3; 4 |] (Belt.MutableQueue.toArray queue);
            assert_int 3 (Belt.MutableQueue.popExn queue);
            assert_array Alcotest.int [| 4 |] (Belt.MutableQueue.toArray queue);
            assert_int 4 (Belt.MutableQueue.popExn queue);
            assert_array Alcotest.int [||] (Belt.MutableQueue.toArray queue);
            assert_int 0 (Belt.MutableQueue.size queue);
            assert_bool true (does_raise Belt.MutableQueue.popExn queue));
        test "reuse after empty" (fun () ->
            let queue = Belt.MutableQueue.make () in
            Belt.MutableQueue.add queue 1;
            assert_int 1 (Belt.MutableQueue.popExn queue);
            assert_bool true (does_raise Belt.MutableQueue.popExn queue);
            Belt.MutableQueue.add queue 2;
            assert_int 2 (Belt.MutableQueue.popExn queue);
            assert_bool true (does_raise Belt.MutableQueue.popExn queue);
            assert_int 0 (Belt.MutableQueue.size queue));
        test "peekExn" (fun () ->
            let queue = Belt.MutableQueue.make () in
            Belt.MutableQueue.add queue 1;
            assert_int 1 (Belt.MutableQueue.peekExn queue);
            Belt.MutableQueue.add queue 2;
            assert_int 1 (Belt.MutableQueue.peekExn queue);
            Belt.MutableQueue.add queue 3;
            assert_int 1 (Belt.MutableQueue.peekExn queue);
            assert_int 1 (Belt.MutableQueue.popExn queue);
            assert_int 2 (Belt.MutableQueue.peekExn queue);
            assert_int 2 (Belt.MutableQueue.popExn queue);
            assert_int 3 (Belt.MutableQueue.peekExn queue);
            assert_int 3 (Belt.MutableQueue.popExn queue);
            assert_bool true (does_raise Belt.MutableQueue.peekExn queue);
            assert_bool true (does_raise Belt.MutableQueue.peekExn queue));
        test "clear" (fun () ->
            let queue = Belt.MutableQueue.make () in
            for value = 1 to 10 do
              Belt.MutableQueue.add queue value
            done;
            Belt.MutableQueue.clear queue;
            assert_int 0 (Belt.MutableQueue.size queue);
            assert_bool true (does_raise Belt.MutableQueue.popExn queue);
            assert_bool true (queue = Belt.MutableQueue.make ());
            Belt.MutableQueue.add queue 42;
            assert_int 42 (Belt.MutableQueue.popExn queue));
        test "copy" (fun () ->
            let source = Belt.MutableQueue.make () in
            for value = 1 to 10 do
              Belt.MutableQueue.add source value
            done;
            let copy = Belt.MutableQueue.copy source in
            assert_array Alcotest.int [| 1; 2; 3; 4; 5; 6; 7; 8; 9; 10 |] (Belt.MutableQueue.toArray source);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5; 6; 7; 8; 9; 10 |] (Belt.MutableQueue.toArray copy);
            assert_int 10 (Belt.MutableQueue.size source);
            assert_int 10 (Belt.MutableQueue.size copy);
            for value = 1 to 10 do
              assert_int value (Belt.MutableQueue.popExn source)
            done;
            for value = 1 to 10 do
              assert_int value (Belt.MutableQueue.popExn copy)
            done);
        test "isEmpty and size" (fun () ->
            let queue = Belt.MutableQueue.make () in
            assert_bool true (Belt.MutableQueue.isEmpty queue);
            for value = 1 to 10 do
              Belt.MutableQueue.add queue value;
              assert_int value (Belt.MutableQueue.size queue);
              assert_bool false (Belt.MutableQueue.isEmpty queue)
            done;
            for value = 10 downto 1 do
              assert_int value (Belt.MutableQueue.size queue);
              assert_bool false (Belt.MutableQueue.isEmpty queue);
              ignore (Belt.MutableQueue.popExn queue)
            done;
            assert_int 0 (Belt.MutableQueue.size queue);
            assert_bool true (Belt.MutableQueue.isEmpty queue));
        test "forEach" (fun () ->
            let queue = Belt.MutableQueue.make () in
            for value = 1 to 10 do
              Belt.MutableQueue.add queue value
            done;
            let expected = ref 1 in
            Belt.MutableQueue.forEach queue (fun value ->
                assert_int !expected value;
                incr expected));
        test "transfer" (fun () ->
            let left = Belt.MutableQueue.make () in
            let right = Belt.MutableQueue.make () in
            Belt.MutableQueue.transfer left right;
            assert_array Alcotest.int [||] (Belt.MutableQueue.toArray left);
            assert_array Alcotest.int [||] (Belt.MutableQueue.toArray right);
            for value = 1 to 4 do
              Belt.MutableQueue.add left value
            done;
            Belt.MutableQueue.transfer left right;
            assert_array Alcotest.int [||] (Belt.MutableQueue.toArray left);
            assert_array Alcotest.int [| 1; 2; 3; 4 |] (Belt.MutableQueue.toArray right);
            for value = 5 to 8 do
              Belt.MutableQueue.add right value
            done;
            Belt.MutableQueue.transfer left right;
            assert_array Alcotest.int [||] (Belt.MutableQueue.toArray left);
            assert_array Alcotest.int [| 1; 2; 3; 4; 5; 6; 7; 8 |] (Belt.MutableQueue.toArray right));
        test "transfer appends to nonempty queue" (fun () ->
            let left = Belt.MutableQueue.make () in
            let right = Belt.MutableQueue.make () in
            for value = 1 to 4 do
              Belt.MutableQueue.add left value
            done;
            for value = 5 to 8 do
              Belt.MutableQueue.add right value
            done;
            Belt.MutableQueue.transfer left right;
            let expected = [| 5; 6; 7; 8; 1; 2; 3; 4 |] in
            assert_array Alcotest.int [||] (Belt.MutableQueue.toArray left);
            assert_array Alcotest.int expected (Belt.MutableQueue.toArray right);
            assert_int
              (Belt.Array.reduce expected 0 (fun acc value -> acc - value))
              (Belt.MutableQueue.reduce right 0 (fun acc value -> acc - value)));
        test "fromArray and map" (fun () ->
            let queue = Belt.MutableQueue.fromArray [| 1; 2; 3; 4 |] in
            let mapped = Belt.MutableQueue.map queue (fun value -> value - 1) in
            assert_array Alcotest.int [| 0; 1; 2; 3 |] (Belt.MutableQueue.toArray mapped);
            assert_bool true (Belt.MutableQueue.isEmpty (Belt.MutableQueue.fromArray [||]));
            assert_bool true
              (Belt.MutableQueue.isEmpty
                 (Belt.MutableQueue.map (Belt.MutableQueue.fromArray [||]) (fun value -> value + 1))));
      ] );
  ]
