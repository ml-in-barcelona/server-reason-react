(** Ported from Melange's test suite: jscomp/test/js_promise_basic_test.ml (melange 6.0.1-54).

    Js.Promise.t is Lwt.t natively, so each promise chain is built with the Js.Promise API and awaited inside an
    Alcotest_lwt test case. *)

open Helpers
open Js.Promise

let test title fn = Alcotest_lwt.test_case title `Quick (fun _switch () -> fn ())
let test_sync title fn = Alcotest_lwt.test_case_sync title `Quick fn
let ok cond = assert_true "expected true" cond
let fail _ = assert false
let h = resolve ()

(* Melange uses [(function[@mel.open] Not_found -> 0)]; natively [Js.Promise.error] is [exn], so a plain match works. *)
let assert_is_not_found (x : Js.Promise.error) = match x with Not_found -> h | _ -> assert false
let is_not_found (error : exn) = match error with Not_found -> true | _ -> false
let twop = resolve 2

let tests =
  [
    test "thenTest" (fun () ->
        let p = resolve 4 in
        p |> then_ (fun x -> resolve @@ ok (x = 4)));
    test "andThenTest" (fun () ->
        let p = resolve 6 in
        p |> then_ (fun _ -> resolve 12) |> then_ (fun y -> resolve @@ ok (y = 12)));
    test "catchTest" (fun () ->
        let p = reject Not_found in
        p |> then_ fail |> catch (fun error -> assert_is_not_found error));
    test "orResolvedTest" (fun () ->
        let p = resolve 42 in
        p |> catch (fun _ -> resolve 22) |> then_ (fun value -> resolve @@ ok (value = 42)) |> catch fail);
    test "orRejectedTest" (fun () ->
        let p = reject Not_found in
        p |> catch (fun _ -> resolve 22) |> then_ (fun value -> resolve @@ ok (value = 22)) |> catch fail);
    test "orElseResolvedTest" (fun () ->
        let p = resolve 42 in
        p |> catch (fun _ -> resolve 22) |> then_ (fun value -> resolve @@ ok (value = 42)) |> catch fail);
    test "orElseRejectedResolveTest" (fun () ->
        let p = reject Not_found in
        p |> catch (fun _ -> resolve 22) |> then_ (fun value -> resolve @@ ok (value = 22)) |> catch fail);
    test "orElseRejectedRejectTest" (fun () ->
        let p = reject Not_found in
        p
        |> catch (fun _ -> reject Stack_overflow)
        |> then_ fail
        |> catch (fun error -> match error with Stack_overflow -> h | _ -> assert false));
    test "resolveTest" (fun () ->
        let p1 = resolve 10 in
        p1 |> then_ (fun x -> resolve @@ ok (x = 10)));
    test "rejectTest" (fun () ->
        let p = reject Not_found in
        p |> catch (fun error -> assert_is_not_found error));
    test "thenCatchChainResolvedTest" (fun () ->
        let p = resolve 20 in
        p |> then_ (fun value -> resolve @@ ok (value = 20)) |> catch fail);
    test "thenCatchChainRejectedTest" (fun () ->
        let p = reject Not_found in
        p |> then_ fail |> catch (fun error -> assert_is_not_found error));
    test "allResolvedTest" (fun () ->
        let p1 = resolve 1 in
        let p2 = resolve 2 in
        let p3 = resolve 3 in
        let promises = [| p1; p2; p3 |] in
        all promises
        |> then_ (fun resolved ->
            ok (resolved.(0) = 1);
            ok (resolved.(1) = 2);
            ok (resolved.(2) = 3);
            h));
    test "allRejectTest" (fun () ->
        let p1 = resolve 1 in
        let p2 = resolve 3 in
        let p3 = reject Not_found in
        let promises = [| p1; p2; p3 |] in
        all promises |> then_ fail
        |> catch (fun error ->
            (* melange needs [Obj.magic error]; natively [error] is already [exn] *)
            ok (is_not_found error);
            h));
    test "raceTest" (fun () ->
        let p1 = resolve "first" in
        let p2 = resolve "second" in
        let p3 = resolve "third" in
        let promises = [| p1; p2; p3 |] in
        race promises |> then_ (fun _resolved -> h) |> catch fail);
    test "createPromiseRejectTest" (fun () ->
        make (fun ~resolve:_ ~reject -> reject Not_found)
        |> catch (fun error ->
            ok (is_not_found error);
            h));
    test "createPromiseFulfillTest" (fun () ->
        make (fun ~resolve ~reject:_ -> resolve "success")
        |> then_ (fun resolved ->
            ok (resolved = "success");
            h)
        |> catch fail);
    test "all2" (fun () ->
        Js.Promise.all2 (Js.Promise.resolve 2, Js.Promise.resolve 3)
        |> Js.Promise.then_ (fun (a, b) ->
            assert_int a 2;
            assert_int b 3;
            Js.Promise.resolve ()));
    (* Mt.from_promise_suites *)
    test "twop Eq(x, 2)" (fun () -> twop |> then_ (fun x -> resolve @@ assert_int x 2));
    test "twop Neq(x, 3)" (fun () -> twop |> then_ (fun x -> resolve @@ ok (x <> 3)));
    test_sync "race [||] stays pending like JS" (fun () ->
        (* node: Promise.race([]) never settles *)
        match Lwt.state (Js.Promise.race [||]) with
        | Lwt.Sleep -> ()
        | _ -> Alcotest.fail "expected a forever-pending promise");
  ]
