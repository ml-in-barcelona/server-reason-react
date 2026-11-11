let test title fn = Alcotest.test_case title `Quick fn
let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left
let assert_int left right = Alcotest.check Alcotest.int "should be equal" right left

let use_state_doesnt_fire () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let state, setState = React.useState (fun () -> "foo") in
          (* You wouldn't have this code in prod, but just for testing purposes *)
          setState (fun _prev -> "bar");
          React.createElement "div" [] [ React.string state ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

let use_sync_external_store_with_server () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let value =
            React.useSyncExternalStoreWithServer
              ~getServerSnapshot:(fun () -> "foo")
              ~subscribe:(fun _ () -> ())
              ~getSnapshot:(fun _ -> "bar")
          in
          React.createElement "div" [] [ React.string value ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

let use_effect_doesnt_fire () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let ref = React.useRef "foo" in
          React.useEffect0 (fun () ->
              ref.current <- "bar";
              None);
          React.createElement "div" [] [ React.string ref.current ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

let compatibility_effects_dont_fire () =
  let value = React.useRef "initial" in
  let callback () =
    value.current <- "changed";
    None
  in
  React.useInsertionEffect0 callback;
  React.useLayoutEffect callback;
  assert_string value.current "initial"

let compatibility_rendering_helpers () =
  let component ?key:_ text = React.string text in
  let app = React.StrictMode.make (React.StrictMode.makeProps ~children:(React.jsx component "content") ()) in
  assert_string (ReactDOM.renderToStaticMarkup app) "content";
  let transitioned = ref false in
  React.startTransition (fun () -> transitioned := true);
  Alcotest.(check bool) "runs the transition callback" true !transitioned

let is_valid_element () =
  let host = React.createElement "div" [] [] in
  Alcotest.(check bool) "host element" true (React.isValidElement host);
  Alcotest.(check bool) "text" false (React.isValidElement (React.string "text"));
  Alcotest.(check bool) "array" false (React.isValidElement (React.array [| host |]));
  Alcotest.(check bool) "null" false (React.isValidElement React.null)

let async_transition_runs_callback () =
  let transitioned = ref false in
  let _, start_transition = React.useTransitionAsync () in
  let _promise = start_transition (fun () -> transitioned := true) in
  Alcotest.(check bool) "runs the transition callback" true !transitioned

let compatible_ref_and_forward_ref () =
  let ref = React.useRef "initial" in
  assert_string (React.Ref.current ref) "initial";
  React.Ref.setCurrent ref "updated";
  assert_string ref.current "updated";
  let component = React.forwardRef (fun text _ref -> React.string text) in
  assert_string (ReactDOM.renderToStaticMarkup (React.jsx component "forwarded")) "forwarded"

let experimental_hooks () =
  let state, set_optimistic = React.Experimental.useOptimistic "initial" (fun _state value -> value) in
  set_optimistic "updated";
  assert_string state "initial";
  let state, _action, pending = React.Experimental.useActionState (fun _state _form_data -> ()) "initial" in
  assert_string state "initial";
  Alcotest.(check bool) "is not pending" false pending

module Gap = struct
  let make ~children =
    React.Children.map children (fun element ->
        if element = React.null then React.null
        else React.createElement "div" [ React.JSX.String ("class", "className", "divider") ] [ element ])
end

let children_map_one_element () =
  let app = React.Upper_case_component ("app", fun () -> Gap.make ~children:(React.string "foo")) in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div class=\"divider\">foo</div>"

let children_map_list_element () =
  let app =
    React.Upper_case_component
      ("app", fun () -> Gap.make ~children:(React.list [ React.string "foo"; React.string "lola" ]))
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div class=\"divider\">foo</div><div class=\"divider\">lola</div>"

let span ?key () = React.createElementWithKey ?key "span" [] []

let rec describe = function
  | React.Lower_case_element { tag; key; _ } -> tag ^ " " ^ Option.value key ~default:"null"
  | React.Static { original; _ } -> "static " ^ describe original
  | React.Writer { original; _ } -> "writer " ^ describe (original ())
  | React.Upper_case_component (name, render) -> name ^ " -> " ^ describe (render ())
  | React.Text text -> "text " ^ text
  | React.Fragment { key; _ } -> "fragment " ^ Option.value key ~default:"null"
  | React.Empty -> "null"
  | _ -> "other"

let members = function
  | React.Static_list members | React.List members -> List.map describe members
  | React.Array members -> List.map describe (Array.to_list members)
  | element -> [ "not a collection: " ^ describe element ]

let check_map label expected mapped = Alcotest.(check (list string)) label expected (members mapped)

let children_map_returns_static_list () =
  let is_static_list = function React.Static_list _ -> true | _ -> false in
  List.iter
    (fun (label, mapped) -> Alcotest.(check bool) label true (is_static_list mapped))
    [
      ("list", React.Children.map (React.list [ span () ]) Fun.id);
      ("array", React.Children.mapWithIndex (React.array [| span () |]) (fun child _ -> child));
      ("Static_list", React.Children.map (React.Static_list [ span () ]) Fun.id);
      ("single element", React.Children.map (span ()) Fun.id);
    ]

let children_map_keys () =
  check_map "unkeyed members get index keys" [ "span .0"; "span .1" ]
    (React.Children.map (React.list [ span (); span () ]) Fun.id);
  check_map "array members" [ "span .0" ] (React.Children.map (React.array [| span () |]) Fun.id);
  check_map "keyed member" [ "span .$a" ] (React.Children.map (React.list [ span ~key:"a" () ]) Fun.id);
  check_map "escaped key" [ "span .$a=0b=2c" ] (React.Children.map (React.list [ span ~key:"a=b:c" () ]) Fun.id);
  check_map "index in base 36"
    (List.init 11 (fun index -> "span ." ^ if index = 10 then "a" else string_of_int index))
    (React.Children.map (React.list (List.init 11 (fun _ -> span ()))) Fun.id);
  check_map "callback key is prefixed" [ "span x/.0" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> span ~key:"x" ()));
  check_map "slashes in a callback key are doubled" [ "span x//y/.0"; "span x///y/.1" ]
    (React.Children.mapWithIndex
       (React.list [ span (); span () ])
       (fun _ index -> span ~key:(if index = 0 then "x/y" else "x//y") ()));
  check_map "same key is not prefixed" [ "span .$a" ] (React.Children.map (React.list [ span ~key:"a" () ]) Fun.id);
  check_map "other key on a keyed member" [ "span b/.$a" ]
    (React.Children.map (React.list [ span ~key:"a" () ]) (fun _ -> span ~key:"b" ()));
  check_map "text members keep their index" [ "text hello"; "span .1" ]
    (React.Children.map (React.list [ React.string "hello"; span () ]) Fun.id);
  check_map "null members keep their index" [ "span .1" ]
    (React.Children.map (React.list [ React.null; span () ]) Fun.id);
  check_map "the callback sees null members" [ "text was null"; "span .1" ]
    (React.Children.map
       (React.list [ React.null; span () ])
       (function React.Empty -> React.string "was null" | child -> child));
  check_map "null results are dropped" [] (React.Children.map (React.list [ span (); span () ]) (fun _ -> React.null));
  check_map "mapWithIndex keys too" [ "span .0"; "span .1" ]
    (React.Children.mapWithIndex (React.list [ span (); span () ]) (fun child _ -> child))

let children_map_static_list () =
  let calls = ref 0 in
  check_map "every member of a Static_list is mapped" [ "span .0"; "span .1" ]
    (React.Children.map
       (React.Static_list [ span (); span () ])
       (fun child ->
         incr calls;
         child));
  Alcotest.(check int) "callback calls" 2 !calls

let children_map_optimized_elements () =
  let static ?key () = React.Static { prerendered = "<span></span>"; original = span ?key () } in
  let writer ?key () =
    React.Writer { emit = (fun buffer ~separators:_ -> Buffer.add_string buffer "<span></span>"); original = span ?key }
  in
  check_map "unkeyed Static and Writer results" [ "static span .0"; "writer span .1" ]
    (React.Children.map (React.list [ static (); writer () ]) Fun.id);
  check_map "keyed Static and Writer members"
    [ "static span .$a"; "writer span .$b" ]
    (React.Children.map (React.list [ static ~key:"a" (); writer ~key:"b" () ]) Fun.id);
  check_map "Static callback key is prefixed" [ "static span x/.0" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> static ~key:"x" ()));
  match React.Children.map (React.list [ static () ]) Fun.id with
  | React.Static_list [ React.Static { prerendered; _ } ] ->
      Alcotest.(check string) "prerendered markup is kept" "<span></span>" prerendered
  | _ -> Alcotest.fail "expected a Static member"

let children_map_flattens () =
  check_map "array results are flattened under the member key" [ "span .0/.0"; "span .0/.1" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> React.list [ span (); span () ]));
  check_map "array results under a keyed member" [ "span .$k/.0"; "span .$k/.$z" ]
    (React.Children.map (React.list [ span ~key:"k" () ]) (fun _ -> React.array [| span (); span ~key:"z" () |]));
  check_map "nested input is flattened" [ "span .0:0"; "span .0:1"; "span .1" ]
    (React.Children.map (React.list [ React.list [ span (); span () ]; span () ]) Fun.id);
  check_map "keyed member of nested input" [ "span .0:$k"; "span .1" ]
    (React.Children.map (React.Static_list [ React.list [ span ~key:"k" () ]; span () ]) Fun.id);
  let indices = ref [] in
  let _ =
    React.Children.mapWithIndex
      (React.list [ React.list [ span (); span () ]; React.null; span () ])
      (fun child index ->
        indices := index :: !indices;
        child)
  in
  Alcotest.(check (list int)) "mapWithIndex counts flattened members" [ 0; 1; 2; 3 ] (List.rev !indices)

let children_map_single_child () =
  check_map "single element" [ "span .0" ] (React.Children.map (span ()) Fun.id);
  check_map "single keyed element" [ "span .$a" ] (React.Children.map (span ~key:"a" ()) Fun.id);
  let called = ref false in
  let mapped =
    React.Children.map React.null (fun child ->
        called := true;
        child)
  in
  Alcotest.(check bool) "null is returned as is" true (mapped == React.null);
  Alcotest.(check bool) "callback is not called for null" false !called

let children_map_component_results () =
  let component ?key name = React.Upper_case_component (name, fun () -> span ?key ()) in
  check_map "component result takes the member key" [ "C -> span .0"; "C -> span .1" ]
    (React.Children.map (React.list [ span (); span () ]) (fun _ -> component "C"));
  check_map "keyed component result joins the keys" [ "C -> span .0,k" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> component ~key:"k" "C"));
  check_map "nested component results" [ "Outer -> C -> span .$a" ]
    (React.Children.map
       (React.list [ span ~key:"a" () ])
       (fun _ -> React.Upper_case_component ("Outer", fun () -> component "C")))

let children_map_fragment_results () =
  let fragment ?key () = React.Fragment.make ?key (React.Fragment.makeProps ~children:(span ()) ()) in
  check_map "fragment result takes the member key" [ "fragment .0"; "fragment .$a" ]
    (React.Children.map (React.list [ span (); span ~key:"a" () ]) (fun _ -> fragment ()));
  check_map "keyed fragment result is prefixed" [ "fragment x/.0" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> fragment ~key:"x" ()));
  check_map "keyed fragment member keeps its key" [ "fragment .$f" ]
    (React.Children.map (React.list [ fragment ~key:"f" () ]) Fun.id)

let children_map_component_fragment_results () =
  let component render = React.Upper_case_component ("C", render) in
  let fragment ?key children = React.Fragment.make ?key (React.Fragment.makeProps ~children ()) in
  check_map "unkeyed fragment passes the key to its child" [ "C -> span .0" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> component (fun () -> fragment (span ()))));
  check_map "fragment of siblings is keyed" [ "C -> fragment .0" ]
    (React.Children.map
       (React.list [ span () ])
       (fun _ -> component (fun () -> fragment (React.Static_list [ span (); span () ]))));
  check_map "collection is wrapped in a keyed fragment" [ "C -> fragment .0" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> component (fun () -> React.list [ span (); span () ])));
  check_map "keyed fragment joins the keys" [ "C -> fragment .0,k" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> component (fun () -> fragment ~key:"k" (span ()))))

let use_ref_works () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let isLive = React.useRef true in
          React.useEffect0 (fun () ->
              isLive.current <- false;
              None);
          React.createElement "span" [] [ React.string (string_of_bool isLive.current) ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<span>true</span>"

let invalid_children () =
  let raises () =
    let _ = React.createElement "input" [ React.JSX.String ("type", "type", "text") ] [ React.string "Hellow" ] in
    ()
  in
  Alcotest.check_raises "Expected invalid argument"
    (React.Invalid_children {|"input" is a self-closing tag and must not have "children".\n|})
    raises

let invalid_dangerouslySetInnerHtml () =
  let raises () =
    let _ =
      React.createElement "meta"
        [ React.JSX.String ("char-set", "charSet", "utf-8"); React.JSX.DangerouslyInnerHtml "Hellow" ]
        []
    in
    ()
  in
  Alcotest.check_raises "Expected invalid argument"
    (React.Invalid_children {|"meta" is a self-closing tag and must not have "dangerouslySetInnerHTML".\n|})
    raises

let raw_element () =
  let original = React.createElement "div" [] [ React.string "Hello" ] in
  let app = React.Upper_case_component ("app", fun () -> React.Static { prerendered = "<div>Hello</div>"; original }) in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>Hello</div>"

let cache_hits_within_request () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        value ^ "-ok")
  in
  React.Cache.with_request_cache (fun () ->
      assert_string (cached "a") "a-ok";
      assert_string (cached "a") "a-ok");
  assert_int !calls 1

let cache_error_is_cached () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        if value = "boom" then raise (Failure "boom");
        "ok")
  in
  let raises () =
    let _ = cached "boom" in
    ()
  in
  React.Cache.with_request_cache (fun () ->
      Alcotest.check_raises "cache error" (Failure "boom") raises;
      Alcotest.check_raises "cache error" (Failure "boom") raises);
  assert_int !calls 1

let cache_separate_per_call () =
  let calls = ref 0 in
  let make_cached () =
    React.cache (fun value ->
        calls := !calls + 1;
        value + 1)
  in
  let cached1 = make_cached () in
  let cached2 = make_cached () in
  React.Cache.with_request_cache (fun () ->
      ignore (cached1 1);
      ignore (cached1 1);
      ignore (cached2 1));
  assert_int !calls 2

let cache_resets_between_requests () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        value)
  in
  React.Cache.with_request_cache (fun () ->
      ignore (cached "a");
      ignore (cached "a"));
  React.Cache.with_request_cache (fun () -> ignore (cached "a"));
  assert_int !calls 2

let cache_error_different_args () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        if value = "boom1" then raise (Failure "boom1");
        if value = "boom2" then raise (Failure "boom2");
        "ok")
  in
  let raises1 () = ignore (cached "boom1") in
  let raises2 () = ignore (cached "boom2") in
  React.Cache.with_request_cache (fun () ->
      Alcotest.check_raises "first error" (Failure "boom1") raises1;
      Alcotest.check_raises "second error" (Failure "boom2") raises2;
      Alcotest.check_raises "first error cached" (Failure "boom1") raises1;
      Alcotest.check_raises "second error cached" (Failure "boom2") raises2);
  assert_int !calls 2

let cache_error_mixed_with_success () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        if value = "boom" then raise (Failure "boom");
        value ^ "-ok")
  in
  let raises () = ignore (cached "boom") in
  React.Cache.with_request_cache (fun () ->
      assert_string (cached "good") "good-ok";
      Alcotest.check_raises "error" (Failure "boom") raises;
      assert_string (cached "good") "good-ok";
      Alcotest.check_raises "error cached" (Failure "boom") raises);
  assert_int !calls 2

let cache_error_resets_between_requests () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        if value = "boom" then raise (Failure "boom");
        "ok")
  in
  let raises () = ignore (cached "boom") in
  React.Cache.with_request_cache (fun () ->
      Alcotest.check_raises "first request error" (Failure "boom") raises;
      Alcotest.check_raises "first request error cached" (Failure "boom") raises);
  React.Cache.with_request_cache (fun () -> Alcotest.check_raises "second request error" (Failure "boom") raises);
  assert_int !calls 2

let cache_error_same_instance () =
  let original_exn = Failure "unique" in
  let cached_exn = ref None in
  let cached = React.cache (fun () -> raise original_exn) in
  let capture_exn () = try ignore (cached ()) with exn -> cached_exn := Some exn in
  React.Cache.with_request_cache (fun () ->
      capture_exn ();
      let first = !cached_exn in
      cached_exn := None;
      capture_exn ();
      let second = !cached_exn in
      match (first, second) with
      | Some e1, Some e2 ->
          Alcotest.(check bool) "same exception instance" true (e1 == e2);
          Alcotest.(check bool) "is original exception" true (e1 == original_exn)
      | _ -> Alcotest.fail "expected exceptions to be captured")

let cache_arg_containing_closure_does_not_crash () =
  let calls = ref 0 in
  let cached =
    React.cache (fun (f : int -> int) ->
        calls := !calls + 1;
        f 1)
  in
  let g = fun x -> x + 1 in
  let h = fun x -> x + 2 in
  React.Cache.with_request_cache (fun () ->
      ignore (cached g);
      ignore (cached h);
      ignore (cached g);
      (* enough distinct closures that a structural store would compare functional values and raise *)
      for i = 3 to 22 do
        ignore (cached (fun x -> x + i))
      done);
  assert_int !calls 22

type cache_record = { a : int; b : string }

let cache_structurally_equal_records_miss () =
  let calls = ref 0 in
  let cached =
    React.cache (fun (record : cache_record) ->
        calls := !calls + 1;
        record.a + String.length record.b)
  in
  (* [Sys.opaque_identity] stops the compiler from statically sharing the two structurally-equal records *)
  let make_record () = { a = Sys.opaque_identity 1; b = "one" } in
  React.Cache.with_request_cache (fun () ->
      ignore (cached (make_record ()));
      ignore (cached (make_record ())));
  assert_int !calls 2

let cache_same_record_hits () =
  let calls = ref 0 in
  let cached =
    React.cache (fun (record : cache_record) ->
        calls := !calls + 1;
        record.a + String.length record.b)
  in
  let record = { a = 1; b = "one" } in
  React.Cache.with_request_cache (fun () ->
      ignore (cached record);
      ignore (cached record));
  assert_int !calls 1

let cache_float_args_hit_by_value () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        value +. 1.)
  in
  React.Cache.with_request_cache (fun () ->
      ignore (cached 1.5);
      ignore (cached 1.5));
  assert_int !calls 1

let lwt_test title fn = Alcotest.test_case title `Quick (fun () -> Lwt_main.run (fn ()))

