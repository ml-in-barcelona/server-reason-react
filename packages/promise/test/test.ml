let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let assert_list ty left right =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_array ty left right =
  Alcotest.check (Alcotest.array ty) "should be equal" right left

let assert_array_int = assert_array Alcotest.int
let case title fn = Alcotest_lwt.test_case title `Quick fn
let promise_to_lwt (p : 'a Promise.t) : 'a Lwt.t = Obj.magic p

let resolve _switch () =
  let value = "hi" in
  let resolved = Promise.resolve value in
  resolved |> promise_to_lwt |> Lwt.map (assert_string value)

let all _switch () =
  let p0 = Promise.make (fun ~resolve ~reject:_ -> resolve 5) in
  let p1 = Promise.make (fun ~resolve ~reject:_ -> resolve 10) in
  let resolved = Promise.all [| p0; p1 |] in
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
    Promise.make (fun ~resolve ~reject:_ ->
        set_timeout (fun () -> resolve 5) 0.5)
  in
  let p1 =
    Promise.make (fun ~resolve ~reject:_ ->
        set_timeout (fun () -> resolve 99) 0.3)
  in
  let resolved = Promise.all [| p0; p1 |] in
  resolved |> promise_to_lwt |> Lwt.map (assert_array_int [| 5; 99 |])

let race_async _switch () =
  let p0 =
    Promise.make (fun ~resolve ~reject:_ ->
        set_timeout (fun () -> resolve "second") 0.5)
  in
  let p1 =
    Promise.make (fun ~resolve ~reject:_ ->
        set_timeout (fun () -> resolve "first") 0.3)
  in
  let resolved = Promise.race [| p0; p1 |] in
  resolved |> promise_to_lwt |> Lwt.map (assert_string "first")

let tests =
  ( "Promise",
    [
      case "resolve" resolve;
      case "all" all;
      case "all_async" all_async;
      case "race_async" race_async;
    ] )

let () = Alcotest_lwt.run "Promise" [ tests ] |> Lwt_main.run
