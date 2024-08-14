let yojson = Alcotest.testable Yojson.Safe.pretty_print ( = )
let check_json = Alcotest.check yojson "should be equal"
let assert_json left right = Alcotest.check yojson "should be equal" right left

let assert_list (type a) (ty : a Alcotest.testable) (left : a list)
    (right : a list) =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let test title fn = Alcotest_lwt.test_case title `Quick fn

let assert_stream (type a) (checker : a Alcotest.testable)
    (stream : a Lwt_stream.t) (expected : a list) =
  let open Lwt.Infix in
  Lwt_stream.to_list stream >>= fun content ->
  if content = [] then Lwt.return @@ Alcotest.fail "stream should not be empty"
  else Lwt.return @@ assert_list checker content expected

let json_from_string = Yojson.Safe.from_string

let null_element _switch () =
  let app = React.null in
  let%lwt stream, _ = ReactServer.render app in
  assert_stream yojson stream [ json_from_string {|null|} ]

let lower_case_component _switch () =
  let app = React.createElement "div" [] [] in
  let%lwt stream, _ = ReactServer.render app in
  assert_stream yojson stream [ json_from_string {|["$","div",null,{} ]|} ]

let lower_case_component_with_children _switch () =
  let app =
    React.createElement "div" []
      [
        React.createElement "span" [] [ React.string "Home" ];
        React.createElement "span" [] [ React.string "Nohome" ];
      ]
  in
  let%lwt stream, _ = ReactServer.render app in
  assert_stream yojson stream
    [
      json_from_string
        {|["$","div",null,{"children":[["$","span",null,{"children":"Home"}],["$","span",null,{"children":"Nohome"}]]}]|};
    ]

let dangerouslySetInnerHtml _switch () =
  let app =
    React.createElement "script"
      [
        React.JSX.String ("type", "application/javascript");
        React.JSX.DangerouslyInnerHtml "console.log('Hi!')";
      ]
      []
  in
  let%lwt stream, _ = ReactServer.render app in
  assert_stream yojson stream
    [
      json_from_string
        {|["$","script",null,{"type":"application/javascript","dangerouslySetInnerHTML":{"__html":"console.log('Hi!')"}}]|};
    ]

let tests =
  ( "ReactServer.render",
    [
      test "null_element" null_element;
      test "lower_case_component" lower_case_component;
      test "lower_case_component_with_children"
        lower_case_component_with_children;
      test "dangerouslySetInnerHtml" dangerouslySetInnerHtml;
    ] )
