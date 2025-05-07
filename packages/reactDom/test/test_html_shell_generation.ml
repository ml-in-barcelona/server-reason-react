let yojson = Alcotest.testable Yojson.Safe.pretty_print ( = )
let check_json = Alcotest.check yojson "should be equal"

let assert_list (type a) (ty : a Alcotest.testable) (left : a list) (right : a list) =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let assert_list_of_strings (left : string list) (right : string list) =
  Alcotest.check (Alcotest.list Alcotest.string) "should be equal" right left

let test title fn =
  ( Printf.sprintf "ReactServerDOM.render_html / %s" title,
    [
      Alcotest_lwt.test_case "" `Quick (fun _switch () ->
          let test_promise = fn () in
          test_promise);
    ] )

let stream_close_script = "<script>window.srr_stream.close()</script>"

let doctype () =
  let app =
    React.Lower_case_element
      {
        key = None;
        tag = "html";
        attributes = [];
        children =
          [
            React.Lower_case_element { key = None; tag = "head"; attributes = []; children = [] };
            React.Lower_case_element { key = None; tag = "body"; attributes = []; children = [] };
          ];
      }
  in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><head></head><body></body></html>";
  Lwt.return ()

let no_head_no_body_nothing_just_an_html_node () =
  let app = React.Lower_case_element { key = None; tag = "input"; attributes = []; children = [] } in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<input />";
  Lwt.return ()

let html_with_an_html_node () =
  let app =
    React.Lower_case_element
      {
        key = None;
        tag = "html";
        attributes = [];
        children = [ React.Lower_case_element { key = None; tag = "input"; attributes = []; children = [] } ];
      }
  in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><input /></html>";
  Lwt.return ()

let html_inside_a_div () =
  let app =
    React.Lower_case_element
      {
        key = None;
        tag = "div";
        attributes = [];
        children = [ React.Lower_case_element { key = None; tag = "html"; attributes = []; children = [] } ];
      }
  in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<div><html></html></div>";
  Lwt.return ()

let html_inside_a_fragment () =
  let app =
    React.Fragment
      (React.list
         [
           React.Lower_case_element
             {
               key = None;
               tag = "html";
               attributes = [];
               children = [ React.Lower_case_element { key = None; tag = "div"; attributes = []; children = [] } ];
             };
         ])
  in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><div></div></html>";
  Lwt.return ()

let tests =
  [
    test "doctype" doctype;
    test "no_head_no_body_nothing_just_an_html_node" no_head_no_body_nothing_just_an_html_node;
    test "html_with_an_html_node" html_with_an_html_node;
    test "html_inside_a_div" html_inside_a_div;
    test "html_inside_a_fragment" html_inside_a_fragment;
  ]
