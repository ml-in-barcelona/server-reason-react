type renderer = Model | Html

let json = Alcotest.testable Yojson.Basic.pretty_print ( = )
let check_json = Alcotest.check json
let node ?key ?(attributes = []) tag children = React.createElementWithKey ?key tag attributes children
let leaf tag = node tag []
let group children = React.Static_children children
let no_frames _ _ = false

let parse_rows chunks =
  String.concat "" chunks |> String.split_on_char '\n'
  |> List.filter_map (fun line ->
      match String.index_opt line ':' with
      | None -> None
      | Some colon ->
          let body = String.sub line (colon + 1) (String.length line - colon - 1) in
          if colon = 0 || body = "" || List.mem body.[0] [ 'I'; 'D'; 'E' ] then None
          else Some (String.sub line 0 colon, Yojson.Basic.from_string body))

let payloads html =
  let pattern = Str.regexp "data-payload='\\([^']*\\)'" in
  let unescape value =
    List.fold_left
      (fun value (escaped, plain) -> Str.global_replace (Str.regexp_string escaped) plain value)
      value
      [ ("&quot;", "\""); ("&#x27;", "'"); ("&#39;", "'"); ("&lt;", "<"); ("&gt;", ">"); ("&amp;", "&") ]
  in
  let rec collect start =
    match Str.search_forward pattern html start with
    | _ ->
        let value = Str.matched_group 1 html in
        let next = Str.match_end () in
        unescape value :: collect next
    | exception Not_found -> []
  in
  collect 0

let capture render =
  let chunks = ref [] in
  let%lwt () =
    render (fun chunk ->
        chunks := chunk :: !chunks;
        Lwt.return_unit)
  in
  Lwt.return (List.rev !chunks)

let render_chunks ?env ?(debug = false) renderer element =
  match renderer with
  | Model ->
      capture (fun subscribe ->
          ReactServerDOM.render_model ?env ~debug ~filter_stack_frame:no_frames ~subscribe element)
  | Html ->
      let%lwt shell, subscribe = ReactServerDOM.render_html ?env ~debug ~filter_stack_frame:no_frames element in
      let%lwt chunks = capture subscribe in
      Lwt.return (payloads (String.concat "" (shell :: chunks)))

let render ?env ?debug renderer element =
  let%lwt chunks = render_chunks ?env ?debug renderer element in
  Lwt.return (parse_rows chunks)

let root rows = List.assoc "0" rows

let prop name = function
  | `List [ `String "$"; _; _; `Assoc props; _; _; _ ] -> List.assoc name props
  | _ -> Alcotest.fail "Expected element tuple"

let summaries ?env rows =
  let rec walk = function
    | `List (`String "$" :: fields) -> (
        match fields with
        | [ `String tag; key; (`Assoc _ as props); owner; stack; `Int validation ] ->
            Alcotest.(check bool) "validation range" true (validation >= 0 && validation <= 2);
            check_json "stack" `Null stack;
            if env <> Some `Dev then check_json "production owner" `Null owner;
            let tag =
              if String.starts_with ~prefix:"$L" tag then "client"
              else if String.starts_with ~prefix:"$" tag then
                let id = String.sub tag 1 (String.length tag - 1) in
                match List.assoc_opt id rows with Some (`String "$Sreact.suspense") -> "suspense" | _ -> tag
              else tag
            in
            (tag, key, validation) :: walk props
        | _ -> Alcotest.fail "Element tuple must have seven fields")
    | `List values -> List.concat_map walk values
    | `Assoc fields -> List.concat_map (fun (_, value) -> walk value) fields
    | _ -> []
  in
  List.concat_map (fun (_, value) -> walk value) rows |> List.sort compare

let check_states ?env expected rows =
  let as_json values = `List (List.map (fun (tag, key, state) -> `List [ `String tag; key; `Int state ]) values) in
  check_json "element validation" (as_json (List.sort compare expected)) (as_json (summaries ?env rows))

let state tag flag = (tag, `Null, flag)
let keyed tag key flag = (tag, `String key, flag)

