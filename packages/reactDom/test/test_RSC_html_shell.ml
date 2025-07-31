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

let lower tag ?(attributes = []) ?(children = []) () =
  React.Lower_case_element { key = None; tag; attributes; children }

let html children = lower "html" ~children ~attributes:[] ()
let head children = lower "head" ~children ()
let body children = lower "body" ~children ()
let input attributes = lower "input" ~attributes ()

let script ~async ~src () =
  lower "script" ~attributes:[ React.JSX.Bool ("async", "async", async); React.JSX.String ("src", "src", src) ] ()

let link ~rel ?precedence ~href () =
  lower "link"
    ~attributes:
      ([ React.JSX.String ("href", "href", href); React.JSX.String ("rel", "rel", rel) ]
      @
      match precedence with
      | Some precedence -> [ React.JSX.String ("precedence", "precedence", precedence) ]
      | None -> [])
    ()

let assert_html ?(skipRoot = false) ?(shell = "") ?bootstrapModules ?bootstrapScriptContent element =
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
  let%lwt html, subscribe = ReactServerDOM.render_html ~skipRoot ?bootstrapModules ?bootstrapScriptContent element in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  let remove_begin_and_end str = Str.replace_first (Str.regexp_string script_html) "" str in
  let diff = remove_begin_and_end html in
  assert_string diff shell;
  Lwt.return ()

let just_an_html_node () =
  let app = html [] in
  assert_html app
    ~shell:"<!DOCTYPE html><html><head></head><script data-payload='0:[]\n'>window.srr_stream.push()</script></html>"

