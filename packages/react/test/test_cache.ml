let lwt_test title fn = Alcotest.test_case title `Quick (fun () -> Lwt_main.run (fn ()))
let test title fn = Alcotest.test_case title `Quick fn
let assert_int left right = Alcotest.check Alcotest.int "should be equal" right left
let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let contains text part =
  let length = String.length part in
  let rec from index =
    index + length <= String.length text && (String.sub text index length = part || from (index + 1))
  in
  from 0

let counting ?(scope = React.Cache.Request) ?ttl ?max ?errors () =
  let calls = ref 0 in
  let cache = React.Cache.make ~name:"test" ~scope ?ttl ?max ?errors () in
  let run ?tags key =
    React.Cache.run cache ~key ?tags (fun () ->
        incr calls;
        Lwt.return (key ^ "-" ^ string_of_int !calls))
  in
  (calls, run)

let request_scope_runs_once () =
  let calls, run = counting () in
  React.Cache.request_scope (fun () ->
      let%lwt first = run "a" in
      let%lwt second = run "a" in
      let%lwt other = run "b" in
      assert_string first "a-1";
      assert_string second "a-1";
      assert_string other "b-2";
      assert_int !calls 2;
      Lwt.return ())

let calls_outside_a_scope_always_run () =
  let calls, run = counting () in
  let%lwt _ = run "a" in
  let%lwt _ = run "a" in
  assert_int !calls 2;
  Lwt.return ()

let pending_calls_share_one_promise () =
  let calls = ref 0 in
  let cache = React.Cache.make ~name:"test" () in
  let waiter, wakener = Lwt.wait () in
  let run () =
    React.Cache.run cache ~key:"a" (fun () ->
        incr calls;
        waiter)
  in
  React.Cache.request_scope (fun () ->
      let first = run () in
      let second = run () in
      Lwt.wakeup wakener "done";
      let%lwt first = first and second = second in
      assert_string first "done";
      assert_string second "done";
      assert_int !calls 1;
      Lwt.return ())

let concurrent_requests_do_not_share () =
  let calls, run = counting () in
  let request () =
    React.Cache.request_scope (fun () ->
        let%lwt () = Lwt.pause () in
        run "a")
  in
  let%lwt first = request () and second = request () in
  assert_int !calls 2;
  Alcotest.(check bool) "different entries" true (first <> second);
  Lwt.return ()

let render_joins_open_scope () =
  let calls, run = counting () in
  let component =
    React.Async_component
      ( "reader",
        fun () ->
          let%lwt value = run "a" in
          Lwt.return (React.string value) )
  in
  React.Cache.request_scope (fun () ->
      let%lwt loaded = run "a" in
      let%lwt html, subscribe = ReactServerDOM.render_html component in
      let%lwt () = subscribe (fun _ -> Lwt.return ()) in
      assert_string loaded "a-1";
      Alcotest.(check bool) "render read the loader's entry" true (contains html "a-1");
      assert_int !calls 1;
      Lwt.return ())

let render_opens_a_scope_when_none_is_open () =
  let calls, run = counting () in
  let reader =
    React.Async_component
      ( "reader",
        fun () ->
          let%lwt value = run "a" in
          Lwt.return (React.string value) )
  in
  let%lwt _html, subscribe = ReactServerDOM.render_html (React.list [ reader; reader ]) in
  let%lwt () = subscribe (fun _ -> Lwt.return ()) in
  assert_int !calls 1;
  Lwt.return ()

let request_scope_never_joins () =
  let calls, run = counting () in
  React.Cache.request_scope (fun () ->
      let%lwt _ = run "a" in
      let%lwt _ = React.Cache.request_scope (fun () -> run "a") in
      assert_int !calls 2;
      Lwt.return ())

