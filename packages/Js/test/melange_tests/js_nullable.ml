open Helpers

let ok cond = assert_true "expected true" cond
let f x y = Js.Nullable.return (x + y)

let tests =
  [
    test "isNullable (return 3) is false" (fun () -> assert_bool (Js.Nullable.isNullable (Js.Nullable.return 3)) false);
    test "isNullable (f 1 2) is false" (fun () -> assert_bool (Js.Nullable.isNullable (f 1 2)) false);
    test "isNullable null is true" (fun () -> assert_bool (Js.Nullable.isNullable Js.Nullable.null) true);
    test "shadowed return is not nullable" (fun () ->
        let null2 = Js.Nullable.return 3 in
        let null = null2 in
        assert_bool (Js.Nullable.isNullable null) false);
    test "map/bind/iter" (fun () ->
        ok (Js.Nullable.map (Js.Nullable.return 2) ~f:(fun n -> n * 2) = Js.Nullable.return 4);
        ok (Js.Nullable.bind Js.Nullable.null ~f:(fun v -> Js.Nullable.return v) = Js.Nullable.null);
        let hit = ref 0 in
        Js.Nullable.iter (Js.Nullable.return 5) ~f:(fun v -> hit := v);
        assert_int !hit 5);
  ]
