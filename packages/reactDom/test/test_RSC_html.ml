let yojson = Alcotest.testable Yojson.Safe.pretty_print ( = )
let check_json = Alcotest.check yojson "should be equal"
let assert_json left right = Alcotest.check yojson "should be equal" right left
let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let assert_list (ty : 'a Alcotest.testable) (left : 'a list) (right : 'a list) =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_list_of_strings (left : string list) (right : string list) =
  Alcotest.check (Alcotest.list Alcotest.string) "should be equal" right left

let assert_raises exn fn =
  match%lwt fn () with
  | exception exn -> Lwt.return (assert_string (Printexc.to_string exn) (Printexc.to_string exn))
  | _ -> Alcotest.failf "Expected exception %s" (Printexc.to_string exn)

let sleep ~ms =
  let%lwt () = Lwt_unix.sleep (Int.to_float ms /. 1000.0) in
  Lwt.return ()

let test title fn =
  ( Printf.sprintf "ReactServerDOM.render_html / %s" title,
    [
      Alcotest_lwt.test_case "" `Quick (fun _switch () ->
          let start = Unix.gettimeofday () in
          let timeout =
            let%lwt () = sleep ~ms:100 in
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

let assert_html element ?(disable_backtrace = false) ?debug ?(shell = "") assertion_list =
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
  if disable_backtrace then Printexc.record_backtrace false else ();
  let%lwt html, subscribe = ReactServerDOM.render_html ?debug element in
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
  assert_list_of_strings subscribed_elements.contents assertion_list;
  if disable_backtrace then Printexc.record_backtrace true else ();
  Lwt.return ()

let layout ~children () =
  React.Upper_case_component
    ( "layout",
      fun () -> React.createElement "div" [] [ React.createElement "p" [] [ React.string "Awesome webpage"; children ] ]
    )

let loading_suspense ~children () = React.Suspense.make ~fallback:(React.string "Loading...") ~children ()

(* ***** *)
(* Tests *)
(* ***** *)

let null_element () =
  let app = React.null in
  assert_html ~shell:"<script data-payload='0:null\n'>window.srr_stream.push()</script>" app
    [ "<script>window.srr_stream.close()</script>" ]

let element_with_dangerously_set_inner_html () =
  let app = React.createElement "div" [ React.JSX.DangerouslyInnerHtml "<h1>Hello</h1>" ] [] in
  assert_html
    ~shell:
      "<div><h1>Hello</h1></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[null],\"dangerouslySetInnerHTML\":{\"__html\":\"<h1>Hello</h1>\"}},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    app
    [ "<script>window.srr_stream.close()</script>" ]

(* let debug_adds_debug_info () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let value = "my friend" in
          React.Fragment
            (React.List
               [
                 React.createElement "input"
                   [
                     React.JSX.String ("id", "id", "sidebar-search-input");
                     React.JSX.String ("placeholder", "placeholder", "Search");
                     React.JSX.String ("value", "value", value);
                   ]
                   [];
                 React.Upper_case_component ("Hello", fun () -> React.createElement "h1" [] [ React.string "Hello :)" ]);
               ]) )
  in
  assert_html
    ~shell:"<input id=\"sidebar-search-input\" placeholder=\"Search\" value=\"my friend\" /><h1>Hello :)</h1>"
    app
    [
      "<script \
       data-payload='1:{\"name\":\"app\",\"env\":\"Server\",\"key\":null,\"owner\":null,\"stack\":[],\"props\":{}}\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='1:D\"$1\"\n'>window.srr_stream.push()</script>";
      "<script \
       data-payload='2:{\"name\":\"Hello\",\"env\":\"Server\",\"key\":null,\"owner\":null,\"stack\":[],\"props\":{}}\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='2:D\"$2\"\n'>window.srr_stream.push()</script>";
"<script>window.srr_stream.close()</script>";
    ] *)

let input_element_with_value () =
  let app = React.createElement "input" [ React.JSX.String ("value", "value", "application") ] [] in
  assert_html
    ~shell:
      "<input value=\"application\" /><script \
       data-payload='0:[\"$\",\"input\",null,{\"value\":\"application\"},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    app
    [ "<script>window.srr_stream.close()</script>" ]

let upper_case_component () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.createElement "div" []
            [
              React.createElement "section" []
                [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
            ] )
  in
  assert_html
    ~shell:
      "<div><section><article>Deep Server Content</article></section></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"section\",null,{\"children\":[[\"$\",\"article\",null,{\"children\":[\"Deep \
       Server Content\"]},null,[],{}]]},null,[],{}]]},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    app
    [ "<script>window.srr_stream.close()</script>" ]

let async_component_without_promise () =
  let app =
    React.Async_component
      ( __FUNCTION__,
        fun () ->
          Lwt.return
            (React.createElement "div" []
               [
                 React.createElement "section" []
                   [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
               ]) )
  in
  assert_html
    ~shell:
      "<div><section><article>Deep Server Content</article></section></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"section\",null,{\"children\":[[\"$\",\"article\",null,{\"children\":[\"Deep \
       Server Content\"]},null,[],{}]]},null,[],{}]]},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    app
    [ "<script>window.srr_stream.close()</script>" ]

let async_component_with_promise () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( __FUNCTION__,
             fun () ->
               let%lwt () = sleep ~ms:10 in
               Lwt.return (React.createElement "span" [] [ React.string "Sleep resolved" ]) ))
      ()
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<div hidden=\"true\" id=\"S:1\"><span>Sleep resolved</span></div>\n<script>$RC('B:1', 'S:1')</script>";
      "<script data-payload='1:[\"$\",\"span\",null,{\"children\":[\"Sleep resolved\"]},null,[],{}]\n\
       '>window.srr_stream.push()</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let suspenasync_and_client () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( __FUNCTION__,
             fun () ->
               let%lwt () = sleep ~ms:10 in
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
                    ]) ))
      ()
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='2:I[\"./client-with-props.js\",[],\"\"]\n'>window.srr_stream.push()</script>";
      "<div hidden=\"true\" id=\"S:1\"><span>Only the client<!-- -->Part of async component</span></div>\n\
       <script>$RC('B:1', 'S:1')</script>";
      "<script data-payload='1:[\"$\",\"span\",null,{\"children\":[[\"$\",\"$2\",null,{},null,[],{}],\"Part of async \
       component\"]},null,[],{}]\n\
       '>window.srr_stream.push()</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let suspense_without_promise () =
  let app () = loading_suspense ~children:(React.string "Resolved") () in
  assert_html
    ~shell:
      "<!--$-->Resolved<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"Resolved\"},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    (app ())
    [ "<script>window.srr_stream.close()</script>" ]

let with_sleepy_promise () =
  let app =
    loading_suspense
      ~children:
        (React.Async_component
           ( __FUNCTION__,
             fun () ->
               let%lwt () = sleep ~ms:10 in
               Lwt.return
                 (React.createElement "div" []
                    [
                      React.createElement "section" []
                        [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
                    ]) ))
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<div hidden=\"true\" id=\"S:1\"><div><section><article>Deep Server Content</article></section></div></div>\n\
       <script>$RC('B:1', 'S:1')</script>";
      "<script \
       data-payload='1:[\"$\",\"div\",null,{\"children\":[[\"$\",\"section\",null,{\"children\":[[\"$\",\"article\",null,{\"children\":[\"Deep \
       Server Content\"]},null,[],{}]]},null,[],{}]]},null,[],{}]\n\
       '>window.srr_stream.push()</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let client_with_promise_props () =
  let delayed_value ~ms value =
    let%lwt () = sleep ~ms in
    Lwt.return value
  in
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
  assert_html (app ())
    ~shell:
      "<div>Server Content</div><!-- -->Client with Props<script \
       data-payload='0:[[\"$\",\"div\",null,{\"children\":[\"Server \
       Content\"]},null,[],{}],[\"$\",\"$2\",null,{\"promise\":\"$@1\"},null,[],{}]]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='1:\"||| Resolved |||\"\n'>window.srr_stream.push()</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let client_with_element_props () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.Client_component
            {
              props =
                [
                  ( "element",
                    React.Element
                      (React.createElement "span" [] [ React.string "server-component-as-props-to-client-component" ])
                  );
                ];
              client = React.string "Client with elment prop";
              import_module = "./client-with-props.js";
              import_name = "ClientWithProps";
            } )
  in
  assert_html (app ())
    ~shell:
      "Client with elment prop<script \
       data-payload='0:[\"$\",\"$1\",null,{\"element\":[\"$\",\"span\",null,{\"children\":[\"server-component-as-props-to-client-component\"]},null,[],{}]},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n\
       '>window.srr_stream.push()</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let suspense_with_error () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:(React.Upper_case_component (__FUNCTION__, fun () -> raise (Failure "lol")))
      ()
  in
  let main = React.Upper_case_component ("app", app) in
  assert_html main ~disable_backtrace:true
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script>";
      "<div hidden=\"true\" id=\"S:1\"></div>\n<script>$RC('B:1', 'S:1')</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let suspense_with_error_in_async () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Loading...")
      ~children:(React.Async_component (__FUNCTION__, fun () -> Lwt.fail (Failure "lol")))
      ()
  in
  let main = React.Upper_case_component ("app", app) in
  assert_html main ~disable_backtrace:true
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script>";
      "<div hidden=\"true\" id=\"S:1\"></div>\n<script>$RC('B:1', 'S:1')</script>";
      "<script>window.srr_stream.close()</script>";
    ]

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
  assert_html main ~disable_backtrace:true
    ~shell:
      "<div><!--$?--><template id=\"B:1\"></template>Loading...<!--/$--></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}]]},null,[],{}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script>";
      "<div hidden=\"true\" id=\"S:1\"></div>\n<script>$RC('B:1', 'S:1')</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let error_without_suspense () =
  let app () = React.Upper_case_component (__FUNCTION__, fun () -> raise (Failure "lol")) in
  let main = React.Upper_case_component ("app", app) in
  assert_raises (Failure "lol") (fun () -> assert_html main ~disable_backtrace:true [])

let error_in_toplevel_in_async () =
  let app () = Lwt.fail (Failure "lol") in
  let main = React.Async_component ("app", app) in
  assert_raises (Failure "lol") (fun () -> assert_html main ~disable_backtrace:true [])

let await_tick ?(raise = false) num =
  React.Async_component
    ( "await_tick",
      fun () ->
        let%lwt () = sleep ~ms:(Random.int 10) in
        if raise then Lwt.fail (Failure "lol") else Lwt.return (React.string num) )

let suspense_in_a_list_with_error () =
  let fallback = React.string "Loading..." in
  let app () =
    React.Fragment
      (React.list
         [
           React.Suspense.make ~fallback ~children:(await_tick "A") ();
           React.Suspense.make ~fallback ~children:(await_tick ~raise:true "B") ();
           React.Suspense.make ~fallback ~children:(await_tick "C") ();
         ])
  in
  let main = React.Upper_case_component ("app", app) in
  assert_html main ~disable_backtrace:true
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><!--$?--><template \
       id=\"B:2\"></template>Loading...<!--/$--><!--$?--><template id=\"B:3\"></template>Loading...<!--/$--><script \
       data-payload='0:[[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L2\"},null,[],{}],[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L3\"},null,[],{}]]\n\
       '>window.srr_stream.push()</script>"
    [
      "<div hidden=\"true\" id=\"S:3\">C</div>\n<script>$RC('B:3', 'S:3')</script>";
      "<script data-payload='3:\"C\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script>";
      "<div hidden=\"true\" id=\"S:2\"></div>\n<script>$RC('B:2', 'S:2')</script>";
      "<div hidden=\"true\" id=\"S:1\">A</div>\n<script>$RC('B:1', 'S:1')</script>";
      "<script data-payload='1:\"A\"\n'>window.srr_stream.push()</script>";
      "<script>window.srr_stream.close()</script>";
    ]

let tests =
  [
    test "client_with_element_props" client_with_element_props;
    (* test "debug_adds_debug_info" debug_adds_debug_info; *)
    test "null_element" null_element;
    test "element_with_dangerously_set_inner_html" element_with_dangerously_set_inner_html;
    test "input_element_with_value" input_element_with_value;
    test "upper_case_component" upper_case_component;
    test "async_component_without_promise" async_component_without_promise;
    test "suspense_without_promise" suspense_without_promise;
    test "with_sleepy_promise" with_sleepy_promise;
    test "client_with_promise_props" client_with_promise_props;
    test "async_component_with_promise" async_component_with_promise;
    test "suspense_with_error" suspense_with_error;
    test "suspense_with_error_in_async" suspense_with_error_in_async;
    test "suspense_with_error_under_lowercase" suspense_with_error_under_lowercase;
    test "error_without_suspense" error_without_suspense;
    test "error_in_toplevel_in_async" error_in_toplevel_in_async;
    test "suspense_in_a_list_with_error" suspense_in_a_list_with_error;
  ]
