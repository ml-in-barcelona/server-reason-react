let yojson = Alcotest.testable Yojson.Safe.pretty_print ( = )
let check_json = Alcotest.check yojson "should be equal"
let assert_json left right = Alcotest.check yojson "should be equal" right left

let assert_list (type a) (ty : a Alcotest.testable) (left : a list) (right : a list) =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_list_of_strings (left : string list) (right : string list) =
  Alcotest.check (Alcotest.list Alcotest.string) "should be equal" right left

let test title fn =
  ( Printf.sprintf "ReactServerDOM.render_model / %s" title,
    [
      Alcotest_lwt.test_case "" `Quick (fun _switch () ->
          let start = Unix.gettimeofday () in
          let timeout =
            let%lwt () = Lwt_unix.sleep 3.0 in
            Alcotest.failf "Test '%s' timed out" title
          in
          let%lwt test_promise = Lwt.pick [ fn (); timeout ] in
          let epsilon = 0.001 in
          let duration = Unix.gettimeofday () -. start in
          if abs_float duration >= epsilon then
            Printf.printf "\027[1m\027[33m[WARNING]\027[0m Test '%s' took %.3f seconds\n" title duration
          else ();
          Lwt.return test_promise);
    ] )

let assert_stream (stream : string Lwt_stream.t) (expected : string list) =
  let%lwt content = Lwt_stream.to_list stream in
  if content = [] then Lwt.return @@ Alcotest.fail "stream should not be empty"
  else Lwt.return @@ assert_list_of_strings content expected

let null_element () =
  let app = React.null in
  let%lwt stream = ReactServerDOM.render_model app in
  assert_stream stream [ "0:null\n" ]

let string_element () =
  let app = React.string "hi" in
  let%lwt stream = ReactServerDOM.render_model app in
  assert_stream stream [ "0:\"hi\"\n" ]

let lower_case_component () =
  let app = React.createElement "div" (ReactDOM.domProps ~className:"foo" ()) [] in
  let%lwt stream = ReactServerDOM.render_model app in
  assert_stream stream [ "0:[\"$\",\"div\",null,{\"className\":\"foo\"}]\n" ]

let lower_case_with_children () =
  let app =
    React.createElement "div" []
      [ React.createElement "span" [] [ React.string "Home" ]; React.createElement "span" [] [ React.string "Nohome" ] ]
  in
  let%lwt stream = ReactServerDOM.render_model app in
  assert_stream stream
    [
      "0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"span\",null,{\"children\":\"Home\"}],[\"$\",\"span\",null,{\"children\":\"Nohome\"}]]}]\n";
    ]

let lower_case_component_nested () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.createElement "div" []
          [
            React.createElement "section" [] [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
          ])
  in
  let%lwt stream = ReactServerDOM.render_model (app ()) in
  assert_stream stream
    [
      "1:[\"$\",\"div\",null,{\"children\":[\"$\",\"section\",null,{\"children\":[\"$\",\"article\",null,{\"children\":\"Deep \
       Server Content\"}]}]}]\n";
      "0:\"$1\"\n";
    ]

let dangerouslySetInnerHtml () =
  let app =
    React.createElement "script"
      [
        React.JSX.String ("type", "type", "application/javascript"); React.JSX.DangerouslyInnerHtml "console.log('Hi!')";
      ]
      []
  in
  let%lwt stream = ReactServerDOM.render_model app in
  assert_stream stream
    [
      "0:[\"$\",\"script\",null,{\"type\":\"application/javascript\",\"dangerouslySetInnerHTML\":{\"__html\":\"console.log('Hi!')\"}}]\n";
    ]

let upper_case_component () =
  let app codition =
    React.Upper_case_component
      (fun () ->
        let text = if codition then "foo" else "bar" in
        React.createElement "span" [] [ React.string text ])
  in
  let%lwt stream = ReactServerDOM.render_model (app true) in
  assert_stream stream [ "1:[\"$\",\"span\",null,{\"children\":\"foo\"}]\n"; "0:\"$1\"\n" ]

let text ~children () = React.createElement "span" [] children

let upper_case_with_list () =
  let app () =
    React.Fragment
      (React.list
         [
           React.Upper_case_component (text ~children:[ React.string "hi" ]);
           React.Upper_case_component (text ~children:[ React.string "hola" ]);
         ])
  in
  let%lwt stream = ReactServerDOM.render_model (app ()) in
  assert_stream stream
    [
      "1:[\"$\",\"span\",null,{\"children\":\"hi\"}]\n";
      "2:[\"$\",\"span\",null,{\"children\":\"hola\"}]\n";
      "0:[\"$1\",\"$2\"]\n";
    ]

let upper_case_with_children () =
  let layout ~children () = React.createElement "div" [] children in
  let app () =
    React.Upper_case_component
      (layout
         ~children:
           [
             React.Upper_case_component (text ~children:[ React.string "hi" ]);
             React.Upper_case_component (text ~children:[ React.string "hola" ]);
           ])
  in
  let%lwt stream = ReactServerDOM.render_model (app ()) in
  assert_stream stream
    [
      "2:[\"$\",\"span\",null,{\"children\":\"hi\"}]\n";
      "3:[\"$\",\"span\",null,{\"children\":\"hola\"}]\n";
      "1:[\"$\",\"div\",null,{\"children\":[\"$2\",\"$3\"]}]\n";
      "0:\"$1\"\n";
    ]

let suspense_without_promise () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:
        (React.createElement "div" []
           [
             React.Upper_case_component (text ~children:[ React.string "hi" ]);
             React.Upper_case_component (text ~children:[ React.string "hola" ]);
           ])
      ()
  in
  let main = React.Upper_case_component app in
  let%lwt stream = ReactServerDOM.render_model main in
  assert_stream stream
    [
      "2:[\"$\",\"span\",null,{\"children\":\"hi\"}]\n";
      "3:[\"$\",\"span\",null,{\"children\":\"hola\"}]\n";
      "1:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":[\"$\",\"div\",null,{\"children\":[\"$2\",\"$3\"]}]}]\n";
      "0:\"$1\"\n";
    ]

let suspense_with_promise () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           (fun () ->
             let%lwt () = Lwt_unix.sleep 1.0 in
             Lwt.return (React.string "lol")))
      ()
  in
  let main = React.Upper_case_component app in
  let%lwt stream = ReactServerDOM.render_model main in
  assert_stream stream
    [
      "1:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L2\"}]\n";
      "0:\"$1\"\n";
      "2:\"lol\"\n";
    ]

let suspense_with_immediate_promise () =
  let resolved_component =
    React.Async_component
      (fun () ->
        let value = "DONE :)" in
        Lwt.return (React.string value))
  in
  let app = React.Suspense.make ~fallback:(React.string "Loading...") ~children:resolved_component in
  let main = React.Upper_case_component app in
  let%lwt stream = ReactServerDOM.render_model main in
  assert_stream stream
    [ "1:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"DONE :)\"}]\n"; "0:\"$1\"\n" ]

let delayed_value ~ms value =
  let%lwt () = Lwt_unix.sleep (Int.to_float ms /. 100.0) in
  Lwt.return value

let suspense () =
  let suspended_component =
    React.Async_component
      (fun () ->
        let%lwt value = delayed_value ~ms:100 "DONE :)" in
        Lwt.return (React.string value))
  in
  let app () = React.Suspense.make ~fallback:(React.string "Loading...") ~children:suspended_component () in
  let main = React.Upper_case_component app in
  let%lwt stream = ReactServerDOM.render_model main in
  assert_stream stream
    [
      "1:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L2\"}]\n";
      "0:\"$1\"\n";
      "2:\"DONE :)\"\n";
    ]

let nested_suspense () =
  let deffered_component =
    React.Async_component
      (fun () ->
        let%lwt value = delayed_value ~ms:200 "DONE :)" in
        Lwt.return (React.string value))
  in
  let app () = React.Suspense.make ~fallback:(React.string "Loading...") ~children:deffered_component () in
  let main = React.Upper_case_component app in
  let%lwt stream = ReactServerDOM.render_model main in
  assert_stream stream
    [
      "1:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L2\"}]\n";
      "0:\"$1\"\n";
      "2:\"DONE :)\"\n";
    ]

let async_component_without_suspense () =
  (* Because there's no Suspense. We await for the promise to resolve before rendering the component *)
  let app =
    React.Async_component
      (fun () ->
        let%lwt value = delayed_value ~ms:100 "DONE :)" in
        Lwt.return (React.string value))
  in
  let%lwt stream = ReactServerDOM.render_model app in
  assert_stream stream [ "0:\"$L1\"\n"; "1:\"DONE :)\"\n" ]

let async_component_without_suspense_immediate () =
  let app =
    React.Async_component
      (fun () ->
        let%lwt value = delayed_value ~ms:0 "DONE :)" in
        Lwt.return (React.string value))
  in
  let%lwt stream = ReactServerDOM.render_model app in
  assert_stream stream [ "0:\"$L1\"\n"; "1:\"DONE :)\"\n" ]

let client_without_props () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.list
          [
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props = [];
                client = React.string "Client without Props";
                import_module = "./client-without-props.js";
                import_name = "ClientWithoutProps";
              };
          ])
  in
  let%lwt stream = ReactServerDOM.render_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-without-props.js\",[],\"ClientWithoutProps\"]\n";
      "1:[[\"$\",\"div\",null,{\"children\":\"Server Content\"}],[\"$\",\"$2\",null,{}]]\n";
      "0:\"$1\"\n";
    ]

let client_with_json_props () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.list
          [
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props =
                  [
                    ("null", React.Json `Null);
                    ("string", React.Json (`String "Title"));
                    ("int", React.Json (`Int 1));
                    ("float", React.Json (`Float 1.1));
                    ("bool true", React.Json (`Bool true));
                    ("bool false", React.Json (`Bool false));
                    ("string list", React.Json (`List [ `String "Item 1"; `String "Item 2" ]));
                    ("object", React.Json (`Assoc [ ("name", `String "John"); ("age", `Int 30) ]));
                  ];
                client = React.string "Client with Props";
                import_module = "./client-with-props.js";
                import_name = "ClientWithProps";
              };
          ])
  in
  let%lwt stream = ReactServerDOM.render_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n";
      "1:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"}],[\"$\",\"$2\",null,{\"null\":null,\"string\":\"Title\",\"int\":1,\"float\":1.1,\"bool \
       true\":true,\"bool false\":false,\"string list\":[\"Item 1\",\"Item \
       2\"],\"object\":{\"name\":\"John\",\"age\":30}}]]\n";
      "0:\"$1\"\n";
    ]

let client_with_element_props () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.list
          [
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props = [ ("children", React.Element (React.string "Client Content")) ];
                client = React.string "Client with Props";
                import_module = "./client-with-props.js";
                import_name = "ClientWithProps";
              };
          ])
  in
  let%lwt stream = ReactServerDOM.render_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n";
      "1:[[\"$\",\"div\",null,{\"children\":\"Server Content\"}],[\"$\",\"$2\",null,{\"children\":\"Client Content\"}]]\n";
      "0:\"$1\"\n";
    ]

let client_with_promise_props () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.list
          [
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props =
                  [ ("promise", React.Promise (delayed_value ~ms:200 "||| Resolved |||", fun res -> `String res)) ];
                client = React.string "Client with Props";
                import_module = "./client-with-props.js";
                import_name = "ClientWithProps";
              };
          ])
  in
  let%lwt stream = ReactServerDOM.render_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n";
      "1:[[\"$\",\"div\",null,{\"children\":\"Server Content\"}],[\"$\",\"$2\",null,{\"promise\":\"$@3\"}]]\n";
      "0:\"$1\"\n";
      "3:\"||| Resolved |||\"\n";
    ]