let matrix run =
  Lwt_list.iter_s
    (fun env -> Lwt_list.iter_s (fun debug -> Lwt_list.iter_s (run env debug) [ Model; Html ]) [ false; true ])
    [ None; Some `Prod; Some `Dev ]

let static_and_dynamic () =
  matrix (fun env debug renderer ->
      let shared = leaf "span" in
      let tree =
        node "div"
          [
            shared;
            React.list [ leaf "i" ];
            React.array [| leaf "b" |];
            node ~key:"fixed" "strong" [];
            React.list [ node ~key:"a" "em" []; node ~key:"a" "em" [] ];
          ]
      in
      let%lwt rows = render ?env ~debug renderer tree in
      check_states ?env
        [
          state "div" 0;
          state "span" 1;
          state "i" 2;
          state "b" 2;
          keyed "strong" "fixed" 1;
          keyed "em" "a" 0;
          keyed "em" "a" 0;
        ]
        rows;
      (match prop "children" (root rows) with
      | `List [ _; `List [ _ ]; `List [ _ ]; _; `List [ _; _ ] ] -> ()
      | _ -> Alcotest.fail "Nested child collections changed shape");
      Lwt.return_unit)

let nested_groups () =
  matrix (fun env debug renderer ->
      let tree =
        group
          [
            leaf "span";
            React.list [ leaf "b"; group [ leaf "i" ] ];
            group [ React.array [| leaf "em" |] ];
            React.list [ leaf "strong" ];
          ]
      in
      let%lwt rows = render ?env ~debug renderer tree in
      check_states ?env [ state "span" 1; state "b" 2; state "i" 1; state "em" 2; state "strong" 2 ] rows;
      Lwt.return_unit)

let reuse_and_extraction () =
  matrix (fun env debug renderer ->
      let shared = leaf "span" in
      let static = node "div" [ shared ] in
      let extracted =
        match static with
        | React.Lower_case_element { children; _ } -> React.Children.only (React.list children)
        | _ -> assert false
      in
      let clone = React.cloneElement extracted [ React.JSX.String ("title", "title", "clone") ] in
      let dynamic = React.list [ shared; extracted; clone ] in
      let check element expected =
        let%lwt rows = render ?env ~debug renderer element in
        check_states ?env expected rows;
        Lwt.return_unit
      in
      let%lwt () = check static [ state "div" 0; state "span" 1 ] in
      let%lwt () = check dynamic [ state "span" 2; state "span" 2; state "span" 2 ] in
      let%lwt () = check dynamic [ state "span" 2; state "span" 2; state "span" 2 ] in
      let%lwt () = check static [ state "div" 0; state "span" 1 ] in
      let%lwt left, right = Lwt.both (render ?env ~debug renderer static) (render ?env ~debug renderer dynamic) in
      check_states ?env [ state "div" 0; state "span" 1 ] left;
      check_states ?env [ state "span" 2; state "span" 2; state "span" 2 ] right;
      Lwt.return_unit)

let raw_and_optimized () =
  matrix (fun env debug renderer ->
      let calls = ref 0 in
      let writer original =
        React.Writer
          {
            emit = (fun _ ~separators:_ -> Alcotest.fail "RSC must read original");
            original =
              (fun () ->
                incr calls;
                original);
          }
      in
      let raw =
        React.Lower_case_element
          { key = None; tag = "div"; attributes = []; children = [ leaf "span"; React.list [ leaf "b" ] ] }
      in
      let tree =
        node "section"
          [
            React.Static { prerendered = "<i></i>"; original = leaf "i" };
            writer (leaf "em");
            writer (React.list [ leaf "strong" ]);
            raw;
          ]
      in
      let%lwt rows = render ?env ~debug renderer tree in
      check_states ?env
        [ state "section" 0; state "i" 1; state "em" 1; state "strong" 2; state "div" 1; state "span" 1; state "b" 2 ]
        rows;
      Alcotest.(check int) "writer original calls" 2 !calls;
      Lwt.return_unit)

let transparent_collections () =
  matrix (fun env debug renderer ->
      let context = React.createContext 0 in
      let children = React.list [ leaf "span"; group [ leaf "b" ] ] in
      let provider = React.Context.provider context (React.Context.makeProps ~value:1 ~children ()) in
      let tree = React.fragment (React.Consumer provider) in
      let%lwt rows = render ?env ~debug renderer tree in
      check_states ?env [ state "span" 2; state "b" 1 ] rows;
      Lwt.return_unit)

