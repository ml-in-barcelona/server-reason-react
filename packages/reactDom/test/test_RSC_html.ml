let yojson = Alcotest.testable Yojson.Safe.pretty_print ( = )
let check_json = Alcotest.check yojson "should be equal"
let assert_json left right = Alcotest.check yojson "should be equal" right left

let assert_list (type a) (ty : a Alcotest.testable) (left : a list) (right : a list) =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_list_of_strings (left : string list) (right : string list) =
  Alcotest.check (Alcotest.list Alcotest.string) "should be equal" right left

let test title fn =
  ( Printf.sprintf "ReactServerDOM.render_html / %s" title,
    [
      Alcotest_lwt.test_case "" `Quick (fun _switch () ->
          let start = Unix.gettimeofday () in
          let timeout =
            let%lwt () = Lwt_unix.sleep 3.0 in
            Alcotest.failf "Test '%s' timed out" title
          in
          let%lwt test_promise = Lwt.pick [ fn (); timeout ] in
          let epsilon = 0.001 in
          let duration = Unix.gettimeofday () -. start in
          if abs_float duration >= epsilon then
            Printf.printf "\027[1m\027[33m[WARNING]\027[0m Test '%s' took %.3f seconds\n" title duration
          else ();
          Lwt.return test_promise);
    ] )

let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let assert_stream (stream : string Lwt_stream.t) (expected : string list) =
  let%lwt content = Lwt_stream.to_list stream in
  if content = [] then Lwt.return @@ Alcotest.fail "stream should not be empty"
  else Lwt.return @@ assert_list_of_strings content expected

let stream_close_script = "<script>window.srr_stream.close()</script>"

let assert_html element ~shell assertion_list =
  let entire_html =
    Printf.sprintf
      "<!DOCTYPE html><html><head><meta charset=\"utf-8\" /><script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}</script><script>\n\
       let enc = new TextEncoder();\n\
       let srr_stream = (window.srr_stream = {});\n\
       srr_stream.push = () => {\n\
      \  srr_stream._c.enqueue(enc.encode(document.currentScript.dataset.payload));\n\
       };\n\
       srr_stream.close = () => {\n\
      \  srr_stream._c.close();\n\
       };\n\
       srr_stream.readable_stream = new ReadableStream({ start(c) { srr_stream._c = c; } });\n\
      \        </script></head>%s</html>"
      shell
  in
  let subscribed_elements = ref [] in
  let%lwt html, subscribe = ReactServerDOM.render_html element in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  assert_string entire_html html;
  assert_list_of_strings subscribed_elements.contents assertion_list;
  Lwt.return ()

let layout ~children () =
  React.Upper_case_component
    (fun () -> React.createElement "div" [] [ React.createElement "p" [] [ React.string "Awesome webpage"; children ] ])

let loading_suspense ~children () = React.Suspense.make ~fallback:(React.string "Loading...") ~children ()

(* ***** *)
(* Tests *)
(* ***** *)

let null_element () =
  let app = React.null in
  assert_html ~shell:"<script data-payload='0:null\n'>window.srr_stream.push()</script>" app [ stream_close_script ]

let element_with_dangerously_set_inner_html () =
  let app = React.createElement "div" [ React.JSX.DangerouslyInnerHtml "<h1>Hello</h1>" ] [] in
  assert_html
    ~shell:
      "<div><h1>Hello</h1></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[null],\"dangerouslySetInnerHTML\":{\"__html\":\"<h1>Hello</h1>\"}}]\n\
       '>window.srr_stream.push()</script>"
    app [ stream_close_script ]

let input_element_with_value () =
  let app = React.createElement "input" [ React.JSX.String ("value", "value", "application") ] [] in
  assert_html
    ~shell:
      "<input value=\"application\" /><script data-payload='0:[\"$\",\"input\",null,{\"value\":\"application\"}]\n\
       '>window.srr_stream.push()</script>"
    app [ stream_close_script ]

let upper_case_component () =
  let app =
    React.Upper_case_component
      (fun () ->
        React.createElement "div" []
          [
            React.createElement "section" [] [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
          ])
  in
  assert_html
    ~shell:
      "<div><section><article>Deep Server Content</article></section></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"section\",null,{\"children\":[[\"$\",\"article\",null,{\"children\":[\"Deep \
       Server Content\"]}]]}]]}]\n\
       '>window.srr_stream.push()</script>"
    app [ stream_close_script ]

let async_component_without_promise () =
  let app =
    React.Async_component
      (fun () ->
        Lwt.return
          (React.createElement "div" []
             [
               React.createElement "section" []
                 [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
             ]))
  in
  assert_html
    ~shell:
      "<div><section><article>Deep Server Content</article></section></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"section\",null,{\"children\":[[\"$\",\"article\",null,{\"children\":[\"Deep \
       Server Content\"]}]]}]]}]\n\
       '>window.srr_stream.push()</script>"
    app [ stream_close_script ]

let async_component_with_promise () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           (fun () ->
             let%lwt () = Lwt_unix.sleep 0.1 in
             Lwt.return (React.createElement "span" [] [ React.string "Sleep resolved" ])))
      ()
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<div hidden=\"true\" id=\"S:1\"><span>Sleep resolved</span></div>\n<script>$RC('B:1', 'S:1')</script>";
      "<script data-payload='1:[\"$\",\"span\",null,{\"children\":[\"Sleep resolved\"]}]\n\
       '>window.srr_stream.push()</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let async_component_and_client_component_with_suspense () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           (fun () ->
             let%lwt () = Lwt_unix.sleep 0.1 in
             Lwt.return
               (React.createElement "span" []
                  [
                    React.Client_component
                      {
                        props = [];
                        client = React.string "Only the client";
                        import_module = "./client-with-props.js";
                        import_name = "";
                      };
                    React.string "Part of async component";
                  ])))
      ()
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='2:I[\"./client-with-props.js\",[],\"\"]\n'>window.srr_stream.push()</script>";
      "<div hidden=\"true\" id=\"S:1\"><span>Only the client<!-- -->Part of async component</span></div>\n\
       <script>$RC('B:1', 'S:1')</script>";
      "<script data-payload='1:[\"$\",\"span\",null,{\"children\":[[\"$\",\"$2\",null,{}],\"Part of async component\"]}]\n\
       '>window.srr_stream.push()</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let suspense_without_promise () =
  let app () = loading_suspense ~children:(React.string "Resolved") () in
  assert_html
    ~shell:
      "<!--$?-->Resolved<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"Resolved\"}]\n\
       '>window.srr_stream.push()</script>"
    (app ()) [ stream_close_script ]

let with_sleepy_promise () =
  let app =
    loading_suspense
      ~children:
        (React.Async_component
           (fun () ->
             let%lwt () = Lwt_unix.sleep 0.1 in
             Lwt.return
               (React.createElement "div" []
                  [
                    React.createElement "section" []
                      [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
                  ])))
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<div hidden=\"true\" id=\"S:1\"><div><section><article>Deep Server Content</article></section></div></div>\n\
       <script>$RC('B:1', 'S:1')</script>";
      "<script \
       data-payload='1:[\"$\",\"div\",null,{\"children\":[[\"$\",\"section\",null,{\"children\":[[\"$\",\"article\",null,{\"children\":[\"Deep \
       Server Content\"]}]]}]]}]\n\
       '>window.srr_stream.push()</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let client_with_promise_props () =
  let delayed_value ~ms value =
    let%lwt () = Lwt_unix.sleep (Int.to_float ms /. 100.0) in
    Lwt.return value
  in
  let app () =
    React.Upper_case_component
      (fun () ->
        React.list
          [
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props =
                  [ ("promise", React.Promise (delayed_value ~ms:200 "||| Resolved |||", fun res -> `String res)) ];
                client = React.string "Client with Props";
                import_module = "./client-with-props.js";
                import_name = "ClientWithProps";
              };
          ])
  in
  assert_html (app ())
    ~shell:
      "<div>Server Content</div><!-- -->Client with Props<script \
       data-payload='0:[[\"$\",\"div\",null,{\"children\":[\"Server \
       Content\"]}],[\"$\",\"$2\",null,{\"promise\":\"$@1\"}]]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='1:\"||| Resolved |||\"\n'>window.srr_stream.push()</script>";
      stream_close_script;
    ]

let tests =
  [
    test "null_element" null_element;
    test "element_with_dangerously_set_inner_html" element_with_dangerously_set_inner_html;
    test "input_element_with_value" input_element_with_value;
    test "upper_case_component" upper_case_component;
    test "async_component_without_promise" async_component_without_promise;
    test "suspense_without_promise" suspense_without_promise;
    test "with_sleepy_promise" with_sleepy_promise;
    test "client_with_promise_props" client_with_promise_props;
    test "async_component_with_promise" async_component_with_promise;
    test "async_component_and_client_component_with_suspense" async_component_and_client_component_with_suspense;
  ]