let request_errors_are_kept () =
  let calls = ref 0 in
  let cache = React.Cache.make ~name:"test" () in
  let run () =
    React.Cache.run cache ~key:"a" (fun () ->
        incr calls;
        Lwt.fail (Failure "boom"))
  in
  React.Cache.request_scope (fun () ->
      let%lwt first = Lwt_result.catch run in
      let%lwt second = Lwt_result.catch run in
      Alcotest.(check bool) "both failed" true (Result.is_error first && Result.is_error second);
      assert_int !calls 1;
      Lwt.return ())

let process_scope_crosses_requests () =
  let calls, run = counting ~scope:Process () in
  let%lwt first = React.Cache.request_scope (fun () -> run "a") in
  let%lwt second = React.Cache.request_scope (fun () -> run "a") in
  let%lwt outside = run "a" in
  assert_string first "a-1";
  assert_string second "a-1";
  assert_string outside "a-1";
  assert_int !calls 1;
  Lwt.return ()

let process_ttl_runs_again () =
  let calls, run = counting ~scope:Process ~ttl:0.05 () in
  let%lwt _ = run "a" in
  let%lwt _ = run "a" in
  assert_int !calls 1;
  let%lwt () = Lwt_unix.sleep 0.1 in
  let%lwt value = run "a" in
  assert_string value "a-2";
  assert_int !calls 2;
  Lwt.return ()

let expire_drops_tagged_entries () =
  let calls, run = counting ~scope:Process () in
  let%lwt _ = run ~tags:[ `User 1 ] "one" in
  let%lwt _ = run ~tags:[ `User 2 ] "two" in
  React.Cache.expire ~tag:(`User 1);
  let%lwt one = run ~tags:[ `User 1 ] "one" in
  let%lwt two = run ~tags:[ `User 2 ] "two" in
  assert_string one "one-3";
  assert_string two "two-2";
  assert_int !calls 3;
  Lwt.return ()

let expire_drops_request_entries () =
  let calls, run = counting () in
  React.Cache.request_scope (fun () ->
      let%lwt _ = run ~tags:[ `User 1 ] "a" in
      let%lwt _ = run ~tags:[ `User 2 ] "b" in
      React.Cache.expire ~tag:(`User 1);
      let%lwt a = run ~tags:[ `User 1 ] "a" in
      let%lwt b = run ~tags:[ `User 2 ] "b" in
      assert_string a "a-3";
      assert_string b "b-2";
      assert_int !calls 3;
      Lwt.return ())

let expire_tag_without_payload () =
  let calls, run = counting ~scope:Process () in
  let%lwt _ = run ~tags:[ `All; `User 1 ] "a" in
  let%lwt _ = run ~tags:[ `All ] "b" in
  let%lwt _ = run ~tags:[ `Other ] "c" in
  React.Cache.expire ~tag:`All;
  let%lwt _ = run "a" in
  let%lwt _ = run "b" in
  let%lwt c = run "c" in
  assert_string c "c-3";
  assert_int !calls 5;
  Lwt.return ()

let expire_tag_without_payload_in_request () =
  let calls, run = counting () in
  React.Cache.request_scope (fun () ->
      let%lwt _ = run ~tags:[ `All ] "a" in
      React.Cache.expire ~tag:`All;
      let%lwt value = run ~tags:[ `All ] "a" in
      assert_string value "a-2";
      assert_int !calls 2;
      Lwt.return ())

let expire_compares_the_whole_payload () =
  let calls, run = counting ~scope:Process () in
  let%lwt _ = run ~tags:[ `Team ("acme", 1) ] "a" in
  let%lwt _ = run ~tags:[ `Team ("acme", 2) ] "b" in
  let%lwt _ = run ~tags:[ `Team ("acm", 1) ] "c" in
  let%lwt _ = run ~tags:[ `Group ("acme", 1) ] "d" in
  React.Cache.expire ~tag:(`Team ("acme", 1));
  let%lwt a = run "a" in
  let%lwt b = run "b" in
  let%lwt c = run "c" in
  let%lwt d = run "d" in
  assert_string a "a-5";
  assert_string b "b-2";
  assert_string c "c-3";
  assert_string d "d-4";
  assert_int !calls 5;
  Lwt.return ()

type filter = { term : string; pages : int list; limit : int option; score : float }

let expire_matches_structured_payloads () =
  let calls, run = counting ~scope:Process () in
  let filter = { term = "a"; pages = [ 1; 2 ]; limit = None; score = 0. } in
  let%lwt _ = run ~tags:[ `Search filter ] "a" in
  let%lwt _ = run ~tags:[ `Search { filter with limit = Some 0 } ] "b" in
  React.Cache.expire ~tag:(`Search { term = "a"; pages = [ 1; 2 ]; limit = None; score = -0. });
  let%lwt a = run "a" in
  let%lwt b = run "b" in
  assert_string a "a-3";
  assert_string b "b-2";
  assert_int !calls 3;
  Lwt.return ()

