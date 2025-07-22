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

let assert_html ?(skipRoot = false) ?(shell = "") ?(bootstrapModules = []) ?(bootstrapScriptContent = "") element =
  let begin_html = "<!DOCTYPE html><html><head></head><body></body>" in
  let script_html =
    Printf.sprintf
      {|<script>function $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if("/$"===d)if(0===e)break;else e--;else"$"!==d&&"$?"!==d&&"$!"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data="$";a._reactRetry&&a._reactRetry()}}</script><script>
let enc = new TextEncoder();
let srr_stream = (window.srr_stream = {});
srr_stream.push = () => {
  srr_stream._c.enqueue(enc.encode(document.currentScript.dataset.payload));
};
srr_stream.close = () => {
  srr_stream._c.close();
};
srr_stream.readable_stream = new ReadableStream({ start(c) { srr_stream._c = c; } });
</script>|}
  in
  let subscribed_elements = ref [] in
  let%lwt html, subscribe = ReactServerDOM.render_html ~skipRoot ~bootstrapModules ~bootstrapScriptContent element in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  let end_html = "</html>" in
  let remove_begin_and_end str =
    let diff = Str.replace_first (Str.regexp_string begin_html) "" str in
    let diff2 = Str.replace_first (Str.regexp_string end_html) "" diff in
    Str.replace_first (Str.regexp_string script_html) "" diff2
  in
  let diff = remove_begin_and_end html in
  assert_string diff shell;
  Lwt.return ()

let just_an_html_node () =
  let app = html [] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><script data-payload='0:[]\n\
       '>window.srr_stream.push()</script><script></script>"

let doctype () =
  let app = html [ head (); body () ] in
  assert_html app
    ~shell:
      (* "<!DOCTYPE html><html><head></head><body></body>" *)
      "<script data-payload='0:[[\"$\",\"head\",null,{},null,[],{}],[\"$\",\"body\",null,{\"children\":[]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script></script>"

let no_head_no_body_nothing_just_an_html_node () =
  let app = input () in
  assert_html app
    ~shell:
      "<input /><script data-payload='0:[\"$\",\"input\",null,{},null,[],{}]\n\
       '>window.srr_stream.push()</script><script></script>"

let html_with_a_node () =
  let app = html [ input () ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><input /><script data-payload='0:[[\"$\",\"input\",null,{},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script></script>"

let html_with_only_a_body () =
  let app = html [ lower "body" ~children:[ lower "div" ~children:[ React.string "Just body content" ] () ] () ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><body><div>Just body content</div><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[\"Just body \
       content\"]},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script></script></body>"

let html_with_no_srr_html_body () =
  let app = html [ lower "body" ~children:[ lower "div" ~children:[ React.string "Just body content" ] () ] () ] in
  assert_html app ~skipRoot:true
    ~shell:
      "<!DOCTYPE html><html><head></head><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[\"Just body \
       content\"]},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script></script>"

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
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><title>Titulaso</title><meta charset=\"utf-8\" /></head><script \
       data-payload='0:[[\"$\",\"head\",null,{\"children\":[[\"$\",\"title\",null,{\"children\":[\"Titulaso\"]},null,[],{}],[\"$\",\"meta\",null,{\"children\":[],\"charSet\":\"utf-8\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script></script>"

let html_inside_a_div () =
  let app = lower "div" ~children:[ html [] ] () in
  assert_html app
    ~shell:
      "<div><html></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"html\",null,{\"children\":[]},null,[],{}]]},null,[],{}]\n\
       '>window.srr_stream.push()</script><script></script>"

let html_inside_a_fragment () =
  let app = React.Fragment (React.list [ html [ lower "div" () ] ]) in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><div></div><script \
       data-payload='0:[[\"$\",\"html\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[]},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script></script>"

let html_with_head_like_elements_not_in_head () =
  let app =
    html
      [
        lower "meta" ~attributes:[ React.JSX.String ("charset", "charSet", "utf-8") ] ();
        lower "title" ~children:[ React.string "Implicit Head?" ] ();
      ]
  in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><meta charset=\"utf-8\" /><title>Implicit Head?</title></head><script \
       data-payload='0:[[\"$\",\"meta\",null,{\"children\":[],\"charSet\":\"utf-8\"},null,[],{}],[\"$\",\"title\",null,{\"children\":[\"Implicit \
       Head?\"]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script></script>"

let html_without_body_and_bootstrap_scripts () =
  let app = html [ lower "input" ~attributes:[ React.JSX.String ("id", "id", "sidebar-search-input") ] () ] in
  assert_html app ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
    ~shell:
      "<!DOCTYPE html><html><head></head><input id=\"sidebar-search-input\" /><script \
       data-payload='0:[[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\"},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script>console.log('hello')</script><script src=\"react\" async=\"\" \
       type=\"module\"></script><script src=\"react-dom\" async=\"\" type=\"module\"></script>"

let html_with_body_and_bootstrap_scripts () =
  let app =
    html
      [ body ~children:[ lower "input" ~attributes:[ React.JSX.String ("id", "id", "sidebar-search-input") ] () ] () ]
  in
  assert_html app ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
    ~shell:
      "<!DOCTYPE html><html><head></head><body><input id=\"sidebar-search-input\" /><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script>console.log('hello')</script><script src=\"react\" async=\"\" \
       type=\"module\"></script><script src=\"react-dom\" async=\"\" type=\"module\"></script></body>"

let input_and_bootstrap_scripts () =
  let app = lower "input" ~attributes:[ React.JSX.String ("id", "id", "sidebar-search-input") ] () in
  assert_html app ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
    ~shell:
      "<input id=\"sidebar-search-input\" /><script \
       data-payload='0:[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\"},null,[],{}]\n\
       '>window.srr_stream.push()</script><script>console.log('hello')</script><script src=\"react\" async=\"\" \
       type=\"module\"></script><script src=\"react-dom\" async=\"\" type=\"module\"></script>"

let title_populates_to_a_head () =
  let app =
    html [ body ~children:[ head ~children:[ lower "title" ~children:[ React.string "Hey Yah" ] () ] () ] () ]
  in
  assert_html app ~bootstrapModules:[ "jquery"; "jquery-mobile" ]
    ~shell:
      "<!DOCTYPE html><html><head><title>Hey Yah</title></head><body><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"head\",null,{\"children\":[\"$\",\"title\",null,{\"children\":[\"Hey \
       Yah\"]},null,[],{}]},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script></script><script src=\"jquery\" async=\"\" \
       type=\"module\"></script><script src=\"jquery-mobile\" async=\"\" type=\"module\"></script></body>"

let tests =
  [
    test "doctype" doctype;
    test "just_an_html_node" just_an_html_node;
    test "no_head_no_body_nothing_just_an_html_node" no_head_no_body_nothing_just_an_html_node;
    test "html_with_no_srr_html_body" html_with_no_srr_html_body;
    test "html_with_a_node" html_with_a_node;
    test "html_inside_a_div" html_inside_a_div;
    test "html_inside_a_fragment" html_inside_a_fragment;
    test "head_with_content" head_with_content;
    test "html_with_only_a_body" html_with_only_a_body;
    test "html_with_head_like_elements_not_in_head" html_with_head_like_elements_not_in_head;
    test "html_without_body_and_bootstrap_scripts" html_without_body_and_bootstrap_scripts;
    test "html_with_body_and_bootstrap_scripts" html_with_body_and_bootstrap_scripts;
    test "input_and_bootstrap_scripts" input_and_bootstrap_scripts;
    test "title_populates_to_a_head" title_populates_to_a_head;
  ]