let client ?key ?(client = React.null) props =
  React.Client_component { key; import_module = "./client.js"; import_name = "Client"; props; client }

let client_models () =
  matrix (fun env debug renderer ->
      let tree =
        React.list
          [
            client ~client:(leaf "div")
              [
                ("direct", React.Model.Element (leaf "span"));
                ( "items",
                  React.Model.List
                    [
                      React.Model.Element (leaf "b");
                      React.Model.Element (group [ leaf "i" ]);
                      React.Model.Assoc [ ("value", React.Model.Element (leaf "em")) ];
                    ] );
              ];
            client ~key:"key" [];
          ]
      in
      let%lwt rows = render ?env ~debug renderer tree in
      check_states ?env
        [ state "client" 2; keyed "client" "key" 0; state "span" 0; state "b" 2; state "i" 1; state "em" 0 ]
        rows;
      Lwt.return_unit)

let generic_models () =
  matrix (fun env debug renderer ->
      let value =
        React.Model.List
          [
            React.Model.Element (leaf "span");
            React.Model.Assoc
              [
                ("direct", React.Model.Element (leaf "b"));
                ("list", React.Model.List [ React.Model.Element (group [ leaf "i" ]) ]);
              ];
          ]
      in
      let%lwt chunks =
        capture (fun subscribe ->
            match renderer with
            | Model -> ReactServerDOM.render_model_value ?env ~debug ~filter_stack_frame:no_frames ~subscribe value
            | Html ->
                ReactServerDOM.create_action_response ?env ~debug ~filter_stack_frame:no_frames ~subscribe
                  (Lwt.return value))
      in
      check_states ?env [ state "span" 2; state "b" 0; state "i" 1 ] (parse_rows chunks);
      Lwt.return_unit)

