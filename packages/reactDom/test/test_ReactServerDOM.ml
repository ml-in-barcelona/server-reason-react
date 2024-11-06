let yojson = Alcotest.testable Yojson.Safe.pretty_print ( = )
let check_json = Alcotest.check yojson "should be equal"
let assert_json left right = Alcotest.check yojson "should be equal" right left

let assert_list (type a) (ty : a Alcotest.testable) (left : a list)
    (right : a list) =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_list_of_strings (left : string list) (right : string list) =
  Alcotest.check (Alcotest.list Alcotest.string) "should be equal" right left

let is_not_zero x epsilon = abs_float x >= epsilon

let test title (fn : unit -> unit Lwt.t) =
  Alcotest_lwt.test_case title `Quick (fun _switch () ->
      let start = Unix.gettimeofday () in
      let timeout =
        let%lwt () = Lwt_unix.sleep 3.0 in
        Alcotest.failf "Test '%s' timed out" title
      in
      let%lwt test_promise = Lwt.pick [ fn (); timeout ] in
      let epsilon = 0.001 in
      let duration = Unix.gettimeofday () -. start in
      if is_not_zero duration epsilon then
        Printf.printf
          "\027[1m\027[33m[WARNING]\027[0m Test '%s' took %.3f seconds\n" title
          duration
      else ();
      Lwt.return test_promise)

let assert_stream (stream : string Lwt_stream.t) (expected : string list) =
  let%lwt content = Lwt_stream.to_list stream in
  if content = [] then Lwt.return @@ Alcotest.fail "stream should not be empty"
  else Lwt.return @@ assert_list_of_strings content expected

let test_silly_stream () =
  let stream, push = Lwt_stream.create () in
  push (Some "first");
  let%lwt () = Lwt_unix.sleep 0.1 in
  push (Some "secondo");
  let%lwt () = Lwt_unix.sleep 0.1 in
  push (Some "trienio");
  push None;
  assert_stream stream [ "first"; "secondo"; "trienio" ]

let null_element () =
  let app = React.null in
  let%lwt stream = ReactServerDOM.render_to_model app in
  assert_stream stream [ "0:null\n" ]

let string_element () =
  let app = React.string "hi" in
  let%lwt stream = ReactServerDOM.render_to_model app in
  assert_stream stream [ "0:\"hi\"\n" ]

let lower_case_component () =
  let app =
    React.createElement "div" (ReactDOM.domProps ~className:"foo" ()) []
  in
  let%lwt stream = ReactServerDOM.render_to_model app in
  assert_stream stream [ "0:[\"$\",\"div\",null,{\"className\":\"foo\"}]\n" ]

let lower_case_with_children () =
  let app =
    React.createElement "div" []
      [
        React.createElement "span" [] [ React.string "Home" ];
        React.createElement "span" [] [ React.string "Nohome" ];
      ]
  in
  let%lwt stream = ReactServerDOM.render_to_model app in
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
            React.createElement "section" []
              [
                React.createElement "article" []
                  [ React.string "Deep Server Content" ];
              ];
          ])
  in
  let%lwt stream = ReactServerDOM.render_to_model (app ()) in
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
        React.JSX.String ("type", "type", "application/javascript");
        React.JSX.DangerouslyInnerHtml "console.log('Hi!')";
      ]
      []
  in
  let%lwt stream = ReactServerDOM.render_to_model app in
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
  let%lwt stream = ReactServerDOM.render_to_model (app true) in
  assert_stream stream
    [ "1:[\"$\",\"span\",null,{\"children\":\"foo\"}]\n"; "0:\"$1\"\n" ]

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
  let%lwt stream = ReactServerDOM.render_to_model (app ()) in
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
  let%lwt stream = ReactServerDOM.render_to_model (app ()) in
  assert_stream stream
    [
      "2:[\"$\",\"span\",null,{\"children\":\"hi\"}]\n";
      "3:[\"$\",\"span\",null,{\"children\":\"hola\"}]\n";
      "1:[\"$\",\"div\",null,{\"children\":[\"$2\",\"$3\"]}]\n";
      "0:\"$1\"\n";
    ]

let suspense_without_promise () =
  let app () =
    React.Suspense.make
      ~fallback:(React.string "Loading...")
      ~children:
        (React.createElement "div" []
           [
             React.Upper_case_component (text ~children:[ React.string "hi" ]);
             React.Upper_case_component (text ~children:[ React.string "hola" ]);
           ])
      ()
  in
  let main = React.Upper_case_component app in
  let%lwt stream = ReactServerDOM.render_to_model main in
  assert_stream stream
    [
      "2:[\"$\",\"span\",null,{\"children\":\"hi\"}]\n";
      "3:[\"$\",\"span\",null,{\"children\":\"hola\"}]\n";
      "1:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":[\"$\",\"div\",null,{\"children\":[\"$2\",\"$3\"]}]}]\n";
      "0:\"$1\"\n";
    ]

let immediate_suspense () =
  let suspended_component =
    React.Async_component
      (fun () ->
        let value = "DONE :)" in
        Lwt.return (React.string value))
  in
  let app () =
    React.Suspense.make
      ~fallback:(React.string "Loading...")
      ~children:suspended_component ()
  in
  let main = React.Upper_case_component app in
  let%lwt stream = ReactServerDOM.render_to_model main in
  assert_stream stream
    [
      "1:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"DONE \
       :)\"}]\n";
      "0:\"$1\"\n";
    ]

let delayed_value ?(ms = 100) value =
  let%lwt () = Lwt_unix.sleep (Int.to_float ms /. 100.0) in
  Lwt.return value

let suspense () =
  let suspended_component =
    React.Async_component
      (fun () ->
        let open Lwt.Syntax in
        let+ value = delayed_value "DONE :)" in
        React.string value)
  in
  let app () =
    React.Suspense.make
      ~fallback:(React.string "Loading...")
      ~children:suspended_component ()
  in
  let main = React.Upper_case_component app in
  let%lwt stream = ReactServerDOM.render_to_model main in
  assert_stream stream
    [
      "1:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L2\"}]\n";
      "0:\"$1\"\n";
      "2:\"DONE :)\"\n";
    ]

let client_without_props () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.List
          [|
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props = [];
                client = React.string "Client without Props";
                import_module = "./client-without-props.js";
                import_name = "ClientWithoutProps";
              };
          |])
  in
  let%lwt stream = ReactServerDOM.render_to_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-without-props.js\",[],\"ClientWithoutProps\"]\n";
      "1:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"}],[\"$\",\"$2\",null,{}]]\n";
      "0:\"$1\"\n";
    ]

let client_with_json_props () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.List
          [|
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
                    ( "string list",
                      React.Json (`List [ `String "Item 1"; `String "Item 2" ])
                    );
                    ( "object",
                      React.Json
                        (`Assoc [ ("name", `String "John"); ("age", `Int 30) ])
                    );
                  ];
                client = React.string "Client with Props";
                import_module = "./client-with-props.js";
                import_name = "ClientWithProps";
              };
          |])
  in
  let%lwt stream = ReactServerDOM.render_to_model (app ()) in
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
        React.List
          [|
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props =
                  [
                    ("children", React.Element (React.string "Client Content"));
                  ];
                client = React.string "Client with Props";
                import_module = "./client-with-props.js";
                import_name = "ClientWithProps";
              };
          |])
  in
  let%lwt stream = ReactServerDOM.render_to_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n";
      "1:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"}],[\"$\",\"$2\",null,{\"children\":\"Client Content\"}]]\n";
      "0:\"$1\"\n";
    ]

let client_with_promise_props () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.List
          [|
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props =
                  [
                    ( "promise",
                      React.Promise
                        ( delayed_value ~ms:200 "||| Resolved |||",
                          fun res -> `String res ) );
                  ];
                client = React.string "Client with Props";
                import_module = "./client-with-props.js";
                import_name = "ClientWithProps";
              };
          |])
  in
  let%lwt stream = ReactServerDOM.render_to_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n";
      "1:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"}],[\"$\",\"$2\",null,{\"promise\":\"$@3\"}]]\n";
      "0:\"$1\"\n";
      "3:\"||| Resolved |||\"\n";
    ]

