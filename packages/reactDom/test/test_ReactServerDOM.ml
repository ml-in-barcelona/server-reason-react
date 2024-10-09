let yojson = Alcotest.testable Yojson.Safe.pretty_print ( = )
let check_json = Alcotest.check yojson "should be equal"
let assert_json left right = Alcotest.check yojson "should be equal" right left

let assert_list (type a) (ty : a Alcotest.testable) (left : a list)
    (right : a list) =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_list_of_strings (left : string list) (right : string list) =
  Alcotest.check (Alcotest.list Alcotest.string) "should be equal" right left

let test title fn =
  Alcotest_lwt.test_case title `Quick (fun _switch body -> fn body)

let assert_stream (stream : string Lwt_stream.t) (expected : string list) =
  let open Lwt.Infix in
  Lwt_stream.to_list stream >>= fun content ->
  if content = [] then Lwt.return @@ Alcotest.fail "stream should not be empty"
  else Lwt.return @@ assert_list_of_strings content expected

let null_element () =
  let app = React.null in
  let%lwt stream = ReactServerDOM.to_model app in
  assert_stream stream [ "0:null\n" ]

let lower_case_component () =
  let app =
    React.createElement "div" (ReactDOM.domProps ~className:"foo" ()) []
  in
  let%lwt stream = ReactServerDOM.to_model app in
  assert_stream stream [ "0:[\"$\",\"div\",null,{\"className\":\"foo\"}]\n" ]

let lower_case_component_with_children () =
  let app =
    React.createElement "div" []
      [
        React.createElement "span" [] [ React.string "Home" ];
        React.createElement "span" [] [ React.string "Nohome" ];
      ]
  in
  let%lwt stream = ReactServerDOM.to_model app in
  assert_stream stream
    [
      "0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"span\",null,{\"children\":\"Home\"}],[\"$\",\"span\",null,{\"children\":\"Nohome\"}]]}]\n";
    ]

let dangerouslySetInnerHtml () =
  let app =
    React.createElement "script"
      [
        React.JSX.String ("type", "application/javascript");
        React.JSX.DangerouslyInnerHtml "console.log('Hi!')";
      ]
      []
  in
  let%lwt stream = ReactServerDOM.to_model app in
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
  let%lwt stream = ReactServerDOM.to_model (app true) in
  assert_stream stream [ "0:[\"$\",\"span\",null,{\"children\":\"foo\"}]\n" ]

let client_component_without_props () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.List
          [|
            React.createElement "span" [] [ React.string "Server" ];
            React.Client_component
              {
                props = [];
                children = React.string "Client";
                import_module = "./client-component.js";
                import_name = "Client_component";
              };
          |])
  in
  let%lwt stream = ReactServerDOM.to_model (app ()) in
  assert_stream stream
    [
      "1:I[\"./client-component.js\",[],\"Client_component\"]\n";
      "0:[[\"$\",\"span\",null,{\"children\":\"Server\"}],[\"$\",\"$1\",null,{}]]\n";
    ]

let client_component_with_props () =
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
                    ("title", React.Json (`String "Title"));
                    ("value", React.Json (`String "Value"));
                  ];
                children = React.string "Client with Props";
                import_module = "./client-with-props.js";
                import_name = "ClientWithProps";
              };
          |])
  in
  let%lwt stream = ReactServerDOM.to_model (app ()) in
  assert_stream stream
    [
      "1:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n";
      "0:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"}],[\"$\",\"$1\",null,{\"title\":\"Title\",\"value\":\"Value\"}]]\n";
    ]

(* let nested_client_components () =
   let app () =
     React.Upper_case_component
       (fun () ->
         React.Client_component
           {
             props = [];
             children =
               React.Client_component
                 {
                   props = [];
                   children = React.string "Inner Client";
                   import_module = "./inner-client.js";
                   import_name = "InnerClient";
                 };
             import_module = "./outer-client.js";
             import_name = "OuterClient";
           })
   in
   let%lwt stream = ReactServerDOM.to_model (app ()) in
   assert_stream stream
     [
       "1:I[\"./inner-client.js\",[],\"InnerClient\"]\n";
       "2:I[\"./outer-client.js\",[],\"OuterClient\"]\n";
       "0:[[\"$\",\"$2\",null,{}]]\n";
     ] *)

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
                children = React.string "Client 1";
                import_module = "./client-1.js";
                import_name = "Client1";
              };
            React.createElement "footer" [] [ React.string "Server Footer" ];
            React.Client_component
              {
                props = [];
                children = React.string "Client 2";
                import_module = "./client-2.js";
                import_name = "Client2";
              };
          |])
  in
  let%lwt stream = ReactServerDOM.to_model (app ()) in
  assert_stream stream
    [
      "1:I[\"./client-1.js\",[],\"Client1\"]\n";
      "2:I[\"./client-2.js\",[],\"Client2\"]\n";
      "0:[[\"$\",\"header\",null,{\"children\":\"Server \
       Header\"}],[\"$\",\"$1\",null,{}],[\"$\",\"footer\",null,{\"children\":\"Server \
       Footer\"}],[\"$\",\"$2\",null,{}]]\n";
    ]

(* let client_component_with_list_as_element () =
   let app () =
     React.Upper_case_component
       (fun () ->
         React.Client_component
           {
             props = [];
             children =
               React.List
                 [|
                   React.string "Client List Item 1";
                   React.string "Client List Item 2";
                   React.string "Client List Item 3";
                 |];
             import_module = "./client-list.js";
             import_name = "ClientList";
           })
   in
   let%lwt stream = ReactServerDOM.to_model (app ()) in
   assert_stream stream
     [
       "1:I[\"./client-list.js\",[],\"ClientList\"]\n";
       "0:[[\"$\",\"$1\",null,{}]]\n";
     ] *)

let deeply_nested_server_content () =
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
  let%lwt stream = ReactServerDOM.to_model (app ()) in
  assert_stream stream
    [
      "0:[\"$\",\"div\",null,{\"children\":[\"$\",\"section\",null,{\"children\":[\"$\",\"article\",null,{\"children\":\"Deep \
       Server Content\"}]}]}]\n";
    ]

let tests =
  ( "ReactServerDOM.to_model",
    [
      test "null_element" null_element;
      test "lower_case_component" lower_case_component;
      test "lower_case_component_with_children"
        lower_case_component_with_children;
      test "dangerouslySetInnerHtml" dangerouslySetInnerHtml;
      test "upper_case_component" upper_case_component;
      test "client_component_without_props" client_component_without_props;
      test "client_component_with_props" client_component_with_props;
      test "mixed_server_and_client" mixed_server_and_client;
      test "deeply_nested_server_content" deeply_nested_server_content;
      (* test "client_component_with_list_as_element"
         client_component_with_list_as_element; *)
      (* test "nested_client_components" nested_client_components; *)
    ] )