let doctype () =
  let app = html [ head []; body [] ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><body></body><script \
       data-payload='0:[[\"$\",\"head\",null,{},null,[],{}],[\"$\",\"body\",null,{\"children\":[]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></html>"

let no_head_no_body_nothing_just_an_html_node () =
  let app = input [] in
  assert_html app
    ~shell:"<input /><script data-payload='0:[\"$\",\"input\",null,{},null,[],{}]\n'>window.srr_stream.push()</script>"

let html_with_a_node () =
  let app = html [ input [] ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><input /><script data-payload='0:[[\"$\",\"input\",null,{},null,[],{}]]\n\
       '>window.srr_stream.push()</script></html>"

let html_with_only_a_body () =
  let app = html [ lower "body" ~children:[ lower "div" ~children:[ React.string "Just body content" ] () ] () ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><body><div>Just body content</div><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[\"Just body \
       content\"]},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></body></html>"

let html_with_no_srr_html_body () =
  let app = html [ lower "body" ~children:[ lower "div" ~children:[ React.string "Just body content" ] () ] () ] in
  assert_html app ~skipRoot:true
    ~shell:
      "<!DOCTYPE html><html><head></head><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[\"Just body \
       content\"]},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></html>"

let head_with_content () =
  let app =
    html
      [
        head
          [
            lower "title" ~children:[ React.string "Titulaso" ] ();
            lower "meta" ~attributes:[ React.JSX.String ("charset", "charSet", "utf-8") ] ();
          ];
      ]
  in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><meta charset=\"utf-8\" /><title>Titulaso</title></head><script \
       data-payload='0:[[\"$\",\"head\",null,{\"children\":[[\"$\",\"title\",null,{\"children\":[\"Titulaso\"]},null,[],{}],[\"$\",\"meta\",null,{\"charSet\":\"utf-8\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></html>"

let html_inside_a_div () =
  let app = lower "div" ~children:[ html [] ] () in
  assert_html app
    ~shell:
      "<div><html></html></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"html\",null,{\"children\":[]},null,[],{}]]},null,[],{}]\n\
       '>window.srr_stream.push()</script>"

let html_inside_a_fragment () =
  let app = React.Fragment (React.list [ html [ lower "div" () ] ]) in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><div></div><script \
       data-payload='0:[[[\"$\",\"div\",null,{\"children\":[]},null,[],{}]]]\n\
       '>window.srr_stream.push()</script></html>"

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
      "<!DOCTYPE html><html><head><title>Implicit Head?</title><meta charset=\"utf-8\" /></head><script \
       data-payload='0:[[\"$\",\"meta\",null,{\"charSet\":\"utf-8\"},null,[],{}],[\"$\",\"title\",null,{\"children\":[\"Implicit \
       Head?\"]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></html>"

let html_without_body_and_bootstrap_scripts () =
  let app = html [ lower "input" ~attributes:[ React.JSX.String ("id", "id", "sidebar-search-input") ] () ] in
  assert_html app ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
    ~shell:
      "<!DOCTYPE html><html><head><link rel=\"modulepreload\" fetchPriority=\"low\" href=\"react-dom\" /><link \
       rel=\"modulepreload\" fetchPriority=\"low\" href=\"react\" /></head><input id=\"sidebar-search-input\" \
       /><script data-payload='0:[[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\"},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script>console.log('hello')</script><script src=\"react\" async=\"\" \
       type=\"module\"></script><script src=\"react-dom\" async=\"\" type=\"module\"></script></html>"

let html_with_body_and_bootstrap_scripts () =
  let app = html [ body [ lower "input" ~attributes:[ React.JSX.String ("id", "id", "sidebar-search-input") ] () ] ] in
  assert_html app ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
    ~shell:
      "<!DOCTYPE html><html><head><link rel=\"modulepreload\" fetchPriority=\"low\" href=\"react-dom\" /><link \
       rel=\"modulepreload\" fetchPriority=\"low\" href=\"react\" /></head><body><input id=\"sidebar-search-input\" \
       /><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script>console.log('hello')</script><script src=\"react\" async=\"\" \
       type=\"module\"></script><script src=\"react-dom\" async=\"\" type=\"module\"></script></body></html>"

let input_and_bootstrap_scripts () =
  let app = lower "input" ~attributes:[ React.JSX.String ("id", "id", "sidebar-search-input") ] () in
  assert_html app ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
    ~shell:
      "<input id=\"sidebar-search-input\" /><script \
       data-payload='0:[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\"},null,[],{}]\n\
       '>window.srr_stream.push()</script><script>console.log('hello')</script><script src=\"react\" async=\"\" \
       type=\"module\"></script><script src=\"react-dom\" async=\"\" type=\"module\"></script>"

let title_and_meta_populates_to_the_head () =
  let app =
    html
      [
        body
          [
            head
              [
                lower "title" ~children:[ React.string "Hey Yah" ] ();
                lower "meta"
                  ~attributes:
                    [
                      React.JSX.String ("name", "name", "viewport");
                      React.JSX.String ("content", "content", "width=device-width,initial-scale=1");
                    ]
                  ();
              ];
          ];
      ]
  in

  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\" /><title>Hey \
       Yah</title></head><body><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"head\",null,{\"children\":[[\"$\",\"title\",null,{\"children\":[\"Hey \
       Yah\"]},null,[],{}],[\"$\",\"meta\",null,{\"name\":\"viewport\",\"content\":\"width=device-width,initial-scale=1\"},null,[],{}]]},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></body></html>"

let async_scripts_to_head () =
  let app = html [ body [ script ~async:true ~src:"https://cdn.com/jquery.min.js" () ] ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><script async src=\"https://cdn.com/jquery.min.js\"></script></head><body><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></body></html>"

let async_scripts_gets_deduplicated () =
  let app =
    html
      [
        body
          [
            script ~async:true ~src:"https://cdn.com/jquery.min.js" ();
            script ~async:true ~src:"https://cdn.com/jquery.min.js" ();
            script ~async:true ~src:"https://cdn.com/jquery.min.js" ();
          ];
      ]
  in
  (* TODO: Deduplication only works on HTML currently, we don't know if we need the same logic for the model *)
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><script async src=\"https://cdn.com/jquery.min.js\"></script></head><body><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"},null,[],{}],[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"},null,[],{}],[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></body></html>"

let async_scripts_gets_deduplicated_2 () =
  let app =
    html
      [
        body
          [
            script ~async:true ~src:"https://cdn.com/jquery.min.js" ();
            script ~async:true ~src:"https://cdn.com/jquery.min.js" ();
            script ~async:false ~src:"https://cdn.com/jquery.min.js" ();
          ];
      ]
  in
  (* non_async scripts aren't hoisted *)
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><script async src=\"https://cdn.com/jquery.min.js\"></script></head><body><script \
       src=\"https://cdn.com/jquery.min.js\"></script><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"},null,[],{}],[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"},null,[],{}],[\"$\",\"script\",null,{\"children\":[],\"async\":false,\"src\":\"https://cdn.com/jquery.min.js\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></body></html>"

let link_with_rel_and_precedence () =
  let app =
    html
      [
        body
          [
            link ~rel:"stylesheet" ~precedence:"high" ~href:"https://cdn.com/main.css" ();
            link ~rel:"stylesheet" ~precedence:"low" ~href:"https://cdn.com/main.css" ();
          ];
      ]
  in
  (* TODO: Deduplication only works on HTML currently, we don't know if we need the same logic for the model *)
  (* Here the precedence "high" remains in the head because it's the first one, there's no update with the 2nd link *)
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><link href=\"https://cdn.com/main.css\" rel=\"stylesheet\" precedence=\"high\" \
       /></head><body><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"link\",null,{\"href\":\"https://cdn.com/main.css\",\"rel\":\"stylesheet\",\"precedence\":\"high\"},null,[],{}],[\"$\",\"link\",null,{\"href\":\"https://cdn.com/main.css\",\"rel\":\"stylesheet\",\"precedence\":\"low\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></body></html>"

let links_gets_pushed_to_the_head () =
  let app =
    html
      [
        body
          [
            link ~rel:"stylesheet" ~precedence:"low" ~href:"https://cdn.com/main.css" ();
            link ~rel:"icon" ~href:"favicon.ico" ();
            link ~rel:"icon" ~href:"favicon.ico" ();
            link ~rel:"pingback" ~href:"http://www.example.com/xmlrpc.php" ();
          ];
      ]
  in
  (* TODO: Deduplication only works on HTML currently, we don't know if we need the same logic for the model *)
  (* Links that aren't hoisted to the head are not deduplicated. Here favicon is duplicated *)
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><link href=\"https://cdn.com/main.css\" rel=\"stylesheet\" precedence=\"low\" \
       /><link href=\"http://www.example.com/xmlrpc.php\" rel=\"pingback\" /><link href=\"favicon.ico\" rel=\"icon\" \
       /><link href=\"favicon.ico\" rel=\"icon\" /></head><body><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"link\",null,{\"href\":\"https://cdn.com/main.css\",\"rel\":\"stylesheet\",\"precedence\":\"low\"},null,[],{}],[\"$\",\"link\",null,{\"href\":\"favicon.ico\",\"rel\":\"icon\"},null,[],{}],[\"$\",\"link\",null,{\"href\":\"favicon.ico\",\"rel\":\"icon\"},null,[],{}],[\"$\",\"link\",null,{\"href\":\"http://www.example.com/xmlrpc.php\",\"rel\":\"pingback\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></body></html>"

let no_async_scripts_to_remain () =
  let app = html [ body [ script ~async:false ~src:"https://cdn.com/jquery.min.js" () ] ] in
  assert_html app ~bootstrapModules:[ "jquery"; "jquery-mobile" ]
    ~shell:
      "<!DOCTYPE html><html><head><link rel=\"modulepreload\" fetchPriority=\"low\" href=\"jquery-mobile\" /><link \
       rel=\"modulepreload\" fetchPriority=\"low\" href=\"jquery\" /></head><body><script \
       src=\"https://cdn.com/jquery.min.js\"></script><script \
       data-payload='0:[[\"$\",\"body\",null,{\"children\":[[\"$\",\"script\",null,{\"children\":[],\"async\":false,\"src\":\"https://cdn.com/jquery.min.js\"},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script><script src=\"jquery\" async=\"\" type=\"module\"></script><script \
       src=\"jquery-mobile\" async=\"\" type=\"module\"></script></body></html>"

let self_closing_with_dangerously () =
  let app =
    React.createElement "div" []
      [
        React.createElement "input" [] [];
        (* When dangerouslySetInnerHtml is used, children gets ignored *)
        React.createElement "p" [ React.JSX.DangerouslyInnerHtml "unsafe!" ] [ React.string "xxx" ];
      ]
  in
  assert_html
    ~shell:
      "<div><input /><p>unsafe!</p></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"input\",null,{},null,[],{}],[\"$\",\"p\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"unsafe!\"}},null,[],{}]]},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    app

let self_closing_with_dangerously_in_head () =
  let app =
    React.createElement "html" []
      [
        React.createElement "head" []
          [
            React.createElement "meta" [ React.JSX.String ("char-set", "charSet", "utf-8") ] [];
            React.createElement "style" [ React.JSX.DangerouslyInnerHtml "* { display: none; }" ] [];
          ];
      ]
  in
  assert_html
    ~shell:
      "<!DOCTYPE html><html><head><meta char-set=\"utf-8\" /><style>* { display: none; }</style></head><script \
       data-payload='0:[[\"$\",\"head\",null,{\"children\":[[\"$\",\"meta\",null,{\"charSet\":\"utf-8\"},null,[],{}],[\"$\",\"style\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"* \
       { display: none; }\"}},null,[],{}]]},null,[],{}]]\n\
       '>window.srr_stream.push()</script></html>"
    app

(* let self_closing_with_dangerously_in_head_2 () =
  let app =
    React.createElement "head" []
      [
        React.createElement "meta" [ React.JSX.String ("char-set", "charSet", "utf-8") ] [];
        React.createElement "style" [ React.JSX.DangerouslyInnerHtml "* { display: none; }" ] [];
      ]
  in
  assert_html
    ~shell:
      "<head><meta char-set=\"utf-8\" /><style>* { display: none; }</style></head><script \
       data-payload='0:[\"$\",\"head\",null,{\"children\":[[\"$\",\"meta\",null,{\"charSet\":\"utf-8\"},null,[],{}],[\"$\",\"style\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"* \
       { display: none; }\"}},null,[],{}]]},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    app
 *)
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
    test "title_and_meta_populates_to_the_head" title_and_meta_populates_to_the_head;
    test "async_scripts_to_head" async_scripts_to_head;
    test "no_async_scripts_to_remain" no_async_scripts_to_remain;
    test "async_scripts_gets_deduplicated" async_scripts_gets_deduplicated;
    test "async_scripts_gets_deduplicated_2" async_scripts_gets_deduplicated_2;
    test "link_with_rel_and_precedence" link_with_rel_and_precedence;
    test "links_gets_pushed_to_the_head" links_gets_pushed_to_the_head;
    test "self_closing_with_dangerously" self_closing_with_dangerously;
    test "self_closing_with_dangerously_in_head" self_closing_with_dangerously_in_head;
  ]