let mixed_server_and_client () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.List
          [|
            React.createElement "header" [] [ React.string "Server Header" ];
            React.Client_component
              {
                props = [];
                client = React.string "Client 1";
                import_module = "./client-1.js";
                import_name = "Client1";
              };
            React.createElement "footer" [] [ React.string "Server Footer" ];
            React.Client_component
              {
                props = [];
                client = React.string "Client 2";
                import_module = "./client-2.js";
                import_name = "Client2";
              };
          |])
  in
  let%lwt stream = ReactServerDOM.render_to_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-1.js\",[],\"Client1\"]\n";
      "3:I[\"./client-2.js\",[],\"Client2\"]\n";
      "1:[[\"$\",\"header\",null,{\"children\":\"Server \
       Header\"}],[\"$\",\"$2\",null,{}],[\"$\",\"footer\",null,{\"children\":\"Server \
       Footer\"}],[\"$\",\"$3\",null,{}]]\n";
      "0:\"$1\"\n";
    ]

let tests =
  ( "ReactServerDOM.render_to_model",
    [
      test "null_element" null_element;
      test "string_element" string_element;
      test "lower_case_component" lower_case_component;
      test "lower_case_component_nested" lower_case_component_nested;
      test "lower_case_with_children" lower_case_with_children;
      test "dangerouslySetInnerHtml" dangerouslySetInnerHtml;
      test "upper_case_component" upper_case_component;
      test "upper_case_with_list" upper_case_with_list;
      test "upper_case_with_children" upper_case_with_children;
      test "suspense_without_promise" suspense_without_promise;
      test "immediate_suspense" immediate_suspense;
      test "suspense" suspense;
      test "mixed_server_and_client" mixed_server_and_client;
      test "client_with_json_props" client_with_json_props;
      test "client_without_props" client_without_props;
      test "client_with_element_props" client_with_element_props;
      test "client_with_promise_props" client_with_promise_props;
    ] )