let cache_async_hits_within_request () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        incr calls;
        value ^ "-ok")
  in
  React.Cache.with_request_cache_async (fun () ->
      assert_string (cached "a") "a-ok";
      let%lwt () = Lwt.pause () in
      assert_string (cached "a") "a-ok";
      Lwt.return ());%lwt
  assert_int !calls 1;
  Lwt.return ()

let cache_async_resets_between_requests () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        incr calls;
        value)
  in
  React.Cache.with_request_cache_async (fun () ->
      ignore (cached "a");
      ignore (cached "a");
      Lwt.return ());%lwt
  React.Cache.with_request_cache_async (fun () ->
      ignore (cached "a");
      Lwt.return ());%lwt
  assert_int !calls 2;
  Lwt.return ()

let cache_async_concurrent_isolation () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        incr calls;
        value ^ "-ok")
  in
  let p1 =
    React.Cache.with_request_cache_async (fun () ->
        assert_string (cached "a") "a-ok";
        (* Yield to scheduler — lets p2 run and install its own cache *)
        let%lwt () = Lwt.pause () in
        (* Must still hit p1's cache, not p2's *)
        assert_string (cached "a") "a-ok";
        Lwt.return ())
  in
  let p2 =
    React.Cache.with_request_cache_async (fun () ->
        (* Independent cache — fresh call even though p1 already cached "a" *)
        assert_string (cached "a") "a-ok";
        Lwt.return ())
  in
  Lwt.join [ p1; p2 ];%lwt
  (* 2 calls total: one per request, each caching "a" independently *)
  assert_int !calls 2;
  Lwt.return ()

