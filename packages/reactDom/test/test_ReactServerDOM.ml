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
  let%lwt stream, _ = ReactServerDOM.render app in
  assert_stream stream [ "0:null\n" ]

let lower_case_component () =
  let app =
    React.createElement "div" (ReactDOM.domProps ~className:"foo" ()) []
  in
  let%lwt stream, _ = ReactServerDOM.render app in
  assert_stream stream [ "0:[\"$\",\"div\",null,{\"className\":\"foo\"}]\n" ]

let lower_case_component_with_children () =
  let app =
    React.createElement "div" []
      [
        React.createElement "span" [] [ React.string "Home" ];
        React.createElement "span" [] [ React.string "Nohome" ];
      ]
  in
  let%lwt stream, _ = ReactServerDOM.render app in
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
  let%lwt stream, _ = ReactServerDOM.render app in
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
  let%lwt stream, _ = ReactServerDOM.render (app true) in
  assert_stream stream [ "0:[\"$\",\"span\",null,{\"children\":\"foo\"}]\n" ]

let tests =
  ( "ReactServerDOM.render",
    [
      test "null_element" null_element;
      test "lower_case_component" lower_case_component;
      test "lower_case_component_with_children"
        lower_case_component_with_children;
      test "dangerouslySetInnerHtml" dangerouslySetInnerHtml;
      test "upper_case_component" upper_case_component;
    ] )
