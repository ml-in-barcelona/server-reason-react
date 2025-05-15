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

let head ?(attributes = []) ?(children = []) () =
  React.Lower_case_element { key = None; tag = "head"; attributes; children }

let body ?(attributes = []) ?(children = []) () =
  React.Lower_case_element { key = None; tag = "body"; attributes; children }

let html ?(attributes = []) children = React.Lower_case_element { key = None; tag = "html"; attributes; children }

let lower tag ?(attributes = []) ?(children = []) () =
  React.Lower_case_element { key = None; tag; attributes; children }

let input ?(attributes = []) () = React.Lower_case_element { key = None; tag = "input"; attributes; children = [] }

let just_an_html_node () =
  let app = html [] in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><head></head></html>";
  Lwt.return ()

let doctype () =
  let app = html [ head (); body () ] in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><head></head><body></body></html>";
  Lwt.return ()

let no_head_no_body_nothing_just_an_html_node () =
  let app = input () in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<input />";
  Lwt.return ()

let html_with_a_node () =
  let app = html [ input () ] in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><head></head><input /></html>";
  Lwt.return ()

let html_with_only_a_body () =
  let app = html [ lower "body" ~children:[ lower "div" ~children:[ React.string "Just body content" ] () ] () ] in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><head></head><body><div>Just body content</div></body></html>";
  Lwt.return ()

let head_with_content () =
  let app =
    html
      [
        head
          ~children:
            [
              lower "title" ~children:[ React.string "Titulaso" ] ();
              lower "meta" ~attributes:[ React.JSX.String ("charset", "charSet", "utf-8") ] ();
            ]
          ();
      ]
  in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><head><title>Titulaso</title><meta charset=\"utf-8\" /></head></html>";
  Lwt.return ()

let html_inside_a_div () =
  let app = lower "div" ~children:[ html [] ] () in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<div><html></html></div>";
  Lwt.return ()

let html_inside_a_fragment () =
  let app = React.Fragment (React.list [ html [ lower "div" () ] ]) in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><div></div></html>";
  Lwt.return ()

let html_with_head_like_elements_not_in_head () =
  let app =
    html
      [
        lower "meta" ~attributes:[ React.JSX.String ("charset", "charSet", "utf-8") ] ();
        lower "title" ~children:[ React.string "Implicit Head?" ] ();
      ]
  in
  let%lwt html, _ = ReactServerDOM.render_html app in
  assert_string html "<!DOCTYPE html><html><head><meta charset=\"utf-8\" /><title>Implicit Head?</title></head></html>";
  Lwt.return ()

let html_without_body_and_bootstrap_scritpts () =
  let app = html [ lower "input" ~attributes:[ React.JSX.String ("id", "id", "sidebar-search-input") ] () ] in
  let%lwt html, _ =
    ReactServerDOM.render_html ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
      app
  in
  assert_string html
    "<!DOCTYPE html><html><head></head><input id=\"sidebar-search-input\" \
     /><script>console.log('hello')</script><script src=\"react\" async=\"\" type=\"module\"></script><script \
     src=\"react-dom\" async=\"\" type=\"module\"></script></html>";
  Lwt.return ()

let html_with_body_and_bootstrap_scripts () =
  let app =
    html
      [ body ~children:[ lower "input" ~attributes:[ React.JSX.String ("id", "id", "sidebar-search-input") ] () ] () ]
  in
  let%lwt html, _ =
    ReactServerDOM.render_html ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
      app
  in
  assert_string html
    "<!DOCTYPE html><html><head></head><body><input id=\"sidebar-search-input\" \
     /><script>console.log('hello')</script><script src=\"react\" async=\"\" type=\"module\"></script><script \
     src=\"react-dom\" async=\"\" type=\"module\"></script></body></html>";
  Lwt.return ()

let input_and_bootstrap_scripts () =
  let app = lower "input" ~attributes:[ React.JSX.String ("id", "id", "sidebar-search-input") ] () in
  let%lwt html, _ =
    ReactServerDOM.render_html ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
      app
  in
  assert_string html
    "<input id=\"sidebar-search-input\" /><script>console.log('hello')</script><script src=\"react\" async=\"\" \
     type=\"module\"></script><script src=\"react-dom\" async=\"\" type=\"module\"></script>";
  Lwt.return ()

let title_populates_to_a_head () =
  let app =
    html [ body ~children:[ head ~children:[ lower "title" ~children:[ React.string "Hey Yah" ] () ] () ] () ]
  in
  let%lwt html, _ = ReactServerDOM.render_html ~bootstrapModules:[ "jquery"; "jquery-mobile" ] app in
  assert_string html
    "<!DOCTYPE html><html><head><title>Hey Yah</title></head><body><script src=\"jquery\" async=\"\" \
     type=\"module\"></script><script src=\"jquery-mobile\" async=\"\" type=\"module\"></script></body></html>";
  Lwt.return ()

let tests =
  [
    test "doctype" doctype;
    test "just_an_html_node" just_an_html_node;
    test "no_head_no_body_nothing_just_an_html_node" no_head_no_body_nothing_just_an_html_node;
    test "html_with_a_node" html_with_a_node;
    test "html_inside_a_div" html_inside_a_div;
    test "html_inside_a_fragment" html_inside_a_fragment;
    test "head_with_content" head_with_content;
    test "html_with_only_a_body" html_with_only_a_body;
    test "html_with_head_like_elements_not_in_head" html_with_head_like_elements_not_in_head;
    test "html_without_body_and_bootstrap_scritpts" html_without_body_and_bootstrap_scritpts;
    test "html_with_body_and_bootstrap_scripts" html_with_body_and_bootstrap_scripts;
    test "input_and_bootstrap_scripts" input_and_bootstrap_scripts;
    test "title_populates_to_a_head" title_populates_to_a_head;
  ]