let tag_is_a_snapshot () =
  let calls, run = counting ~scope:Process () in
  let counter = ref 1 in
  let%lwt _ = run ~tags:[ `Counter counter ] "a" in
  counter := 2;
  React.Cache.expire ~tag:(`Counter (ref 2));
  let%lwt kept = run "a" in
  React.Cache.expire ~tag:(`Counter (ref 1));
  let%lwt dropped = run "a" in
  assert_string kept "a-1";
  assert_string dropped "a-2";
  assert_int !calls 2;
  Lwt.return ()

let unsupported_tags_raise () =
  let calls, run = counting ~scope:Process () in
  let rejects name f =
    match f () with
    | () -> Alcotest.failf "%s: expected Invalid_argument" name
    | exception Invalid_argument message ->
        Alcotest.(check bool) (name ^ " message") true (contains message "tag payload")
  in
  let%lwt _ = run ~tags:[ `Plain ] "a" in
  rejects "run with a function" (fun () -> ignore (run ~tags:[ `Fn (fun () -> ()) ] "b"));
  rejects "expire with a function" (fun () -> React.Cache.expire ~tag:(`Fn print_endline));
  rejects "int64" (fun () -> React.Cache.expire ~tag:(`Id 1L));
  rejects "object" (fun () -> React.Cache.expire ~tag:(`Obj (object end)));
  rejects "lazy" (fun () -> React.Cache.expire ~tag:(`Lazy (lazy (print_endline "x"))));
  let rec cycle = 1 :: cycle in
  rejects "cyclic" (fun () -> React.Cache.expire ~tag:(`Cycle cycle));
  assert_int !calls 1;
  React.Cache.expire ~tag:`Plain;
  let%lwt a = run "a" in
  assert_string a "a-2";
  Lwt.return ()

let process_errors_retry () =
  let calls = ref 0 in
  let cache = React.Cache.make ~name:"test" ~scope:Process () in
  let run () =
    React.Cache.run cache ~key:"a" (fun () ->
        incr calls;
        if !calls = 1 then Lwt.fail (Failure "boom") else Lwt.return "ok")
  in
  let%lwt first = Lwt_result.catch run in
  let%lwt second = run () in
  Alcotest.(check bool) "first failed" true (Result.is_error first);
  assert_string second "ok";
  assert_int !calls 2;
  Lwt.return ()

let process_kept_error_expires_with_ttl () =
  let calls = ref 0 in
  let cache = React.Cache.make ~name:"test" ~scope:Process ~ttl:0.05 ~errors:Keep () in
  let run () =
    React.Cache.run cache ~key:"a" (fun () ->
        incr calls;
        if !calls = 1 then Lwt.fail (Failure "boom") else Lwt.return "ok")
  in
  let%lwt first = Lwt_result.catch run in
  let%lwt second = Lwt_result.catch run in
  Alcotest.(check bool) "error kept" true (Result.is_error first && Result.is_error second);
  assert_int !calls 1;
  let%lwt () = Lwt_unix.sleep 0.1 in
  let%lwt third = run () in
  assert_string third "ok";
  assert_int !calls 2;
  Lwt.return ()

let cancelling_a_request_caller_keeps_the_shared_promise () =
  let calls = ref 0 in
  let cache = React.Cache.make ~name:"test" () in
  let waiter, wakener = Lwt.task () in
  let run () =
    React.Cache.run cache ~key:"a" (fun () ->
        incr calls;
        waiter)
  in
  React.Cache.request_scope (fun () ->
      let first = run () in
      Lwt.cancel first;
      let second = run () in
      Lwt.wakeup wakener "done";
      let%lwt second = second in
      assert_string second "done";
      assert_int !calls 1;
      Lwt.return ())

let process_max_evicts_least_recent () =
  let calls, run = counting ~scope:Process ~max:2 () in
  let%lwt _ = run "a" in
  let%lwt _ = run "b" in
  let%lwt _ = run "a" in
  let%lwt _ = run "c" in
  assert_int !calls 3;
  let%lwt a = run "a" in
  let%lwt b = run "b" in
  assert_string a "a-1";
  assert_string b "b-4";
  Lwt.return ()

let process_entry_runs_outside_the_request () =
  let inner_calls, inner = counting () in
  let outer = React.Cache.make ~name:"outer" ~scope:Process () in
  React.Cache.request_scope (fun () ->
      let%lwt _ = inner "x" in
      let%lwt _ = React.Cache.run outer ~key:"k" (fun () -> inner "x") in
      assert_int !inner_calls 2;
      Lwt.return ())

let cancelling_a_caller_keeps_the_shared_promise () =
  let calls = ref 0 in
  let cache = React.Cache.make ~name:"test" ~scope:Process () in
  let waiter, wakener = Lwt.task () in
  let run () =
    React.Cache.run cache ~key:"a" (fun () ->
        incr calls;
        waiter)
  in
  let first = run () in
  Lwt.cancel first;
  let second = run () in
  Lwt.wakeup wakener "done";
  let%lwt second = second in
  assert_string second "done";
  assert_int !calls 1;
  Lwt.return ()

let hanging cache calls =
  React.Cache.run cache ~key:"a" (fun () ->
      incr calls;
      fst (Lwt.task ()))

let timed_out promise =
  Lwt.catch
    (fun () -> Lwt.map (fun _ -> false) promise)
    (function React.Cache.Timeout "slow" -> Lwt.return true | exn -> Lwt.reraise exn)

let process_timeout_fails_and_retries () =
  let calls = ref 0 in
  let cache = React.Cache.make ~name:"slow" ~scope:Process ~timeout:0.01 () in
  let first = hanging cache calls in
  let joined = hanging cache calls in
  let%lwt first = timed_out first and joined = timed_out joined in
  Alcotest.(check bool) "first times out" true first;
  Alcotest.(check bool) "joined caller times out" true joined;
  assert_int !calls 1;
  let%lwt again = timed_out (hanging cache calls) in
  Alcotest.(check bool) "retry times out" true again;
  assert_int !calls 2;
  Lwt.return ()

let timeout_cancels_the_function () =
  let cancelled = ref false in
  let cache = React.Cache.make ~name:"slow" ~scope:Process ~timeout:0.01 () in
  let promise =
    React.Cache.run cache ~key:"a" (fun () ->
        let waiter, _ = Lwt.task () in
        Lwt.on_cancel waiter (fun () -> cancelled := true);
        waiter)
  in
  let%lwt _ = timed_out promise in
  Alcotest.(check bool) "cancelled" true !cancelled;
  Lwt.return ()

let request_timeout_is_kept () =
  let calls = ref 0 in
  let cache = React.Cache.make ~name:"slow" ~timeout:0.01 () in
  React.Cache.request_scope (fun () ->
      let%lwt first = timed_out (hanging cache calls) in
      let%lwt second = timed_out (hanging cache calls) in
      Alcotest.(check bool) "first" true first;
      Alcotest.(check bool) "second" true second;
      assert_int !calls 1;
      Lwt.return ())

let fast_calls_ignore_the_timeout () =
  let cache = React.Cache.make ~name:"fast" ~scope:Process ~timeout:5. () in
  let%lwt value = React.Cache.run cache ~key:"a" (fun () -> Lwt.bind (Lwt.pause ()) (fun () -> Lwt.return "done")) in
  assert_string value "done";
  let%lwt cached = React.Cache.run cache ~key:"a" (fun () -> Lwt.return "again") in
  assert_string cached "done";
  Lwt.return ()

let keys_are_injective () =
  let open React.Cache.Key in
  Alcotest.(check bool) "parts" true (parts [ "a"; "bc" ] <> parts [ "ab"; "c" ]);
  Alcotest.(check bool) "option" true (option string None <> option string (Some ""));
  Alcotest.(check bool) "nested option" true (option (option int) None <> option (option int) (Some None));
  Alcotest.(check bool) "list" true (list string [ "a"; "b" ] <> list string [ "ab" ]);
  Alcotest.(check bool) "float zero" true (float 0. <> float (-0.))

let make_rejects_bad_settings () =
  let raises name f =
    match f () with
    | (_ : string React.Cache.t) -> Alcotest.failf "%s: expected Invalid_argument" name
    | exception Invalid_argument _ -> ()
  in
  raises "ttl on Request" (fun () -> React.Cache.make ~name:"t" ~ttl:1. ());
  raises "zero ttl" (fun () -> React.Cache.make ~name:"t" ~scope:Process ~ttl:0. ());
  raises "zero max" (fun () -> React.Cache.make ~name:"t" ~scope:Process ~max:0 ());
  raises "zero timeout" (fun () -> React.Cache.make ~name:"t" ~timeout:0. ())

let tests =
  ( "React.Cache",
    [
      lwt_test "request scope runs once per key" request_scope_runs_once;
      lwt_test "calls outside a scope always run" calls_outside_a_scope_always_run;
      lwt_test "pending calls share one promise" pending_calls_share_one_promise;
      lwt_test "concurrent requests do not share" concurrent_requests_do_not_share;
      lwt_test "render joins the open scope" render_joins_open_scope;
      lwt_test "render opens a scope when none is open" render_opens_a_scope_when_none_is_open;
      lwt_test "request_scope never joins" request_scope_never_joins;
      lwt_test "request errors are kept" request_errors_are_kept;
      lwt_test "process scope crosses requests" process_scope_crosses_requests;
      lwt_test "process ttl runs again" process_ttl_runs_again;
      lwt_test "expire drops tagged process entries" expire_drops_tagged_entries;
      lwt_test "expire drops tagged request entries" expire_drops_request_entries;
      lwt_test "expire a tag without payload" expire_tag_without_payload;
      lwt_test "expire a tag without payload in a request" expire_tag_without_payload_in_request;
      lwt_test "expire compares the whole payload" expire_compares_the_whole_payload;
      lwt_test "expire matches structured payloads" expire_matches_structured_payloads;
      lwt_test "a tag is a snapshot" tag_is_a_snapshot;
      lwt_test "unsupported tags raise" unsupported_tags_raise;
      lwt_test "process errors retry" process_errors_retry;
      lwt_test "process max evicts the least recent" process_max_evicts_least_recent;
      lwt_test "a kept process error expires with ttl" process_kept_error_expires_with_ttl;
      lwt_test "cancelling a request caller keeps the shared promise"
        cancelling_a_request_caller_keeps_the_shared_promise;
      lwt_test "process entry runs outside the request" process_entry_runs_outside_the_request;
      lwt_test "cancelling a caller keeps the shared promise" cancelling_a_caller_keeps_the_shared_promise;
      lwt_test "process timeout fails and retries" process_timeout_fails_and_retries;
      lwt_test "timeout cancels the function" timeout_cancels_the_function;
      lwt_test "request timeout is kept" request_timeout_is_kept;
      lwt_test "fast calls ignore the timeout" fast_calls_ignore_the_timeout;
      test "keys are injective" keys_are_injective;
      test "make rejects bad settings" make_rejects_bad_settings;
    ] )
