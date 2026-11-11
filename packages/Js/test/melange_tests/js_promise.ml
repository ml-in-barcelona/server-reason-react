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
let assert_pending p = match Lwt.state p with Lwt.Sleep -> () | _ -> Alcotest.fail "expected a pending promise"

let assert_settled p expected =
  match (Lwt.state p, expected) with
  | Lwt.Return v, Ok e -> ok (v = e)
  | Lwt.Fail exn, Error e -> ok (exn = e)
  | Lwt.Sleep, _ -> Alcotest.fail "expected a settled promise, got a pending one"
  | Lwt.Return _, Error _ -> Alcotest.fail "expected a rejected promise, got a fulfilled one"
  | Lwt.Fail exn, Ok _ -> Alcotest.failf "expected a fulfilled promise, got rejected with %s" (Printexc.to_string exn)

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
    test_sync "race leaves losing promises pending" (fun () ->
        let slow, resolve_slow = Lwt.task () in
        let fast, resolve_fast = Lwt.task () in
        let winner = race [| slow; fast |] in
        Lwt.wakeup resolve_fast "fast";
        assert_settled winner (Ok "fast");
        assert_pending slow;
        Lwt.wakeup resolve_slow "slow";
        assert_settled slow (Ok "slow"));
    test_sync "race of settled inputs picks the first in array order" (fun () ->
        (* node: Promise.race([Promise.reject(e), Promise.resolve(1)]) rejects with e *)
        for _ = 1 to 100 do
          assert_settled (race [| reject Not_found; resolve 1 |]) (Error Not_found);
          assert_settled (race [| resolve 1; resolve 2; reject Not_found |]) (Ok 1)
        done);
    test_sync "make ignores a second resolve" (fun () ->
        let p =
          make (fun ~resolve ~reject:_ ->
              resolve 1;
              resolve 2)
        in
        assert_settled p (Ok 1));
    test_sync "make ignores reject after resolve" (fun () ->
        let p =
          make (fun ~resolve ~reject ->
              resolve 1;
              reject Not_found)
        in
        assert_settled p (Ok 1));
    test_sync "make rejects when the executor raises" (fun () ->
        (* node: new Promise(() => { throw e }) rejects with e *)
        let p = make (fun ~resolve:_ ~reject:_ -> raise Not_found) in
        assert_settled p (Error Not_found));
    test_sync "make ignores a raise after resolve" (fun () ->
        let p =
          make (fun ~resolve ~reject:_ ->
              resolve 1;
              raise Not_found)
        in
        assert_settled p (Ok 1));
    test_sync "make ignores a late second resolve" (fun () ->
        let saved = ref (fun _ -> ()) in
        let p = make (fun ~resolve ~reject:_ -> saved := resolve) in
        assert_pending p;
        !saved 1;
        !saved 2;
        assert_settled p (Ok 1));
    test_sync "all2 rejects as soon as any input rejects" (fun () ->
        (* node: Promise.all([pending, Promise.reject(e)]) rejects with e without waiting *)
        let a, resolve_a = Lwt.wait () in
        let b, resolve_b = Lwt.wait () in
        let p = all2 (a, b) in
        Lwt.wakeup_exn resolve_b Not_found;
        assert_settled p (Error Not_found);
        Lwt.wakeup_exn resolve_a Exit;
        assert_settled p (Error Not_found));
    test_sync "all2 keeps input order when inputs settle out of order" (fun () ->
        let a, resolve_a = Lwt.wait () in
        let b, resolve_b = Lwt.wait () in
        let p = all2 (a, b) in
        Lwt.wakeup resolve_b "b";
        assert_pending p;
        Lwt.wakeup resolve_a 1;
        assert_settled p (Ok (1, "b")));
    test_sync "all3 rejects with the first rejection in time" (fun () ->
        let a, resolve_a = Lwt.wait () in
        let b, _ = Lwt.wait () in
        let c, resolve_c = Lwt.wait () in
        let p = all3 (a, b, c) in
        Lwt.wakeup_exn resolve_c Not_found;
        Lwt.wakeup_exn resolve_a Exit;
        assert_settled p (Error Not_found));
    test_sync "all4 rejects as soon as any input rejects" (fun () ->
        let d, resolve_d = Lwt.wait () in
        let p = all4 (fst (Lwt.wait ()), resolve 2, resolve 3, d) in
        Lwt.wakeup_exn resolve_d Not_found;
        assert_settled p (Error Not_found));
    test_sync "all5 keeps input order" (fun () ->
        let a, resolve_a = Lwt.wait () in
        let p = all5 (a, resolve "2", resolve 3., resolve '4', resolve [ 5 ]) in
        assert_pending p;
        Lwt.wakeup resolve_a 1;
        assert_settled p (Ok (1, "2", 3., '4', [ 5 ])));
    test_sync "all3 rejects at once inside a promise callback" (fun () ->
        let trigger, go = Lwt.wait () in
        let state = ref Lwt.Sleep in
        Lwt.on_success trigger (fun () ->
            let c, resolve_c = Lwt.wait () in
            let p = all3 (fst (Lwt.wait ()), fst (Lwt.wait ()), c) in
            Lwt.wakeup_exn resolve_c Not_found;
            state := Lwt.state p);
        Lwt.wakeup go ();
        match !state with Lwt.Fail Not_found -> () | _ -> Alcotest.fail "expected a rejected promise");
    test_sync "all6 keeps input order" (fun () ->
        let f, resolve_f = Lwt.wait () in
        let p = all6 (resolve 1, resolve "2", resolve 3., resolve '4', resolve [ 5 ], f) in
        assert_pending p;
        Lwt.wakeup resolve_f (Some 6);
        assert_settled p (Ok (1, "2", 3., '4', [ 5 ], Some 6)));
    test_sync "all rejects as soon as any input rejects" (fun () ->
        let a, resolve_a = Lwt.wait () in
        let b, resolve_b = Lwt.wait () in
        let p = all [| a; b |] in
        Lwt.wakeup_exn resolve_b Not_found;
        assert_settled p (Error Not_found);
        Lwt.wakeup resolve_a 1;
        assert_settled p (Error Not_found));
    test_sync "all keeps input order when inputs settle out of order" (fun () ->
        let a, resolve_a = Lwt.wait () in
        let b, resolve_b = Lwt.wait () in
        let c, resolve_c = Lwt.wait () in
        let p = all [| a; b; c |] in
        Lwt.wakeup resolve_c 3;
        Lwt.wakeup resolve_a 1;
        assert_pending p;
        Lwt.wakeup resolve_b 2;
        assert_settled p (Ok [| 1; 2; 3 |]));
    test_sync "all of settled rejections picks the first in array order" (fun () ->
        (* node: Promise.all([Promise.reject(a), Promise.reject(b)]) rejects with a *)
        assert_settled (all [| resolve 1; reject Not_found; reject Exit |]) (Error Not_found));
    test_sync "all [||] fulfils with [||]" (fun () ->
        (* node: Promise.all([]) fulfils with [] *)
        assert_settled (all [||]) (Ok [||]));
    test_sync "then_ turns a raising callback into a rejection" (fun () ->
        (* node: Promise.resolve(1).then(() => { throw e }) rejects with e *)
        let p = resolve 1 |> then_ (fun _ -> raise Not_found) in
        assert_settled p (Error Not_found));
    test_sync "catch turns a raising handler into a rejection" (fun () ->
        (* node: Promise.reject(a).catch(() => { throw b }) rejects with b *)
        let p = reject Not_found |> catch (fun _ -> raise Exit) in
        assert_settled p (Error Exit));
  ]
