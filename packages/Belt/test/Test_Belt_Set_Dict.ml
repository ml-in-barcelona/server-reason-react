let suites =
  [
    ( "Set.Dict",
      [
        test "forEach and every" (fun () ->
            let values = Belt.Set.fromArray (shuffled_range 0 20) ~id:(module IntCmp) in
            let collected = ref [] in
            Belt.Set.Dict.forEach (Belt.Set.getData values) (fun value -> collected := value :: !collected);
            assert_list Alcotest.int (Array.to_list (inclusive_range 0 20)) (List.rev !collected);
            assert_bool true (Belt.Set.Dict.every (Belt.Set.getData values) (fun value -> value < 24)));
      ] );
  ]
