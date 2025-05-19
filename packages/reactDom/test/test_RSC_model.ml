let yojson = Alcotest.testable Yojson.Safe.pretty_print ( = )
let check_json = Alcotest.check yojson "should be equal"
let assert_json left right = Alcotest.check yojson "should be equal" right left

let assert_list (type a) (ty : a Alcotest.testable) (left : a list) (right : a list) =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_list_of_strings left right = Alcotest.check (Alcotest.list Alcotest.string) "should be equal" right left

let lwt_sleep ~ms =
  let%lwt () = Lwt_unix.sleep (Int.to_float ms /. 1000.0) in
  Lwt.return ()

let test title fn =
  let test_case _switch () =
    let start = Unix.gettimeofday () in
    let timeout =
      let%lwt () = lwt_sleep ~ms:100 in
      Alcotest.failf "Test '%s' timed out" title
    in
    let%lwt test_promise = Lwt.pick [ fn (); timeout ] in
    let epsilon = 0.001 in
    let duration = Unix.gettimeofday () -. start in
    if abs_float duration >= epsilon then
      Printf.printf "\027[1m\027[33m[WARNING]\027[0m Test '%s' took %.3f seconds\n" title duration
    else ();
    Lwt.return test_promise
  in
  (Printf.sprintf "ReactServerDOM.render_model / %s" title, [ Alcotest_lwt.test_case "" `Quick test_case ])

let[@warning "-27"] skip title _fn =
  let test_case _switch () = Lwt.return () in
  (Printf.sprintf "ReactServerDOM.render_model / %s" title, [ Alcotest_lwt.test_case "" `Quick test_case ])

let assert_stream (stream : string Lwt_stream.t) expected =
  let%lwt content = Lwt_stream.to_list stream in
  if content = [] then Lwt.return @@ Alcotest.fail "stream should not be empty"
  else Lwt.return @@ assert_list_of_strings content expected

let capture_stream () =
  let output = ref [] in
  let subscribe chunk =
    output := !output @ [ chunk ];
    Lwt.return ()
  in
  (output, subscribe)

let text ~children () = React.createElement "span" [] children

(* ***** *)
(* Tests *)
(* ***** *)

let null_element () =
  let app = React.null in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe app in
  assert_list_of_strings !output [ "0:null\n" ];
  Lwt.return ()

let string_element () =
  let app = React.string "hi" in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe app in
  assert_list_of_strings !output [ "0:\"hi\"\n" ];
  Lwt.return ()

let lower_case_component () =
  let app = React.createElement "div" (ReactDOM.domProps ~className:"foo" ()) [] in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe app in
  assert_list_of_strings !output [ "0:[\"$\",\"div\",null,{\"className\":\"foo\"},null,[],{}]\n" ];
  Lwt.return ()

let lower_case_with_children () =
  let app =
    React.createElement "div" []
      [ React.createElement "span" [] [ React.string "Home" ]; React.createElement "span" [] [ React.string "Nohome" ] ]
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe app in
  assert_list_of_strings !output
    [
      "0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"span\",null,{\"children\":\"Home\"},null,[],{}],[\"$\",\"span\",null,{\"children\":\"Nohome\"},null,[],{}]]},null,[],{}]\n";
    ];
  Lwt.return ()

let lower_case_component_nested () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.createElement "div" []
            [
              React.createElement "section" []
                [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
            ] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app ()) in
  assert_list_of_strings !output
    [
      "0:[\"$\",\"div\",null,{\"children\":[\"$\",\"section\",null,{\"children\":[\"$\",\"article\",null,{\"children\":\"Deep \
       Server Content\"},null,[],{}]},null,[],{}]},null,[],{}]\n";
    ];
  Lwt.return ()

let dangerouslySetInnerHtml () =
  let app =
    React.createElement "script"
      [
        React.JSX.String ("type", "type", "application/javascript"); React.JSX.DangerouslyInnerHtml "console.log('Hi!')";
      ]
      []
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe app in
  assert_list_of_strings !output
    [
      "0:[\"$\",\"script\",null,{\"type\":\"application/javascript\",\"dangerouslySetInnerHTML\":{\"__html\":\"console.log('Hi!')\"}},null,[],{}]\n";
    ];
  Lwt.return ()

