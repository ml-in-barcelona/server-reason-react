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
  let%lwt _ = run ~tags:[ "user:1" ] "one" in
  let%lwt _ = run ~tags:[ "user:2" ] "two" in
  React.Cache.expire ~tag:"user:1";
  let%lwt one = run ~tags:[ "user:1" ] "one" in
  let%lwt two = run ~tags:[ "user:2" ] "two" in
  assert_string one "one-3";
  assert_string two "two-2";
  assert_int !calls 3;
  Lwt.return ()

let expire_drops_request_entries () =
  let calls, run = counting () in
  React.Cache.request_scope (fun () ->
      let%lwt _ = run ~tags:[ "t" ] "a" in
      React.Cache.expire ~tag:"t";
      let%lwt value = run ~tags:[ "t" ] "a" in
      assert_string value "a-2";
      assert_int !calls 2;
      Lwt.return ())

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
  raises "zero max" (fun () -> React.Cache.make ~name:"t" ~scope:Process ~max:0 ())

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
      lwt_test "process errors retry" process_errors_retry;
      lwt_test "process max evicts the least recent" process_max_evicts_least_recent;
      lwt_test "a kept process error expires with ttl" process_kept_error_expires_with_ttl;
      lwt_test "cancelling a request caller keeps the shared promise"
        cancelling_a_request_caller_keeps_the_shared_promise;
      lwt_test "process entry runs outside the request" process_entry_runs_outside_the_request;
      lwt_test "cancelling a caller keeps the shared promise" cancelling_a_caller_keeps_the_shared_promise;
      test "keys are injective" keys_are_injective;
      test "make rejects bad settings" make_rejects_bad_settings;
    ] )