let shared_promises () =
  matrix (fun env debug renderer ->
      Lwt_list.iter_s
        (fun pending ->
          Lwt_list.iter_s
            (fun reverse ->
              Lwt_list.iter_s
                (fun resolved ->
                  let promise, wake = Lwt.wait () in
                  if not pending then Lwt.wakeup wake resolved;
                  let value = React.Model.Promise (promise, Fun.id) in
                  let fields = [ ("list", React.Model.List [ value ]); ("field", value) ] in
                  let fields = if reverse then List.rev fields else fields in
                  let task = render ?env ~debug renderer (client fields) in
                  if pending then Lwt.wakeup wake resolved;
                  let%lwt rows = task in
                  let list_ref = prop "list" (root rows) in
                  let field_ref = prop "field" (root rows) in
                  check_json "shared reference" (`List [ field_ref ]) list_ref;
                  let id =
                    match field_ref with
                    | `String ref -> String.sub ref 2 (String.length ref - 2)
                    | _ -> Alcotest.fail "Expected promise reference"
                  in
                  Alcotest.(check int)
                    "single promise row" 1
                    (List.length (List.filter (fun (row, _) -> row = id) rows));
                  let expected =
                    match resolved with
                    | React.Model.Element (React.Static_children _) -> [ state "span" 1 ]
                    | React.Model.Element _ -> [ state "span" 0 ]
                    | _ -> [ state "span" 2; state "b" 1 ]
                  in
                  check_states ?env (state "client" 0 :: expected) rows;
                  Lwt.return_unit)
                [
                  React.Model.Element (leaf "span");
                  React.Model.Element (group [ leaf "span" ]);
                  React.Model.List [ React.Model.Element (leaf "span"); React.Model.Element (group [ leaf "b" ]) ];
                ])
            [ false; true ])
        [ false; true ])

let server_returns () =
  matrix (fun env debug renderer ->
      Lwt_list.iter_s
        (fun collection ->
          Lwt_list.iter_s
            (fun kind ->
              let calls = ref 0 in
              let returned =
                if collection then React.list [ leaf "span"; group [ leaf "b" ]; node ~key:"k" "i" [] ] else leaf "span"
              in
              let promise, wake = Lwt.wait () in
              let component =
                match kind with
                | 0 ->
                    React.Upper_case_component
                      ( "Sync",
                        fun () ->
                          incr calls;
                          returned )
                | 1 ->
                    React.Async_component
                      ( "Ready",
                        fun () ->
                          incr calls;
                          Lwt.return returned )
                | _ ->
                    React.Async_component
                      ( "Pending",
                        fun () ->
                          incr calls;
                          promise )
              in
              let boundary = React.Suspense { key = None; children = component; fallback = Some (leaf "small") } in
              let task = render ?env ~debug renderer (React.list [ boundary ]) in
              if kind = 2 then Lwt.wakeup wake returned;
              let%lwt rows = task in
              let expected =
                if collection then [ state "span" 2; state "b" 1; keyed "i" "k" 0 ] else [ state "span" 1 ]
              in
              check_states ?env (state "suspense" 2 :: state "small" 1 :: expected) rows;
              Alcotest.(check int) "component calls" 1 !calls;
              Lwt.return_unit)
            [ 0; 1; 2 ])
        [ false; true ])

let server_task_roots () =
  matrix (fun env debug renderer ->
      let inner = React.Upper_case_component ("Inner", fun () -> leaf "span") in
      let outer =
        React.Async_component
          ( "Outer",
            fun () ->
              let%lwt () = Lwt.pause () in
              Lwt.return inner )
      in
      let%lwt rows = render ?env ~debug renderer outer in
      check_states ?env [ state "span" 1 ] rows;
      let%lwt rows = render ?env ~debug renderer (React.list [ inner ]) in
      check_states ?env [ state "span" 1 ] rows;
      Lwt.return_unit)

let suspended_retry () =
  matrix (fun env debug renderer ->
      let promise, wake = Lwt.wait () in
      let calls = ref 0 in
      let component =
        React.Upper_case_component
          ( "Suspended",
            fun () ->
              incr calls;
              let () = React.Experimental.usePromise promise in
              React.list [ leaf "span"; group [ leaf "b" ] ] )
      in
      let tree = React.Suspense { key = Some "boundary"; children = component; fallback = Some (leaf "small") } in
      let task = render ?env ~debug renderer (React.list [ tree ]) in
      Lwt.wakeup wake ();
      let%lwt rows = task in
      check_states ?env [ keyed "suspense" "boundary" 0; state "small" 1; state "span" 2; state "b" 1 ] rows;
      Alcotest.(check int) "suspended component attempts" 2 !calls;
      Lwt.return_unit)

let special_host_paths () =
  matrix (fun env debug renderer ->
      let action = { Runtime.id = "save"; call = (fun () -> Lwt.return_unit) } in
      let form = node ~attributes:[ React.JSX.Action ("action", "action", action) ] "form" [ leaf "button" ] in
      let raw = node ~attributes:[ React.JSX.DangerouslyInnerHtml "<b>raw</b>" ] "section" [] in
      let tree =
        node "html"
          [
            node "head" [ node "title" [ React.string "title" ]; leaf "meta" ];
            node "body"
              [
                React.list
                  [
                    form;
                    raw;
                    leaf "input";
                    leaf "link";
                    node
                      ~attributes:[ React.JSX.Bool ("async", "async", true); React.JSX.String ("src", "src", "/a.js") ]
                      "script" [];
                  ];
              ];
          ]
      in
      let%lwt rows = render ?env ~debug renderer tree in
      check_states ?env
        [
          state "html" 0;
          state "head" 1;
          state "title" 1;
          state "meta" 1;
          state "body" 1;
          state "form" 2;
          state "button" 1;
          state "section" 2;
          state "input" 2;
          state "link" 2;
          state "script" 2;
        ]
        rows;
      Lwt.return_unit)

let use_id_and_evaluation () =
  matrix (fun env debug renderer ->
      let calls = ref 0 in
      let component () =
        React.Upper_case_component
          ( "Id",
            fun () ->
              incr calls;
              node ~attributes:[ React.JSX.String ("id", "id", React.useId ()) ] "span" [] )
      in
      let tree mark = node "div" [ mark (component ()); mark (component ()) ] in
      let%lwt listed = render ?env ~debug renderer (tree (fun child -> React.list [ child ])) in
      let%lwt grouped = render ?env ~debug renderer (tree (fun child -> group [ child ])) in
      let rec ids = function
        | `Assoc fields -> List.concat_map (fun (key, value) -> if key = "id" then [ value ] else ids value) fields
        | `List values -> List.concat_map ids values
        | _ -> []
      in
      let ids rows = List.concat_map (fun (_, value) -> ids value) rows in
      check_json "useId traversal" (`List (ids listed)) (`List (ids grouped));
      Alcotest.(check int) "component evaluation" 4 !calls;
      Lwt.return_unit)

let action_promises () =
  matrix (fun env debug renderer ->
      let promise, wake = Lwt.wait () in
      let response, wake_response = Lwt.wait () in
      let value = React.Model.Promise (promise, fun child -> React.Model.Element child) in
      let model =
        match renderer with
        | Model -> React.Model.Assoc [ ("list", React.Model.List [ value ]); ("value", value) ]
        | Html -> React.Model.Assoc [ ("value", value); ("list", React.Model.List [ value ]) ]
      in
      let task =
        capture (fun subscribe ->
            ReactServerDOM.create_action_response ?env ~debug ~filter_stack_frame:no_frames ~subscribe response)
      in
      Lwt.wakeup wake_response model;
      Lwt.wakeup wake (leaf "span");
      let%lwt chunks = task in
      let rows = parse_rows chunks in
      check_states ?env [ state "span" 0 ] rows;
      Alcotest.(check int) "action and shared promise rows" 2 (List.length rows);
      (match root rows with
      | `Assoc fields ->
          check_json "action promise dedup" (`List [ List.assoc "value" fields ]) (List.assoc "list" fields)
      | _ -> Alcotest.fail "Expected action association");
      Lwt.return_unit)