let upper_case_component () =
  let app codition =
    React.Upper_case_component
      ( "app",
        fun () ->
          let text = if codition then "foo" else "bar" in
          React.createElement "span" [] [ React.string text ] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app true) in
  assert_list_of_strings !output [ "0:[\"$\",\"span\",null,{\"children\":\"foo\"},null,[],{}]\n" ];
  Lwt.return ()

let upper_case_with_list () =
  let app () =
    React.Fragment
      (React.list
         [
           React.Upper_case_component ("Text", text ~children:[ React.string "hi" ]);
           React.Upper_case_component ("Text", text ~children:[ React.string "hola" ]);
         ])
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app ()) in
  assert_list_of_strings !output
    [
      "1:[\"$\",\"span\",null,{\"children\":\"hi\"},null,[],{}]\n";
      "2:[\"$\",\"span\",null,{\"children\":\"hola\"},null,[],{}]\n";
      "0:[\"$1\",\"$2\"]\n";
    ];
  Lwt.return ()

let upper_case_with_children () =
  let layout ~children () = React.createElement "div" [] children in
  let app () =
    React.Upper_case_component
      ( "Layout",
        layout
          ~children:
            [
              React.Upper_case_component ("Text", text ~children:[ React.string "hi" ]);
              React.Upper_case_component ("Text", text ~children:[ React.string "hola" ]);
            ] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app ()) in
  assert_list_of_strings !output
    [
      "1:[\"$\",\"span\",null,{\"children\":\"hi\"},null,[],{}]\n";
      "2:[\"$\",\"span\",null,{\"children\":\"hola\"},null,[],{}]\n";
      "0:[\"$\",\"div\",null,{\"children\":[\"$1\",\"$2\"]},null,[],{}]\n";
    ];
  Lwt.return ()

let suspense_without_promise () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:
        (React.createElement "div" []
           [
             React.Upper_case_component ("Text", text ~children:[ React.string "hi" ]);
             React.Upper_case_component ("Text", text ~children:[ React.string "hola" ]);
           ])
      ()
  in
  let main = React.Upper_case_component ("App", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [
      "1:[\"$\",\"span\",null,{\"children\":\"hi\"},null,[],{}]\n";
      "2:[\"$\",\"span\",null,{\"children\":\"hola\"},null,[],{}]\n";
      "0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":[\"$\",\"div\",null,{\"children\":[\"$1\",\"$2\"]},null,[],{}]},null,[],{}]\n";
    ];
  Lwt.return ()

let suspense_with_promise () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( "suspense_with_promise",
             fun () ->
               let%lwt () = lwt_sleep ~ms:10 in
               Lwt.return (React.string "lol") ))
      ()
  in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [
      "0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]\n";
      "1:\"lol\"\n";
    ];
  Lwt.return ()

let suspense_with_error () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:(React.Async_component (__FUNCTION__, fun () -> Lwt.fail (Failure "lol")))
      ()
  in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [
      "1:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n";
      "0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]\n";
    ];
  Lwt.return ()

let suspense_with_error_under_lowercase () =
  let app () =
    React.createElement "div" []
      [
        React.Suspense.make ~fallback:(React.string "Loading...")
          ~children:(React.Async_component (__FUNCTION__, fun () -> Lwt.fail (Failure "lol")))
          ();
      ]
  in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [
      "1:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n";
      "0:[\"$\",\"div\",null,{\"children\":[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]},null,[],{}]\n";
    ];
  Lwt.return ()

let error_without_suspense () =
  let app () = React.Upper_case_component (__FUNCTION__, fun () -> raise (Failure "lol")) in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [ "1:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n"; "0:\"$L1\"\n" ];
  Lwt.return ()

let error_in_toplevel () =
  let app () = raise (Failure "lol") in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [ "1:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n"; "0:\"$L1\"\n" ];
  Lwt.return ()

let error_in_toplevel_in_async () =
  let app () = Lwt.fail (Failure "lol") in
  let main = React.Async_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [ "1:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n"; "0:\"$L1\"\n" ];
  Lwt.return ()

let await_tick ?(raise = false) num =
  React.Async_component
    ( "await_tick",
      fun () ->
        let%lwt () = lwt_sleep ~ms:(Random.int 10) in
        if raise then Lwt.fail (Failure "lol") else Lwt.return (React.string num) )

let suspense_in_a_list () =
  let fallback = React.string "Loading..." in
  let app () =
    React.Fragment
      (React.list
         [
           React.Suspense.make ~fallback ~children:(await_tick "A") ();
           React.Suspense.make ~fallback ~children:(await_tick "B") ();
           React.Suspense.make ~fallback ~children:(await_tick "C") ();
           React.Suspense.make ~fallback ~children:(await_tick "D") ();
           React.Suspense.make ~fallback ~children:(await_tick "E") ();
         ])
  in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [
      "0:[[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L2\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L3\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L4\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L5\"},null,[],{}]]\n";
      "3:\"C\"\n";
      "2:\"B\"\n";
      "1:\"A\"\n";
      "4:\"D\"\n";
      "5:\"E\"\n";
    ];
  Lwt.return ()

let suspense_in_a_list_with_error () =
  let fallback = React.string "Loading..." in
  let app () =
    React.Fragment
      (React.list
         [
           React.Suspense.make ~fallback ~children:(await_tick "A") ();
           React.Suspense.make ~fallback ~children:(await_tick ~raise:true "B") ();
           React.Suspense.make ~fallback ~children:(await_tick "C") ();
           React.Suspense.make ~fallback ~children:(await_tick "D") ();
           React.Suspense.make ~fallback ~children:(await_tick "E") ();
         ])
  in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [
      "0:[[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L2\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L3\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L4\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L5\"},null,[],{}]]\n";
      "1:\"A\"\n";
      "4:\"D\"\n";
      "5:\"E\"\n";
      "2:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n";
      "3:\"C\"\n";
    ];
  Lwt.return ()

let suspense_with_immediate_promise () =
  let resolved_component =
    React.Async_component
      ( __FUNCTION__,
        fun () ->
          let value = "DONE :)" in
          Lwt.return (React.string value) )
  in
  let app = React.Suspense.make ~fallback:(React.string "Loading...") ~children:resolved_component in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [ "0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"DONE :)\"},null,[],{}]\n" ];
  Lwt.return ()

