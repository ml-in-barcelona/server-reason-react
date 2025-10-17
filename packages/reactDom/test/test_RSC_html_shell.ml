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

let html ?(attributes = []) children = React.createElement "html" attributes children
let head children = React.createElement "head" [] children
let body children = React.createElement "body" [] children
let input attributes = React.createElement "input" attributes []
let div attributes children = React.createElement "div" attributes children

let script ~async ~src () =
  React.createElement "script" [ React.JSX.Bool ("async", "async", async); React.JSX.String ("src", "src", src) ] []

let link ?precedence ~rel ~href () =
  React.createElement "link"
    ([ React.JSX.String ("href", "href", href); React.JSX.String ("rel", "rel", rel) ]
    @
    match precedence with
    | Some precedence -> [ React.JSX.String ("precedence", "precedence", precedence) ]
    | None -> [])
    []

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
    ~shell:
      "<!DOCTYPE html><html><head></head><script data-payload='0:[\"$\",\"html\",null,{\"children\":[]}]\n\
       '>window.srr_stream.push()</script></html>"

let doctype () =
  let app = html [ head []; body [] ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><body></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"head\",null,{\"children\":[]}],[\"$\",\"body\",null,{\"children\":[]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let no_head_no_body_nothing_just_an_html_node () =
  let app = input [] in
  assert_html app
    ~shell:"<input /><script data-payload='0:[\"$\",\"input\",null,{}]\n'>window.srr_stream.push()</script>"

let html_with_a_node () =
  let app = html [ input [] ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><input /><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"input\",null,{}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let html_with_only_a_body () =
  let app = html [ body [ div [] [ React.string "Just body content" ] ] ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><body><div>Just body content</div></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[\"Just \
       body content\"]}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let html_with_no_srr_html_body () =
  let app = html [ body [ div [] [ React.string "Just body content" ] ] ] in
  assert_html app ~skipRoot:true
    ~shell:
      "<!DOCTYPE html><html><head></head><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[\"Just \
       body content\"]}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let head_with_content () =
  let app =
    html
      [
        head
          [
            React.createElement "title" [] [ React.string "Titulaso" ];
            React.createElement "meta" [ React.JSX.String ("charset", "charSet", "utf-8") ] [];
          ];
      ]
  in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><title>Titulaso</title><meta charset=\"utf-8\" /></head><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"head\",null,{\"children\":[[\"$\",\"title\",null,{\"children\":[\"Titulaso\"]}],[\"$\",\"meta\",null,{\"charSet\":\"utf-8\"}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let html_inside_a_div () =
  let app = React.createElement "div" [] [ html [] ] in
  assert_html app
    ~shell:
      "<div><html></html></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"html\",null,{\"children\":[]}]]}]\n\
       '>window.srr_stream.push()</script>"

let html_inside_a_fragment () =
  let app = React.Fragment (React.list [ html [ React.createElement "div" [] [] ] ]) in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head></head><div></div><script \
       data-payload='0:[[\"$\",\"html\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[]}]]}]]\n\
       '>window.srr_stream.push()</script></html>"

let html_with_head_like_elements_not_in_head () =
  let app =
    html
      [
        React.createElement "meta" [ React.JSX.String ("charset", "charSet", "utf-8") ] [];
        React.createElement "title" [] [ React.string "Implicit Head?" ];
      ]
  in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><meta charset=\"utf-8\" /><title>Implicit Head?</title></head><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"meta\",null,{\"charSet\":\"utf-8\"}],[\"$\",\"title\",null,{\"children\":[\"Implicit \
       Head?\"]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let html_without_body_and_bootstrap_scripts () =
  let app = html [ React.createElement "input" [ React.JSX.String ("id", "id", "sidebar-search-input") ] [] ] in
  assert_html app ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
    ~shell:
      "<!DOCTYPE html><html><head><link rel=\"modulepreload\" fetchPriority=\"low\" href=\"react\" /><link \
       rel=\"modulepreload\" fetchPriority=\"low\" href=\"react-dom\" /></head><input id=\"sidebar-search-input\" \
       /><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\"}]]}]\n\
       '>window.srr_stream.push()</script><script>console.log('hello')</script><script src=\"react\" async=\"\" \
       type=\"module\"></script><script src=\"react-dom\" async=\"\" type=\"module\"></script></html>"

let html_with_body_and_bootstrap_scripts () =
  let app =
    html [ body [ React.createElement "input" [ React.JSX.String ("id", "id", "sidebar-search-input") ] [] ] ]
  in
  assert_html app ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
    ~shell:
      "<!DOCTYPE html><html><head><link rel=\"modulepreload\" fetchPriority=\"low\" href=\"react\" /><link \
       rel=\"modulepreload\" fetchPriority=\"low\" href=\"react-dom\" /></head><body><input \
       id=\"sidebar-search-input\" /></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\"}]]}]]}]\n\
       '>window.srr_stream.push()</script><script>console.log('hello')</script><script src=\"react\" async=\"\" \
       type=\"module\"></script><script src=\"react-dom\" async=\"\" type=\"module\"></script></html>"

let input_and_bootstrap_scripts () =
  let app = React.createElement "input" [ React.JSX.String ("id", "id", "sidebar-search-input") ] [] in
  assert_html app ~bootstrapModules:[ "react"; "react-dom" ] ~bootstrapScriptContent:"console.log('hello')"
    ~shell:
      "<input id=\"sidebar-search-input\" /><script \
       data-payload='0:[\"$\",\"input\",null,{\"id\":\"sidebar-search-input\"}]\n\
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
                React.createElement "title" [] [ React.string "Hey Yah" ];
                React.createElement "meta"
                  [
                    React.JSX.String ("name", "name", "viewport");
                    React.JSX.String ("content", "content", "width=device-width,initial-scale=1");
                  ]
                  [];
              ];
          ];
      ]
  in

  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><title>Hey Yah</title><meta name=\"viewport\" \
       content=\"width=device-width,initial-scale=1\" /></head><body></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"head\",null,{\"children\":[[\"$\",\"title\",null,{\"children\":[\"Hey \
       Yah\"]}],[\"$\",\"meta\",null,{\"name\":\"viewport\",\"content\":\"width=device-width,initial-scale=1\"}]]}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let async_scripts_to_head () =
  let app = html [ body [ script ~async:true ~src:"https://cdn.com/jquery.min.js" () ] ] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><script async \
       src=\"https://cdn.com/jquery.min.js\"></script></head><body></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

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
      "<!DOCTYPE html><html><head><script async \
       src=\"https://cdn.com/jquery.min.js\"></script></head><body></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"}],[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"}],[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/jquery.min.js\"}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let async_scripts_gets_deduplicated_2 () =
  let app =
    html
      [
        body
          [
            script ~async:true ~src:"https://cdn.com/duplicated.js" ();
            script ~async:true ~src:"https://cdn.com/duplicated.js" ();
            script ~async:false ~src:"https://cdn.com/non-async.js" ();
          ];
      ]
  in
  (* sync scripts aren't hoisted to the head *)
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><script async src=\"https://cdn.com/duplicated.js\"></script></head><body><script \
       src=\"https://cdn.com/non-async.js\"></script></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/duplicated.js\"}],[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"https://cdn.com/duplicated.js\"}],[\"$\",\"script\",null,{\"children\":[],\"async\":false,\"src\":\"https://cdn.com/non-async.js\"}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

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
  (* Here the precedence "high" remains in the head because it's the first one, there's no update with the 2nd link *)
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><link href=\"https://cdn.com/main.css\" rel=\"stylesheet\" precedence=\"high\" \
       /></head><body></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"link\",null,{\"href\":\"https://cdn.com/main.css\",\"rel\":\"stylesheet\",\"precedence\":\"high\"}],[\"$\",\"link\",null,{\"href\":\"https://cdn.com/main.css\",\"rel\":\"stylesheet\",\"precedence\":\"low\"}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

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
       /><link href=\"favicon.ico\" rel=\"icon\" /><link href=\"favicon.ico\" rel=\"icon\" /><link \
       href=\"http://www.example.com/xmlrpc.php\" rel=\"pingback\" /></head><body></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"link\",null,{\"href\":\"https://cdn.com/main.css\",\"rel\":\"stylesheet\",\"precedence\":\"low\"}],[\"$\",\"link\",null,{\"href\":\"favicon.ico\",\"rel\":\"icon\"}],[\"$\",\"link\",null,{\"href\":\"favicon.ico\",\"rel\":\"icon\"}],[\"$\",\"link\",null,{\"href\":\"http://www.example.com/xmlrpc.php\",\"rel\":\"pingback\"}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let no_async_scripts_to_remain () =
  let app = html [ body [ script ~async:false ~src:"https://cdn.com/jquery.min.js" () ] ] in
  assert_html app ~bootstrapModules:[ "jquery"; "jquery-mobile" ]
    ~shell:
      "<!DOCTYPE html><html><head><link rel=\"modulepreload\" fetchPriority=\"low\" href=\"jquery\" /><link \
       rel=\"modulepreload\" fetchPriority=\"low\" href=\"jquery-mobile\" /></head><body><script \
       src=\"https://cdn.com/jquery.min.js\"></script></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"script\",null,{\"children\":[],\"async\":false,\"src\":\"https://cdn.com/jquery.min.js\"}]]}]]}]\n\
       '>window.srr_stream.push()</script><script src=\"jquery\" async=\"\" type=\"module\"></script><script \
       src=\"jquery-mobile\" async=\"\" type=\"module\"></script></html>"

let self_closing_with_dangerously () =
  let app =
    div []
      [
        input [];
        (* When dangerouslySetInnerHtml is used, children gets ignored *)
        React.createElement "p" [ React.JSX.DangerouslyInnerHtml "unsafe!" ] [ React.string "xxx" ];
      ]
  in
  assert_html
    ~shell:
      "<div><input /><p>unsafe!</p></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"input\",null,{}],[\"$\",\"p\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"unsafe!\"}}]]}]\n\
       '>window.srr_stream.push()</script>"
    app

let self_closing_with_dangerously_in_head () =
  let app =
    html
      [
        head
          [
            React.createElement "meta" [ React.JSX.String ("char-set", "charSet", "utf-8") ] [];
            React.createElement "style" [ React.JSX.DangerouslyInnerHtml "* { display: none; }" ] [];
          ];
      ]
  in
  assert_html
    ~shell:
      "<!DOCTYPE html><html><head><meta char-set=\"utf-8\" /><style>* { display: none; }</style></head><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"head\",null,{\"children\":[[\"$\",\"meta\",null,{\"charSet\":\"utf-8\"}],[\"$\",\"style\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"* \
       { display: none; }\"}}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"
    app

let upper_case_component_with_resources () =
  let app () =
    html
      [
        head
          [
            React.createElement "link"
              [
                React.JSX.String ("rel", "rel", "stylesheet");
                React.JSX.String ("href", "href", "/styles.css");
                React.JSX.String ("precedence", "precedence", "default");
              ]
              [];
            React.createElement "script"
              [ React.JSX.String ("src", "src", "/app.js"); React.JSX.Bool ("async", "async", true) ]
              [];
          ];
        body [ div [] [ React.string "Page content" ] ];
      ]
  in
  assert_html
    (React.Upper_case_component ("Page", app))
    ~shell:
      "<!DOCTYPE html><html><head><link rel=\"stylesheet\" href=\"/styles.css\" precedence=\"default\" /><script \
       src=\"/app.js\" async></script></head><body><div>Page content</div></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"head\",null,{\"children\":[[\"$\",\"link\",null,{\"rel\":\"stylesheet\",\"href\":\"/styles.css\",\"precedence\":\"default\"}],[\"$\",\"script\",null,{\"children\":[],\"src\":\"/app.js\",\"async\":true}]]}],[\"$\",\"body\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[\"Page \
       content\"]}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let hoisted_elements_order_issue () =
  (* This test demonstrates the ordering issue with hoisted elements.
     When multiple elements are hoisted (title, meta, link, scripts),
     their order in the final HTML may not match the order they were defined *)
  let app =
    html
      [
        body
          [
            (* These elements will be hoisted to head but their order might not be preserved *)
            React.createElement "title" [] [ React.string "First Title" ];
            React.createElement "meta"
              [
                React.JSX.String ("name", "name", "description");
                React.JSX.String ("content", "content", "Page description");
              ]
              [];
            link ~rel:"stylesheet" ~href:"/first.css" ();
            React.createElement "title" [] [ React.string "Second Title" ];
            (* Will override first *)
            React.createElement "meta"
              [ React.JSX.String ("name", "name", "keywords"); React.JSX.String ("content", "content", "react, ssr") ]
              [];
            link ~rel:"stylesheet" ~href:"/second.css" ();
            script ~async:true ~src:"/first.js" ();
            link ~rel:"stylesheet" ~precedence:"high" ~href:"/third.css" ();
            (* This is a resource *)
            script ~async:true ~src:"/second.js" ();
            React.createElement "meta"
              [ React.JSX.String ("name", "name", "author"); React.JSX.String ("content", "content", "Developer") ]
              [];
            div [] [ React.string "Body content" ];
          ];
      ]
  in
  (* The expected order should maintain the order elements were defined:
     Resources (async scripts and links with precedence) followed by regular head elements *)
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><script async src=\"/first.js\"></script><link href=\"/third.css\" \
       rel=\"stylesheet\" precedence=\"high\" /><script async src=\"/second.js\"></script><title>First \
       Title</title><meta name=\"description\" content=\"Page description\" /><link href=\"/first.css\" \
       rel=\"stylesheet\" /><title>Second Title</title><meta name=\"keywords\" content=\"react, ssr\" /><link \
       href=\"/second.css\" rel=\"stylesheet\" /><meta name=\"author\" content=\"Developer\" /></head><body><div>Body \
       content</div></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"body\",null,{\"children\":[[\"$\",\"title\",null,{\"children\":[\"First \
       Title\"]}],[\"$\",\"meta\",null,{\"name\":\"description\",\"content\":\"Page \
       description\"}],[\"$\",\"link\",null,{\"href\":\"/first.css\",\"rel\":\"stylesheet\"}],[\"$\",\"title\",null,{\"children\":[\"Second \
       Title\"]}],[\"$\",\"meta\",null,{\"name\":\"keywords\",\"content\":\"react, \
       ssr\"}],[\"$\",\"link\",null,{\"href\":\"/second.css\",\"rel\":\"stylesheet\"}],[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"/first.js\"}],[\"$\",\"link\",null,{\"href\":\"/third.css\",\"rel\":\"stylesheet\",\"precedence\":\"high\"}],[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"/second.js\"}],[\"$\",\"meta\",null,{\"name\":\"author\",\"content\":\"Developer\"}],[\"$\",\"div\",null,{\"children\":[\"Body \
       content\"]}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let head_preserves_children_order () =
  (* Test that elements inside <head> maintain their original order *)
  let app =
    html
      [
        head
          [
            React.createElement "meta" [ React.JSX.String ("charset", "charSet", "utf-8") ] [];
            React.createElement "style" [ React.JSX.DangerouslyInnerHtml ".custom { color: red; }" ] [];
            link ~rel:"stylesheet" ~href:"/main.css" ();
            React.createElement "title" [] [ React.string "My App" ];
            React.createElement "meta"
              [
                React.JSX.String ("name", "name", "viewport");
                React.JSX.String ("content", "content", "width=device-width");
              ]
              [];
            script ~async:true ~src:"/app.js" ();
          ];
        body [ div [] [ React.string "Content" ] ];
      ]
  in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html><head><meta charset=\"utf-8\" /><style>.custom { color: red; }</style><link \
       href=\"/main.css\" rel=\"stylesheet\" /><title>My App</title><meta name=\"viewport\" \
       content=\"width=device-width\" /><script async \
       src=\"/app.js\"></script></head><body><div>Content</div></body><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[[\"$\",\"head\",null,{\"children\":[[\"$\",\"meta\",null,{\"charSet\":\"utf-8\"}],[\"$\",\"style\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\".custom \
       { color: red; \
       }\"}}],[\"$\",\"link\",null,{\"href\":\"/main.css\",\"rel\":\"stylesheet\"}],[\"$\",\"title\",null,{\"children\":[\"My \
       App\"]}],[\"$\",\"meta\",null,{\"name\":\"viewport\",\"content\":\"width=device-width\"}],[\"$\",\"script\",null,{\"children\":[],\"async\":true,\"src\":\"/app.js\"}]]}],[\"$\",\"body\",null,{\"children\":[[\"$\",\"div\",null,{\"children\":[\"Content\"]}]]}]]}]\n\
       '>window.srr_stream.push()</script></html>"

let html_attributes_are_preserved () =
  let app = html ~attributes:[ React.JSX.String ("lang", "lang", "en") ] [] in
  assert_html app
    ~shell:
      "<!DOCTYPE html><html lang=\"en\"><head></head><script \
       data-payload='0:[\"$\",\"html\",null,{\"children\":[],\"lang\":\"en\"}]\n\
       '>window.srr_stream.push()</script></html>"

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
    test "upper_case_component_with_resources" upper_case_component_with_resources;
    test "hoisted_elements_order_issue" hoisted_elements_order_issue;
    test "head_preserves_children_order" head_preserves_children_order;
    test "html_attributes_are_preserved" html_attributes_are_preserved;
  ]
