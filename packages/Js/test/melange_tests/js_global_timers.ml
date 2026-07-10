(** Tests for Js.Global timers (Lwt-backed). Semantics follow WHATWG/node timers: callbacks fire asynchronously after
    the delay on the event loop; clearTimeout/clearInterval cancel pending callbacks. *)

let test title fn = Alcotest_lwt.test_case title `Quick (fun _switch () -> fn ())

let tests =
  [
    test "setTimeout fires after the delay" (fun () ->
        let hit = ref false in
        let _id = Js.Global.setTimeout ~f:(fun () -> hit := true) 10 in
        if !hit then Alcotest.fail "callback ran synchronously";
        let%lwt () = Lwt_unix.sleep 0.05 in
        Alcotest.(check bool) "fired" true !hit;
        Lwt.return_unit);
    test "clearTimeout cancels the callback" (fun () ->
        let hit = ref false in
        let id = Js.Global.setTimeout ~f:(fun () -> hit := true) 10 in
        Js.Global.clearTimeout id;
        let%lwt () = Lwt_unix.sleep 0.05 in
        Alcotest.(check bool) "not fired" false !hit;
        Lwt.return_unit);
    test "setTimeout with 0 delay runs asynchronously" (fun () ->
        let hit = ref false in
        let _id = Js.Global.setTimeout ~f:(fun () -> hit := true) 0 in
        if !hit then Alcotest.fail "callback ran synchronously";
        let%lwt () = Lwt_unix.sleep 0.02 in
        Alcotest.(check bool) "fired" true !hit;
        Lwt.return_unit);
    test "setInterval fires repeatedly until cleared" (fun () ->
        let count = ref 0 in
        let id = Js.Global.setInterval ~f:(fun () -> incr count) 10 in
        let%lwt () = Lwt_unix.sleep 0.055 in
        Js.Global.clearInterval id;
        let fired = !count in
        Alcotest.(check bool) (Printf.sprintf "fired repeatedly (%d)" fired) true (fired >= 2);
        let%lwt () = Lwt_unix.sleep 0.03 in
        Alcotest.(check int) "no more callbacks after clearInterval" fired !count;
        Lwt.return_unit);
    test "setTimeoutFloat accepts fractional milliseconds" (fun () ->
        let hit = ref false in
        let _id = Js.Global.setTimeoutFloat ~f:(fun () -> hit := true) 5.5 in
        let%lwt () = Lwt_unix.sleep 0.03 in
        Alcotest.(check bool) "fired" true !hit;
        Lwt.return_unit);
  ]