let delayed_value ~ms value =
  let%lwt () = lwt_sleep ~ms in
  Lwt.return value

let suspense () =
  let suspended_component =
    React.Async_component
      ( __FUNCTION__,
        fun () ->
          let%lwt value = delayed_value ~ms:10 "DONE :)" in
          Lwt.return (React.string value) )
  in
  let app () = React.Suspense.make ~fallback:(React.string "Loading...") ~children:suspended_component () in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [
      "0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]\n";
      "1:\"DONE :)\"\n";
    ];
  Lwt.return ()

let nested_suspense () =
  let deffered_component =
    React.Async_component
      ( __FUNCTION__,
        fun () ->
          let%lwt value = delayed_value ~ms:20 "DONE :)" in
          Lwt.return (React.string value) )
  in
  let app () = React.Suspense.make ~fallback:(React.string "Loading...") ~children:deffered_component () in
  let main = React.Upper_case_component ("app", app) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe main in
  assert_list_of_strings !output
    [ "0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L2\"}]\n"; "1:\"DONE :)\"\n" ];
  Lwt.return ()

let async_component_without_suspense () =
  (* Because there's no Suspense. We await for the promise to resolve before rendering the component *)
  let app =
    React.Async_component
      ( __FUNCTION__,
        fun () ->
          let%lwt value = delayed_value ~ms:10 "DONE :)" in
          Lwt.return (React.string value) )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe app in
  assert_list_of_strings !output [ "0:\"$L1\"\n"; "1:\"DONE :)\"\n" ];
  Lwt.return ()

let async_component_without_suspense_immediate () =
  let app =
    React.Async_component
      ( __FUNCTION__,
        fun () ->
          let%lwt value = delayed_value ~ms:0 "DONE :)" in
          Lwt.return (React.string value) )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe app in
  assert_list_of_strings !output [ "0:\"$L1\"\n"; "1:\"DONE :)\"\n" ];
  Lwt.return ()

let client_without_props () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
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
            ] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app ()) in
  assert_list_of_strings !output
    [
      "1:I[\"./client-without-props.js\",[],\"ClientWithoutProps\"]\n";
      "0:[[\"$\",\"div\",null,{\"children\":\"Server Content\"},null,[],{}],[\"$\",\"$1\",null,{},null,[],{}]]\n";
    ];
  Lwt.return ()