let mixed_server_and_client () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.list
          [
            React.createElement "header" [] [ React.string "Server Header" ];
            React.Client_component
              { props = []; client = React.string "Client 1"; import_module = "./client-1.js"; import_name = "Client1" };
            React.createElement "footer" [] [ React.string "Server Footer" ];
            React.Client_component
              { props = []; client = React.string "Client 2"; import_module = "./client-2.js"; import_name = "Client2" };
          ])
  in
  let%lwt stream = ReactServerDOM.render_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-1.js\",[],\"Client1\"]\n";
      "3:I[\"./client-2.js\",[],\"Client2\"]\n";
      "1:[[\"$\",\"header\",null,{\"children\":\"Server \
       Header\"}],[\"$\",\"$2\",null,{}],[\"$\",\"footer\",null,{\"children\":\"Server \
       Footer\"}],[\"$\",\"$3\",null,{}]]\n";
      "0:\"$1\"\n";
    ]

let client_with_server_children () =
  let server_child () = React.createElement "div" [] [ React.string "Server Component Inside Client" ] in
  let app () =
    React.Upper_case_component
      (fun () ->
        React.list
          [
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props = [ ("children", React.Element (React.Upper_case_component server_child)) ];
                client = React.string "Client with Server Children";
                import_module = "./client-with-server-children.js";
                import_name = "ClientWithServerChildren";
              };
          ])
  in
  let%lwt stream = ReactServerDOM.render_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-with-server-children.js\",[],\"ClientWithServerChildren\"]\n";
      "3:[\"$\",\"div\",null,{\"children\":\"Server Component Inside Client\"}]\n";
      "1:[[\"$\",\"div\",null,{\"children\":\"Server Content\"}],[\"$\",\"$2\",null,{\"children\":\"$3\"}]]\n";
      "0:\"$1\"\n";
    ]