let debug_through_models () =
  matrix (fun env debug renderer ->
      let promise, wake = Lwt.wait () in
      let child = React.Upper_case_component ("Prop", fun () -> leaf "span") in
      let props =
        [
          ( "values",
            React.Model.List
              [
                React.Model.Assoc [ ("pending", React.Model.Promise (promise, fun child -> React.Model.Element child)) ];
              ] );
        ]
      in
      let task = render_chunks ?env ~debug renderer (client props) in
      Lwt.wakeup wake child;
      let%lwt chunks = task in
      check_states ?env [ state "client" 0; state "span" 1 ] (parse_rows chunks);
      let has_debug =
        List.exists
          (fun row ->
            try
              ignore (Str.search_forward (Str.regexp_string ":D") row 0);
              true
            with Not_found -> false)
          chunks
      in
      Alcotest.(check bool) "debug rows follow option" debug has_debug;
      Lwt.return_unit)

let errors_and_boundary_state () =
  matrix (fun env debug renderer ->
      Lwt_list.iter_s
        (fun pending ->
          let promise, wake = Lwt.wait () in
          let bad =
            if pending then React.Async_component ("Bad", fun () -> promise)
            else React.Upper_case_component ("Bad", fun () -> failwith "private-message")
          in
          let boundary = React.Suspense { key = None; children = bad; fallback = Some (leaf "small") } in
          let tree =
            React.list [ boundary; group [ React.Suspense { key = None; children = leaf "span"; fallback = None } ] ]
          in
          let task = render_chunks ?env ~debug renderer tree in
          if pending then Lwt.wakeup_exn wake (Failure "private-message");
          let%lwt chunks = task in
          check_states ?env
            [ state "suspense" 2; state "suspense" 1; state "small" 1; state "span" 1 ]
            (parse_rows chunks);
          let errors =
            String.concat "" chunks |> String.split_on_char '\n'
            |> List.filter_map (fun line ->
                match String.index_opt line ':' with
                | Some i when i + 1 < String.length line && line.[i + 1] = 'E' ->
                    Some (Yojson.Basic.from_string (String.sub line (i + 2) (String.length line - i - 2)))
                | _ -> None)
          in
          Alcotest.(check int) "one boundary error" 1 (List.length errors);
          (match env with
          | Some `Dev -> (
              match List.hd errors with
              | `Assoc fields ->
                  Alcotest.(check bool) "development error message" true (List.mem_assoc "message" fields)
              | _ -> Alcotest.fail "Expected error object")
          | _ -> check_json "production error redaction" (`List [ `Assoc [ ("digest", `String "") ] ]) (`List errors));
          Lwt.return_unit)
        [ false; true ])

let sync_html_failure_restores_context () =
  Lwt_list.iter_s
    (fun env ->
      Lwt_list.iter_s
        (fun debug ->
          let reader =
            React.Upper_case_component
              ("Reader", fun () -> node ~attributes:[ React.JSX.String ("id", "id", React.useId ()) ] "span" [])
          in
          let%lwt baseline = render ?env ~debug Html reader in
          let expected_id = prop "id" (root baseline) in
          Lwt_list.iter_s
            (fun mode ->
              Lwt_list.iter_s
                (fun delayed_child ->
                  let promise, wake = Lwt.wait () in
                  let calls = ref 0 in
                  let bad =
                    if delayed_child then
                      React.Async_component
                        ( "Bad",
                          fun () ->
                            let%lwt () = Lwt.pause () in
                            Lwt.fail (Failure "child failed") )
                    else React.Upper_case_component ("Bad", fun () -> failwith "child failed")
                  in
                  let component =
                    React.Upper_case_component
                      ( "Parent",
                        fun () ->
                          incr calls;
                          ignore (React.useId ());
                          if mode <> `Direct then ignore (React.Experimental.usePromise promise);
                          bad )
                  in
                  let task =
                    Lwt.apply
                      (fun () -> ReactServerDOM.render_html ?env ~debug ~filter_stack_frame:no_frames component)
                      ()
                  in
                  (match mode with
                  | `Direct -> ()
                  | `Retry -> Lwt.wakeup wake ()
                  | `Reject -> Lwt.wakeup_exn wake (Failure "promise rejected"));
                  let%lwt error =
                    Lwt.catch
                      (fun () ->
                        let%lwt _ = task in
                        Lwt.return_none)
                      (fun exn -> Lwt.return (Some (Printexc.to_string exn)))
                  in
                  let message = if mode = `Reject then "promise rejected" else "child failed" in
                  Alcotest.(check (option string)) "render error" (Some (Printexc.to_string (Failure message))) error;
                  Alcotest.(check int) "component attempts" (if mode = `Retry then 2 else 1) !calls;
                  Alcotest.(check bool)
                    "root tree context restored" true
                    (!React.current_tree_context = React.Tree_context.empty);
                  let%lwt subsequent = render ?env ~debug Html reader in
                  check_json "subsequent render id" expected_id (prop "id" (root subsequent));
                  Lwt.return_unit)
                [ false; true ])
            [ `Direct; `Retry; `Reject ])
        [ false; true ])
    [ None; Some `Prod; Some `Dev ]

let test name run =
  Alcotest_lwt.test_case name `Quick (fun _ () ->
      Lwt.pick
        [
          run ();
          (let%lwt () = Lwt_unix.sleep 5. in
           Alcotest.fail "Key validation test timed out");
        ])

let tests =
  [
    ( "Flight key validation",
      [
        test "static slots and dynamic collections" static_and_dynamic;
        test "nested groups" nested_groups;
        test "reuse, extraction, and cloning" reuse_and_extraction;
        test "raw records and optimized originals" raw_and_optimized;
        test "transparent collections" transparent_collections;
        test "client model props and opaque HTML" client_models;
        test "generic models and action responses" generic_models;
        test "shared ready and pending promises" shared_promises;
        test "sync and async server results" server_returns;
        test "server task roots and erased calls" server_task_roots;
        test "suspended retry" suspended_retry;
        test "form, raw, void, and hoisted hosts" special_host_paths;
        test "useId and evaluation count" use_id_and_evaluation;
        test "pending action response and promise dedup" action_promises;
        test "debug through model collections and promises" debug_through_models;
        test "error redaction and boundary validation" errors_and_boundary_state;
        test "sync HTML failure restores useId context" sync_html_failure_restores_context;
      ] );
  ]