let cache_async_no_cross_request_leaking () =
  let cached = React.cache (fun value -> value ^ "-ok") in
  let seen_in_p2 = ref "" in
  let p1 =
    React.Cache.with_request_cache_async (fun () ->
        ignore (cached "from-p1");
        let%lwt () = Lwt.pause () in
        Lwt.return ())
  in
  let p2 =
    React.Cache.with_request_cache_async (fun () ->
        (* p2 should compute its own value, not see p1's cached result *)
        seen_in_p2 := cached "from-p2";
        Lwt.return ())
  in
  Lwt.join [ p1; p2 ];%lwt
  assert_string !seen_in_p2 "from-p2-ok";
  Lwt.return ()

let memo_component ~name () =
  React.Upper_case_component ("component", fun () -> React.createElement "div" [] [ React.string name ])

let memo_renders_identically () =
  let memoized = React.memo memo_component in
  assert_string
    (ReactDOM.renderToStaticMarkup (memoized ~name:"foo" ()))
    (ReactDOM.renderToStaticMarkup (memo_component ~name:"foo" ()))

let memo_custom_compare_props_renders_identically () =
  (* The compare function is ignored on the server: there's no re-render *)
  let memoized = React.memoCustomCompareProps memo_component (fun _prev _next -> true) in
  assert_string
    (ReactDOM.renderToStaticMarkup (memoized ~name:"foo" ()))
    (ReactDOM.renderToStaticMarkup (memo_component ~name:"foo" ()))

let tests =
  ( "React",
    [
      test "useState" use_state_doesnt_fire;
      test "memo renders identically to the un-memoized component" memo_renders_identically;
      test "memoCustomCompareProps renders identically to the un-memoized component"
        memo_custom_compare_props_renders_identically;
      test "useSyncExternalStoreWithServer" use_sync_external_store_with_server;
      test "useEffect" use_effect_doesnt_fire;
      test "compatibility effects don't fire" compatibility_effects_dont_fire;
      test "compatibility rendering helpers" compatibility_rendering_helpers;
      test "isValidElement" is_valid_element;
      test "async transition runs callback" async_transition_runs_callback;
      test "compatible Ref and forwardRef" compatible_ref_and_forward_ref;
      test "experimental hooks" experimental_hooks;
      test "Children.map" children_map_one_element;
      test "Children.map" children_map_list_element;
      test "Children.map returns a Static_list" children_map_returns_static_list;
      test "Children.map keys" children_map_keys;
      test "Children.map over a Static_list" children_map_static_list;
      test "Children.map keys Static and Writer" children_map_optimized_elements;
      test "Children.map flattens like React" children_map_flattens;
      test "Children.map single child" children_map_single_child;
      test "Children.map component results" children_map_component_results;
      test "Children.map fragment results" children_map_fragment_results;
      test "Children.map component fragment results" children_map_component_fragment_results;
      test "useRef" use_ref_works;
      test "invalid_children" invalid_children;
      test "invalid_dangerouslySetInnerHtml" invalid_dangerouslySetInnerHtml;
      test "raw_element" raw_element;
      test "cache hits within request" cache_hits_within_request;
      test "cache errors are cached" cache_error_is_cached;
      test "cache is separate per call" cache_separate_per_call;
      test "cache resets between requests" cache_resets_between_requests;
      test "cache errors different args" cache_error_different_args;
      test "cache errors mixed with success" cache_error_mixed_with_success;
      test "cache errors reset between requests" cache_error_resets_between_requests;
      test "cache errors same instance" cache_error_same_instance;
      test "cache arg containing closure does not crash" cache_arg_containing_closure_does_not_crash;
      test "cache structurally equal records miss" cache_structurally_equal_records_miss;
      test "cache same record hits" cache_same_record_hits;
      test "cache float args hit by value" cache_float_args_hit_by_value;
      lwt_test "cache async hits within request" cache_async_hits_within_request;
      lwt_test "cache async resets between requests" cache_async_resets_between_requests;
      lwt_test "cache async concurrent isolation" cache_async_concurrent_isolation;
      lwt_test "cache async no cross-request leaking" cache_async_no_cross_request_leaking;
    ] )