let key_renders_outside_of_props () =
  let app =
    React.createElementWithKey ~key:(Some "important key") "section"
      [ React.JSX.String ("className", "className", "sidebar-header") ]
      [ React.createElement "strong" [] [ React.string "React Notes" ] ]
  in
  let%lwt stream = ReactServerDOM.render_model app in
  assert_stream stream
    [
      "0:[\"$\",\"section\",\"important key\",{\"children\":[\"$\",\"strong\",null,{\"children\":\"React \
       Notes\"}],\"className\":\"sidebar-header\"}]\n";
    ]

let style_as_json () =
  let app =
    React.createElement "div"
      [ React.JSX.style (ReactDOMStyle.make ~color:"red" ~background:"blue" ~zIndex:"34" ()) ]
      []
  in
  let%lwt stream = ReactServerDOM.render_model app in
  assert_stream stream
    [ "0:[\"$\",\"div\",null,{\"style\":{\"zIndex\":\"34\",\"color\":\"red\",\"background\":\"blue\"}}]\n" ]

let act_with_simple_response () =
  let response = React.Json (`String "Server Content") in
  let%lwt stream = ReactServerDOM.create_action_response response in
  assert_stream stream [ "0:\"Server Content\"\n" ]

let ensure_dev_adds_debug_info () =
  let app = React.createElement "h1" [] [ React.string "Hello :)" ] in
  let%lwt stream = ReactServerDOM.render_model ~__DEV__:"development" app in
  assert_stream stream
    [ "0:[\"$\",\"div\",null,{\"style\":{\"zIndex\":\"34\",\"color\":\"red\",\"background\":\"blue\"}}]\n" ]

let tests =
  [
    test "null_element" null_element;
    test "string_element" string_element;
    test "key_renders_outside_of_props" key_renders_outside_of_props;
    test "style_as_json" style_as_json;
    test "lower_case_component" lower_case_component;
    test "lower_case_component_nested" lower_case_component_nested;
    test "lower_case_with_children" lower_case_with_children;
    test "dangerouslySetInnerHtml" dangerouslySetInnerHtml;
    test "upper_case_component" upper_case_component;
    test "upper_case_with_list" upper_case_with_list;
    test "upper_case_with_children" upper_case_with_children;
    test "suspense_without_promise" suspense_without_promise;
    test "suspense_with_promise" suspense_with_promise;
    test "suspense_with_immediate_promise" suspense_with_immediate_promise;
    test "suspense" suspense;
    test "async_component_without_suspense" async_component_without_suspense;
    test "client_with_promise_props" client_with_promise_props;
    test "async_component_without_suspense_immediate" async_component_without_suspense_immediate;
    test "mixed_server_and_client" mixed_server_and_client;
    test "client_with_json_props" client_with_json_props;
    test "client_without_props" client_without_props;
    test "client_with_element_props" client_with_element_props;
    test "client_with_server_children" client_with_server_children;
    test "act_with_simple_response" act_with_simple_response;
    test "ensure_dev_adds_debug_info" ensure_dev_adds_debug_info;
  ]