let client_with_json_props () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
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
            ] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app ()) in
  assert_list_of_strings !output
    [
      "1:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n";
      "0:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"},null,[],{}],[\"$\",\"$1\",null,{\"null\":null,\"string\":\"Title\",\"int\":1,\"float\":1.1,\"bool \
       true\":true,\"bool false\":false,\"string list\":[\"Item 1\",\"Item \
       2\"],\"object\":{\"name\":\"John\",\"age\":30}},null,[],{}]]\n";
    ];
  Lwt.return ()

let client_with_element_props () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
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
            ] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app ()) in
  assert_list_of_strings !output
    [
      "1:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n";
      "0:[[\"$\",\"div\",null,{\"children\":\"Server Content\"},null,[],{}],[\"$\",\"$1\",null,{\"children\":\"Client \
       Content\"},null,[],{}]]\n";
    ];
  Lwt.return ()

let client_with_promise_props () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.list
            [
              React.createElement "div" [] [ React.string "Server Content" ];
              React.Client_component
                {
                  props =
                    [ ("promise", React.Promise (delayed_value ~ms:20 "||| Resolved |||", fun res -> `String res)) ];
                  client = React.string "Client with Props";
                  import_module = "./client-with-props.js";
                  import_name = "ClientWithProps";
                };
            ] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app ()) in
  assert_list_of_strings !output
    [
      "1:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n";
      "0:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"},null,[],{}],[\"$\",\"$1\",null,{\"promise\":\"$@2\"},null,[],{}]]\n";
      "2:\"||| Resolved |||\"\n";
    ];
  Lwt.return ()

let mixed_server_and_client () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.list
            [
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
            ] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app ()) in
  assert_list_of_strings !output
    [
      "1:I[\"./client-1.js\",[],\"Client1\"]\n";
      "2:I[\"./client-2.js\",[],\"Client2\"]\n";
      "0:[[\"$\",\"header\",null,{\"children\":\"Server \
       Header\"},null,[],{}],[\"$\",\"$1\",null,{},null,[],{}],[\"$\",\"footer\",null,{\"children\":\"Server \
       Footer\"},null,[],{}],[\"$\",\"$2\",null,{},null,[],{}]]\n";
    ];
  Lwt.return ()

let client_with_server_children () =
  let server_child () = React.createElement "div" [] [ React.string "Server Component Inside Client" ] in
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.list
            [
              React.createElement "div" [] [ React.string "Server Content" ];
              React.Client_component
                {
                  props = [ ("children", React.Element (React.Upper_case_component ("Server", server_child))) ];
                  client = React.string "Client with Server Children";
                  import_module = "./client-with-server-children.js";
                  import_name = "ClientWithServerChildren";
                };
            ] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe (app ()) in
  assert_list_of_strings !output
    [
      "1:I[\"./client-with-server-children.js\",[],\"ClientWithServerChildren\"]\n";
      "0:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"},null,[],{}],[\"$\",\"$1\",null,{\"children\":[\"$\",\"div\",null,{\"children\":\"Server Component \
       Inside Client\"},null,[],{}]},null,[],{}]]\n";
    ];
  Lwt.return ()

let key_renders_outside_of_props () =
  let app =
    React.createElementWithKey ~key:(Some "important key") "section"
      [ React.JSX.String ("className", "className", "sidebar-header") ]
      [ React.createElement "strong" [] [ React.string "React Notes" ] ]
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe app in
  assert_list_of_strings !output
    [
      "0:[\"$\",\"section\",\"important key\",{\"children\":[\"$\",\"strong\",null,{\"children\":\"React \
       Notes\"},null,[],{}],\"className\":\"sidebar-header\"},null,[],{}]\n";
    ];
  Lwt.return ()

let style_as_json () =
  let app =
    React.createElement "div"
      [ React.JSX.style (ReactDOMStyle.make ~color:"red" ~background:"blue" ~zIndex:"34" ()) ]
      []
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe app in
  assert_list_of_strings !output
    [ "0:[\"$\",\"div\",null,{\"style\":{\"zIndex\":\"34\",\"color\":\"red\",\"background\":\"blue\"}},null,[],{}]\n" ];
  Lwt.return ()

let act_with_simple_response () =
  let response = Lwt.return (React.Json (`String "Server Content")) in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.create_action_response ~subscribe response in
  assert_list_of_strings !output [ "0:\"Server Content\"\n" ];
  Lwt.return ()

let act_with_error () =
  let output, subscribe = capture_stream () in
  let response = Lwt.fail (Failure "Error") in
  let%lwt () = ReactServerDOM.create_action_response ~subscribe response in
  assert_list_of_strings !output
    [
      "1:E{\"message\":\"Failure(\\\"Error\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"1000123519\"}\n";
      "0:\"$Z1\"\n";
    ];
  Lwt.return ()

let env_development_adds_debug_info () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let value = "my friend" in
          React.createElement "input"
            [
              React.JSX.String ("id", "id", "sidebar-search-input");
              React.JSX.String ("placeholder", "placeholder", "Search");
              React.JSX.String ("value", "value", value);
            ]
            [] )
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe ~debug:true app in
  assert_list_of_strings !output
    [
      "1:{\"name\":\"app\",\"env\":\"Server\",\"key\":null,\"owner\":null,\"stack\":[],\"props\":{}}\n";
      "0:D\"$1\"\n";
      "0:[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\",\"placeholder\":\"Search\",\"value\":\"my \
       friend\"},null,[],{}]\n";
    ];
  Lwt.return ()

(* let env_development_adds_debug_info_2 () =
  let app () =
    React.Fragment
      (React.list
         [
           React.Upper_case_component ("Text", text ~children:[ React.string "hi" ]);
           React.Upper_case_component ("Text", text ~children:[ React.string "hola" ]);
         ])
  in
  let output, subscribe = capture_stream () in
  let%lwt () = ReactServerDOM.render_model ~subscribe ~debug:true (app ()) in
  assert_list_of_strings !output
    [
      "1:{\"name\":\"App\",\"env\":\"Server\",\"key\":null,\"owner\":null,\"stack\":[[\"module \
       code\",\"/Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/arch/server/render-rsc-to-stream.js\",54,42]],\"props\":{}}";
      "0:D\"$1\"";
      "3:{\"name\":\"Comp\",\"env\":\"Server\",\"key\":null,\"owner\":\"$1\",\"stack\":[[\"App\",\"/Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/arch/server/render-rsc-to-stream.js\",50,15]],\"props\":{\"name\":\"hi\"}}";
      "2:D\"$3\"";
      "2:[\"$\",\"h1\",null,{\"children\":[\"Hello \",\"hi\"]},\"$3\",[],1]";
      "5:{\"name\":\"Comp\",\"env\":\"Server\",\"key\":null,\"owner\":\"$1\",\"stack\":[[\"App\",\"/Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/arch/server/render-rsc-to-stream.js\",51,15]],\"props\":{\"name\":\"Hola\"}}";
      "4:D\"$5\"";
      "4:[\"$\",\"h1\",null,{\"children\":[\"Hello \",\"Hola\"]},\"$5\",[],1]";
      "0:[\"$2\",\"$4\"]";
    ];
  Lwt.return () *)

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
    test "suspense_with_error" suspense_with_error;
    test "suspense_with_immediate_promise" suspense_with_immediate_promise;
    test "suspense" suspense;
    test "async_component_without_suspense" async_component_without_suspense;
    test "suspense_in_a_list" suspense_in_a_list;
    test "client_with_promise_props" client_with_promise_props;
    test "async_component_without_suspense_immediate" async_component_without_suspense_immediate;
    test "mixed_server_and_client" mixed_server_and_client;
    test "client_with_json_props" client_with_json_props;
    test "client_without_props" client_without_props;
    test "client_with_element_props" client_with_element_props;
    test "client_with_server_children" client_with_server_children;
    test "act_with_simple_response" act_with_simple_response;
    test "env_development_adds_debug_info" env_development_adds_debug_info;
    test "act_with_error" act_with_error;
    test "error_without_suspense" error_without_suspense;
    test "error_in_toplevel" error_in_toplevel;
    test "error_in_toplevel_in_async" error_in_toplevel_in_async;
    (* test "env_development_adds_debug_info_2" env_development_adds_debug_info_2; *)
    test "suspense_in_a_list_with_error" suspense_in_a_list_with_error;
    test "suspense_with_error_under_lowercase" suspense_with_error_under_lowercase;
  ]
