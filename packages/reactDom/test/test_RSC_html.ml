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

let test ?(timeout = 20) title fn =
  ( Printf.sprintf "ReactServerDOM.render_html / %s" title,
    [
      Alcotest_lwt.test_case "" `Quick (fun _switch () ->
          let start = Unix.gettimeofday () in
          let timeout =
            let%lwt () = sleep ~ms:timeout in
            Alcotest.failf "Test '%s' timed out" title
          in
          let%lwt test_promise = Lwt.pick [ fn (); timeout ] in
          let epsilon = 0.001 in
          let duration = Unix.gettimeofday () -. start in
          if abs_float duration >= epsilon then
            Printf.printf "  \027[1m\027[33m[WARNING]\027[0m Test '%s' took %.3f seconds\n" title duration
          else ();
          Lwt.return test_promise);
    ] )

let mk_suspense ?key ?fallback ?children () = React.Suspense.make ?key (React.Suspense.makeProps ?fallback ?children ())

let mk_context context ~value ~children () =
  React.Context.provider context (React.Context.makeProps ~value ~children ())

let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let assert_stream (stream : string Lwt_stream.t) (expected : string list) =
  let%lwt content = Lwt_stream.to_list stream in
  if content = [] then Lwt.return @@ Alcotest.fail "stream should not be empty"
  else Lwt.return @@ assert_list_of_strings content expected

let assert_html element ?(disable_backtrace = false) ?(env = `Dev) ?debug ?filter_stack_frame ?(shell = "")
    assertion_list =
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
  let prev = Printexc.backtrace_status () in
  if disable_backtrace then Printexc.record_backtrace false else ();
  let%lwt html, subscribe =
    ReactServerDOM.render_html ~progressive_chunk_size:1 ~env ?debug ?filter_stack_frame element
  in
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
  assert_list_of_strings subscribed_elements.contents (assertion_list @ [ "<script>window.srr_stream.close()</script>" ]);
  if disable_backtrace then Printexc.record_backtrace prev else ();
  Lwt.return ()

let layout ~children () =
  React.Upper_case_component
    ( "layout",
      fun () -> React.createElement "div" [] [ React.createElement "p" [] [ React.string "Awesome webpage"; children ] ]
    )

let loading_suspense ~children () = mk_suspense ~fallback:(React.string "Loading...") ~children ()

(* ***** *)
(* Tests *)
(* ***** *)

let null_element () =
  let app = React.null in
  assert_html ~shell:"<script data-payload='0:null\n'>window.srr_stream.push()</script>" app []

let element_with_dangerously_set_inner_html () =
  let app = React.createElement "div" [ React.JSX.DangerouslyInnerHtml "<h1>Hello</h1>" ] [] in
  assert_html
    ~shell:
      "<div><h1>Hello</h1></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"<h1>Hello</h1>\"}},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

let static_element () =
  let original = React.createElement "div" [] [ React.string "Hello" ] in
  let app () = React.Static { prerendered = "<div>Hello</div>"; original } in
  assert_html (app ())
    ~shell:
      "<div>Hello</div><script data-payload='0:[\"$\",\"div\",null,{\"children\":\"Hello\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    []

let suppress_hydration_warning_in_model () =
  let app =
    React.createElement "div"
      [ React.JSX.Bool ("suppressHydrationWarning", "suppressHydrationWarning", true) ]
      [ React.string "Hello" ]
  in
  assert_html
    ~shell:
      "<div>Hello</div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":\"Hello\",\"suppressHydrationWarning\":true},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

(* ~debug:true emits the same debug-info rows as render_model (see debug_* tests in test_RSC_model.ml): the first
   component attaches its debug rows to the root row; nested components are outlined into their own model row with a
   D ref, while their HTML stays inline in the shell. *)

let drop_all_frames _ _ = false

let debug_adds_debug_info () =
  let app = React.Upper_case_component ("App", fun () -> React.createElement "h1" [] [ React.string "title" ]) in
  assert_html ~debug:true ~filter_stack_frame:drop_all_frames
    ~shell:
      "<h1>title</h1><script data-payload='0:[\"$\",\"h1\",null,{\"children\":\"title\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app
    [
      "<script \
       data-payload='1:{\"name\":\"App\",\"env\":\"Server\",\"key\":null,\"owner\":null,\"stack\":[],\"props\":{}}\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='0:D\"$1\"\n'>window.srr_stream.push()</script>";
    ]

let debug_nested_owner_chain () =
  let app =
    React.Upper_case_component
      ( "App",
        fun () -> React.Upper_case_component ("Child", fun () -> React.createElement "div" [] [ React.string "hello" ])
      )
  in
  assert_html ~debug:true ~filter_stack_frame:drop_all_frames
    ~shell:"<div>hello</div><script data-payload='0:\"$2\"\n'>window.srr_stream.push()</script>"
    app
    [
      "<script \
       data-payload='1:{\"name\":\"App\",\"env\":\"Server\",\"key\":null,\"owner\":null,\"stack\":[],\"props\":{}}\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='0:D\"$1\"\n'>window.srr_stream.push()</script>";
      "<script \
       data-payload='3:{\"name\":\"Child\",\"env\":\"Server\",\"key\":null,\"owner\":\"$1\",\"stack\":[],\"props\":{}}\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='2:D\"$3\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:[\"$\",\"div\",null,{\"children\":\"hello\"},\"$1\",null,1]\n\
       '>window.srr_stream.push()</script>";
    ]

let debug_async_component_owner_chain () =
  let app =
    React.Upper_case_component
      ( "App",
        fun () ->
          React.Async_component
            ("AsyncChild", fun () -> Lwt.return (React.createElement "span" [] [ React.string "async" ])) )
  in
  assert_html ~debug:true ~filter_stack_frame:drop_all_frames
    ~shell:"<span>async</span><script data-payload='0:\"$2\"\n'>window.srr_stream.push()</script>"
    app
    [
      "<script \
       data-payload='1:{\"name\":\"App\",\"env\":\"Server\",\"key\":null,\"owner\":null,\"stack\":[],\"props\":{}}\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='0:D\"$1\"\n'>window.srr_stream.push()</script>";
      "<script \
       data-payload='3:{\"name\":\"AsyncChild\",\"env\":\"Server\",\"key\":null,\"owner\":\"$1\",\"stack\":[],\"props\":{}}\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='2:D\"$3\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:[\"$\",\"span\",null,{\"children\":\"async\"},\"$1\",null,1]\n\
       '>window.srr_stream.push()</script>";
    ]

let debug_not_emitted_without_flag () =
  let app = React.Upper_case_component ("App", fun () -> React.createElement "div" [] [ React.string "no debug" ]) in
  assert_html ~debug:false
    ~shell:
      "<div>no debug</div><script data-payload='0:[\"$\",\"div\",null,{\"children\":\"no debug\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

let input_element_with_value () =
  let app = React.createElement "input" [ React.JSX.String ("value", "value", "application") ] [] in
  assert_html
    ~shell:
      "<input value=\"application\" /><script \
       data-payload='0:[\"$\",\"input\",null,{\"value\":\"application\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

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
       data-payload='0:[\"$\",\"div\",null,{\"children\":[\"$\",\"section\",null,{\"children\":[\"$\",\"article\",null,{\"children\":\"Deep \
       Server Content\"},null,null,1]},null,null,1]},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

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
       data-payload='0:[\"$\",\"div\",null,{\"children\":[\"$\",\"section\",null,{\"children\":[\"$\",\"article\",null,{\"children\":\"Deep \
       Server Content\"},null,null,1]},null,null,1]},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

let async_component_with_promise () =
  let app () =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( __FUNCTION__,
             fun () ->
               let%lwt () = Lwt.pause () in
               Lwt.return (React.createElement "span" [] [ React.string "Sleep resolved" ]) ))
      ()
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:2\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"Loading...\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<div hidden id=\"S:2\"><span>Sleep resolved</span></div>\n\
       <script>$RC('B:2', 'S:2')</script><script data-payload='2:[\"$\",\"span\",null,{\"children\":\"Sleep \
       resolved\"},null,null,1]\n\
       '>window.srr_stream.push()</script>";
    ]

let suspenasync_and_client () =
  let app () =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( __FUNCTION__,
             fun () ->
               let%lwt () = Lwt.pause () in
               Lwt.return
                 (React.createElement "span" []
                    [
                      React.Client_component
                        {
                          key = None;
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
      "<!--$?--><template id=\"B:2\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"Loading...\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='3:I[\"./client-with-props.js\",[],\"\"]\n'>window.srr_stream.push()</script>";
      "<div hidden id=\"S:2\"><span>Only the client<!-- -->Part of async component</span></div>\n\
       <script>$RC('B:2', 'S:2')</script>";
      "<script data-payload='2:[\"$\",\"span\",null,{\"children\":[[\"$\",\"$L3\",null,{}],\"Part of async \
       component\"]}]\n\
       '>window.srr_stream.push()</script>";
    ]

let suspense_without_promise () =
  let app () = loading_suspense ~children:(React.string "Resolved") () in
  assert_html
    ~shell:
      "<!--$-->Resolved<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"Resolved\",\"fallback\":\"Loading...\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    (app ())
    [ "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>" ]

let with_sleepy_promise () =
  let app =
    loading_suspense
      ~children:
        (React.Async_component
           ( __FUNCTION__,
             fun () ->
               let%lwt () = Lwt.pause () in
               Lwt.return
                 (React.createElement "div" []
                    [
                      React.createElement "section" []
                        [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
                    ]) ))
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:2\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"Loading...\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<div hidden id=\"S:2\"><div><section><article>Deep Server Content</article></section></div></div>\n\
       <script>$RC('B:2', 'S:2')</script><script \
       data-payload='2:[\"$\",\"div\",null,{\"children\":[\"$\",\"section\",null,{\"children\":[\"$\",\"article\",null,{\"children\":\"Deep \
       Server Content\"},null,null,1]},null,null,1]},null,null,1]\n\
       '>window.srr_stream.push()</script>";
    ]

let client_with_promise_props () =
  let delayed_value value =
    let%lwt () = Lwt.pause () in
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
                  key = None;
                  props =
                    [
                      ( "promise",
                        React.Model.Promise (delayed_value "||| Resolved |||", fun res -> React.Model.Json (`String res))
                      );
                    ];
                  client = React.string "Client with Props";
                  import_module = "./client-with-props.js";
                  import_name = "ClientWithProps";
                };
            ] )
  in
  assert_html (app ())
    ~shell:
      "<div>Server Content</div>Client with Props<script data-payload='0:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"},null,null,1],[\"$\",\"$L2\",null,{\"promise\":\"$@1\"},null,null,1]]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='1:\"||| Resolved |||\"\n'>window.srr_stream.push()</script>";
    ]

let client_with_promise_failed_props () =
  let app () =
    let promise =
      React.Model.Promise
        ( (let%lwt () = Lwt.pause () in
           Lwt.fail (Failure "Already failed")),
          fun res -> React.Model.Json (`String res) )
    in
    React.Upper_case_component
      ( "app",
        fun () ->
          React.list
            [
              React.createElement "div" [] [ React.string "Server Content" ];
              React.Client_component
                {
                  key = None;
                  props = [ ("promise", promise) ];
                  client = React.string "Client with Props";
                  import_module = "./client-with-props.js";
                  import_name = "ClientWithProps";
                };
            ] )
  in
  assert_html (app ()) ~env:`Prod
    ~shell:
      "<div>Server Content</div>Client with Props<script data-payload='0:[[\"$\",\"div\",null,{\"children\":\"Server \
       Content\"}],[\"$\",\"$L2\",null,{\"promise\":\"$@1\"}]]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='1:E{\"digest\":\"\"}\n'>window.srr_stream.push()</script>";
    ]

let client_with_element_props () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.Client_component
            {
              key = None;
              props =
                [
                  ( "element",
                    React.Model.Element
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
       data-payload='0:[\"$\",\"$L1\",null,{\"element\":[\"$\",\"span\",null,{\"children\":\"server-component-as-props-to-client-component\"},null,null,1]},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n\
       '>window.srr_stream.push()</script>";
    ]

let client_component_with_async_component () =
  let children =
    React.Async_component
      ( __FUNCTION__,
        fun () ->
          let%lwt () = Lwt.pause () in
          Lwt.return (React.string "Async Component") )
  in
  let app ~children =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.Client_component
            {
              key = None;
              import_module = "./client.js";
              import_name = "Client";
              props = [ ("children", React.Model.Element children) ];
              client = children;
            } )
  in
  assert_html (app ~children)
    ~shell:
      "Async Component<script data-payload='0:[\"$\",\"$L2\",null,{\"children\":\"$L1\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"Async Component\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:I[\"./client.js\",[],\"Client\"]\n'>window.srr_stream.push()</script>";
    ]

let suspense_with_error () =
  let app () =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:(React.Upper_case_component (__FUNCTION__, fun () -> raise (Failure "lol")))
      ()
  in
  let main = React.Upper_case_component ("app", app) in
  assert_html main ~disable_backtrace:true
    ~shell:
      "<!--$?--><template id=\"B:2\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"Loading...\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script><div hidden id=\"S:2\"></div>\n\
       <script>$RC('B:2', 'S:2')</script>";
    ]

let suspense_with_error_in_async () =
  let app () =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:(React.Async_component (__FUNCTION__, fun () -> Lwt.fail (Failure "lol")))
      ()
  in
  let main = React.Upper_case_component ("app", app) in
  assert_html main ~disable_backtrace:true
    ~shell:
      "<!--$?--><template id=\"B:2\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"Loading...\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script><div hidden id=\"S:2\"></div>\n\
       <script>$RC('B:2', 'S:2')</script>";
    ]

let suspense_with_error_under_lowercase () =
  let app () =
    React.createElement "div" []
      [
        mk_suspense ~fallback:(React.string "Loading...")
          ~children:(React.Async_component (__FUNCTION__, fun () -> Lwt.fail (Failure "lol")))
          ();
      ]
  in
  let main = React.Upper_case_component ("app", app) in
  assert_html main ~disable_backtrace:true
    ~shell:
      "<div><!--$?--><template id=\"B:2\"></template>Loading...<!--/$--></div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"Loading...\"},null,null,1]},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script><div hidden id=\"S:2\"></div>\n\
       <script>$RC('B:2', 'S:2')</script>";
    ]

let error_without_suspense () =
  let app () = React.Upper_case_component (__FUNCTION__, fun () -> raise (Failure "lol")) in
  let main = React.Upper_case_component ("app", app) in
  assert_raises (Failure "lol") (fun () -> assert_html main ~disable_backtrace:true [])

let error_in_toplevel_in_async () =
  let app () = Lwt.fail (Failure "lol") in
  let main = React.Async_component ("app", app) in
  assert_raises (Failure "lol") (fun () -> assert_html main ~disable_backtrace:true [])

(* Errors inside a client tree (client_to_html): a Suspense boundary inside the client tree turns the error into a
   client-rendered boundary (<!--$!--> pre-flush, $RX post-flush); without one the render fails. *)

(* React's $RX instruction, vendored in Fizz_instructions.ml (a private module, hence the copy) *)
let rx_definition =
  {|$RX=function(b,c,d,e,f){var a=document.getElementById(b);a&&(b=a.previousSibling,b.data="$!",a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};|}

let mk_throwing_client_app ~children =
  let client = mk_suspense ~fallback:(React.string "Loading...") ~children () in
  React.Client_component { key = None; props = []; client; import_module = "./client.js"; import_name = "Client" }

let client_with_sync_error_under_client_suspense () =
  let app =
    mk_throwing_client_app ~children:(React.Upper_case_component ("throwing", fun () -> raise (Failure "boom")))
  in
  assert_html app ~disable_backtrace:true
    ~shell:
      "<!--$!--><template data-msg=\"Failure(&quot;boom&quot;)\n\
       \"></template>Loading...<!--/$--><script data-payload='0:[\"$\",\"$L1\",null,{},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [ "<script data-payload='1:I[\"./client.js\",[],\"Client\"]\n'>window.srr_stream.push()</script>" ]

let client_with_sync_error_under_client_suspense_in_prod () =
  let app =
    mk_throwing_client_app ~children:(React.Upper_case_component ("throwing", fun () -> raise (Failure "boom")))
  in
  (* Production must not leak the exception message or backtrace into the HTML: bare template, no data-msg *)
  assert_html app ~env:`Prod ~disable_backtrace:true
    ~shell:
      "<!--$!--><template></template>Loading...<!--/$--><script data-payload='0:[\"$\",\"$L1\",null,{}]\n\
       '>window.srr_stream.push()</script>"
    [ "<script data-payload='1:I[\"./client.js\",[],\"Client\"]\n'>window.srr_stream.push()</script>" ]

let client_with_async_error_under_client_suspense () =
  let failing =
    React.Async_component
      ( "failing",
        fun () ->
          let%lwt () = sleep ~ms:1 in
          Lwt.fail (Failure "boom") )
  in
  let app = mk_throwing_client_app ~children:failing in
  assert_html app ~disable_backtrace:true
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$L2\",null,{},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='2:I[\"./client.js\",[],\"Client\"]\n'>window.srr_stream.push()</script>";
      Printf.sprintf
        "<script>%s;$RX(\"B:1\",\"\",\"Switched to client rendering because the server rendering \
         errored:\\n\\nFailure(\\\"boom\\\")\")</script>"
        rx_definition;
    ]

let client_with_async_error_under_client_suspense_in_prod () =
  let failing =
    React.Async_component
      ( "failing",
        fun () ->
          let%lwt () = sleep ~ms:1 in
          Lwt.fail (Failure "boom") )
  in
  let app = mk_throwing_client_app ~children:failing in
  (* Production passes no message to $RX, only the digest slot *)
  assert_html app ~env:`Prod ~disable_backtrace:true
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script data-payload='0:[\"$\",\"$L2\",null,{}]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='2:I[\"./client.js\",[],\"Client\"]\n'>window.srr_stream.push()</script>";
      Printf.sprintf "<script>%s;$RX(\"B:1\",\"\")</script>" rx_definition;
    ]

let writer_subtree_with_client_component () =
  (* The PPX Writer fast path wraps lowercase markup whose children may include client components;
     its emit closure (ReactDOM.write_to_buffer) raises on them. The RSC HTML path must walk the
     original tree instead of using the prerendered emit. *)
  let counter =
    React.Client_component
      {
        key = None;
        props = [];
        client = React.string "Client Counter";
        import_module = "./counter.js";
        import_name = "Counter";
      }
  in
  let original = React.createElement "div" [] [ counter ] in
  let app =
    React.Writer
      {
        emit = (fun _ -> raise (Invalid_argument "emit must not be used when the subtree has a client component"));
        original = (fun () -> original);
      }
  in
  assert_html app
    ~shell:
      "<div>Client Counter</div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":[\"$\",\"$L1\",null,{},null,null,1]},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [ "<script data-payload='1:I[\"./counter.js\",[],\"Counter\"]\n'>window.srr_stream.push()</script>" ]

let client_with_error_without_suspense () =
  let client = React.Upper_case_component ("throwing", fun () -> raise (Failure "boom")) in
  let app =
    React.Client_component { key = None; props = []; client; import_module = "./client.js"; import_name = "Client" }
  in
  assert_raises (Failure "boom") (fun () -> assert_html app ~disable_backtrace:true [])

let client_with_error_under_server_suspense () =
  (* A server-side Suspense above the client component: the propagated error follows the server path, an E row
     rejecting the $L reference so the client error boundary takes over *)
  let client = React.Upper_case_component ("throwing", fun () -> raise (Failure "boom")) in
  let client_component =
    React.Client_component { key = None; props = []; client; import_module = "./client.js"; import_name = "Client" }
  in
  let app = mk_suspense ~fallback:(React.string "Loading...") ~children:client_component () in
  assert_html app ~disable_backtrace:true
    ~shell:
      "<!--$?--><template id=\"B:2\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"Loading...\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:E{\"message\":\"Failure(\\\"boom\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script><div hidden id=\"S:2\"></div>\n\
       <script>$RC('B:2', 'S:2')</script>";
    ]

let await_tick ?(raise = false) ?(ms = 1) num =
  React.Async_component
    ( "await_tick",
      fun () ->
        let%lwt () = sleep ~ms in
        if raise then Lwt.fail (Failure "lol") else Lwt.return (React.string num) )

let server_function_as_action () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.createElement "form"
            [
              React.JSX.Action
                ( "action",
                  "action",
                  { Runtime.id = "1234-4321"; call = (fun () -> Lwt.return (React.string "Server Content")) } );
            ]
            [ React.string "Server Content" ] )
  in
  let main = React.Upper_case_component ("app", app) in
  assert_html main ~disable_backtrace:true
    ~shell:
      "<form action=\"\" method=\"POST\"><input type=\"hidden\" name=\"$ACTION_ID_1234-4321\" value=\"\" />Server \
       Content</form><script data-payload='0:[\"$\",\"form\",null,{\"children\":\"Server \
       Content\",\"action\":\"$F1\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [ "<script data-payload='1:{\"id\":\"1234-4321\",\"bound\":null}\n'>window.srr_stream.push()</script>" ]

let suspense_in_a_list_with_error () =
  let fallback = React.string "Loading..." in
  let app () =
    React.Fragment
      (React.list
         [
           mk_suspense ~fallback ~children:(await_tick ~ms:1 "A") ();
           mk_suspense ~fallback ~children:(await_tick ~ms:2 ~raise:true "B") ();
           mk_suspense ~fallback ~children:(await_tick ~ms:3 "C") ();
         ])
  in
  let main = React.Upper_case_component ("app", app) in
  assert_html main ~disable_backtrace:true
    ~shell:
      "<!--$?--><template id=\"B:2\"></template>Loading...<!--/$--><!--$?--><template \
       id=\"B:3\"></template>Loading...<!--/$--><!--$?--><template id=\"B:4\"></template>Loading...<!--/$--><script \
       data-payload='0:[[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"Loading...\"},null,null,1],[\"$\",\"$1\",null,{\"children\":\"$L3\",\"fallback\":\"Loading...\"},null,null,1],[\"$\",\"$1\",null,{\"children\":\"$L4\",\"fallback\":\"Loading...\"},null,null,1]]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<div hidden id=\"S:2\">A</div>\n\
       <script>$RC('B:2', 'S:2')</script><script data-payload='2:\"A\"\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='3:E{\"message\":\"Failure(\\\"lol\\\")\",\"stack\":[],\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script>";
      "<div hidden id=\"S:4\">C</div>\n\
       <script>$RC('B:4', 'S:4')</script><script data-payload='4:\"C\"\n\
       '>window.srr_stream.push()</script>";
    ]

let page_with_duplicate_resources () =
  (* Test that duplicate resources are deduplicated *)
  let app () =
    React.Upper_case_component
      ( "Page",
        fun () ->
          React.list
            [
              React.createElement "html" []
                [
                  React.createElement "head" []
                    [
                      React.createElement "link"
                        [
                          React.JSX.String ("rel", "rel", "stylesheet");
                          React.JSX.String ("href", "href", "/styles.css");
                          React.JSX.String ("precedence", "precedence", "default");
                        ]
                        [];
                      React.createElement "link"
                        [
                          React.JSX.String ("rel", "rel", "stylesheet");
                          React.JSX.String ("href", "href", "/styles.css");
                          React.JSX.String ("precedence", "precedence", "default");
                        ]
                        [];
                    ];
                  React.createElement "body" [] [ React.createElement "div" [] [ React.string "Page content" ] ];
                ];
            ] )
  in
  assert_html (app ())
    ~shell:
      "<div>Page content</div><script data-payload='0:[\"$\",\"div\",null,{\"children\":\"Page content\"}]\n\
       '>window.srr_stream.push()</script>"
    []

let client_component_with_bootstrap_scripts () =
  (* Test bootstrap scripts are included in the rendered HTML *)
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.Client_component
            {
              key = None;
              props = [];
              client = React.string "Client Component";
              import_module = "./client.js";
              import_name = "Client";
            } )
  in
  let%lwt html, subscribe = ReactServerDOM.render_html ~bootstrapScripts:[ "/runtime.js"; "/app.js" ] (app ()) in
  let subscribed_elements = ref [] in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  (* Check that bootstrap scripts are included in the HTML *)
  let has_runtime_script = Str.string_match (Str.regexp ".*\\/runtime\\.js.*") html 0 in
  let has_app_script = Str.string_match (Str.regexp ".*\\/app\\.js.*") html 0 in
  assert_string (string_of_bool has_runtime_script) "true";
  assert_string (string_of_bool has_app_script) "true";
  Lwt.return ()

let client_component_with_bootstrap_modules () =
  (* Test bootstrap modules are included as module scripts *)
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.Client_component
            {
              key = None;
              props = [];
              client = React.string "Client Component";
              import_module = "./client.js";
              import_name = "Client";
            } )
  in
  let%lwt html, subscribe = ReactServerDOM.render_html ~bootstrapModules:[ "/runtime.mjs"; "/app.mjs" ] (app ()) in
  let subscribed_elements = ref [] in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  (* Check that bootstrap modules are included with type="module" *)
  let has_runtime_module = Str.string_match (Str.regexp ".*type=\"module\".*") html 0 in
  let has_module_script = Str.string_match (Str.regexp ".*\\/runtime\\.mjs.*") html 0 in
  assert_string (string_of_bool has_runtime_module) "true";
  assert_string (string_of_bool has_module_script) "true";
  Lwt.return ()

let nested_context () =
  let context = React.createContext React.null in
  let provider ~value ~children =
    React.Upper_case_component
      ( "provider",
        fun () ->
          React.Client_component
            {
              key = None;
              import_module = "./provider.js";
              import_name = "Provider";
              props = [ ("value", React.Model.Element value); ("children", React.Model.Element children) ];
              client = React.Upper_case_component ("provider", fun () -> mk_context context ~value ~children ());
            } )
  in
  let client =
    React.Upper_case_component
      ( "client",
        fun () ->
          let context = React.useContext context in
          context )
  in
  let consumer () =
    React.Client_component { key = None; import_module = "./consumer.js"; import_name = "Consumer"; props = []; client }
  in
  let about () =
    React.Upper_case_component
      ( "about",
        fun () ->
          provider ~value:(React.string "About page") ~children:(React.array [| React.string "/about"; consumer () |])
      )
  in
  let app () =
    React.Upper_case_component
      ("root", fun () -> provider ~value:(about ()) ~children:(React.array [| React.string "/root"; consumer () |]))
  in
  assert_html (app ())
    ~shell:
      "/root<!-- -->/about<!-- -->About page<script \
       data-payload='0:[\"$\",\"$L1\",null,{\"value\":[\"$\",\"$L1\",null,{\"value\":\"About \
       page\",\"children\":[\"/about\",[\"$\",\"$L2\",null,{},null,null,1]]},null,null,1],\"children\":[\"/root\",[\"$\",\"$L2\",null,{},null,null,1]]},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:I[\"./provider.js\",[],\"Provider\"]\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:I[\"./consumer.js\",[],\"Consumer\"]\n'>window.srr_stream.push()</script>";
    ]

let context_preserved_across_async_suspense () =
  let context = React.createContext "default" in
  let consumer () =
    React.Upper_case_component
      ( "consumer",
        fun () ->
          let value = React.useContext context in
          React.string value )
  in
  let app () =
    mk_context context ~value:"from-provider"
      ~children:
        (mk_suspense ~fallback:(React.string "loading")
           ~children:
             (React.Async_component
                ( "async",
                  fun () ->
                    let%lwt () = Lwt.pause () in
                    Lwt.return (consumer ()) ))
           ())
      ()
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:2\"></template>loading<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"loading\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<div hidden id=\"S:2\">from-provider</div>\n\
       <script>$RC('B:2', 'S:2')</script><script data-payload='2:\"from-provider\"\n\
       '>window.srr_stream.push()</script>";
    ]

let context_nested_providers_across_async_suspense () =
  let outer = React.createContext "outer-default" in
  let inner = React.createContext "inner-default" in
  let consumer () =
    React.Upper_case_component
      ( "consumer",
        fun () ->
          let o = React.useContext outer in
          let i = React.useContext inner in
          React.createElement "span" [] [ React.string (o ^ "+" ^ i) ] )
  in
  let app () =
    mk_context outer ~value:"outer-val"
      ~children:
        (mk_context inner ~value:"inner-val"
           ~children:
             (mk_suspense ~fallback:(React.string "loading")
                ~children:
                  (React.Async_component
                     ( "async",
                       fun () ->
                         let%lwt () = Lwt.pause () in
                         Lwt.return (consumer ()) ))
                ())
           ())
      ()
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:2\"></template>loading<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"loading\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<div hidden id=\"S:2\"><span>outer-val+inner-val</span></div>\n\
       <script>$RC('B:2', 'S:2')</script><script \
       data-payload='2:[\"$\",\"span\",null,{\"children\":\"outer-val+inner-val\"},null,null,1]\n\
       '>window.srr_stream.push()</script>";
    ]

let context_client_component_reads_context_across_async_suspense () =
  let context = React.createContext "default" in
  let client_consumer () =
    React.Client_component
      {
        key = None;
        import_module = "./consumer.js";
        import_name = "Consumer";
        props = [];
        client =
          React.Upper_case_component
            ( "consumer",
              fun () ->
                let value = React.useContext context in
                React.createElement "div" [] [ React.string value ] );
      }
  in
  let app () =
    mk_context context ~value:"ctx-value"
      ~children:
        (mk_suspense ~fallback:(React.string "loading")
           ~children:
             (React.Async_component
                ( "async",
                  fun () ->
                    let%lwt () = Lwt.pause () in
                    Lwt.return (client_consumer ()) ))
           ())
      ()
  in
  assert_html (app ())
    ~shell:
      "<!--$?--><template id=\"B:2\"></template>loading<!--/$--><script \
       data-payload='0:[\"$\",\"$1\",null,{\"children\":\"$L2\",\"fallback\":\"loading\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='3:I[\"./consumer.js\",[],\"Consumer\"]\n'>window.srr_stream.push()</script>";
      "<div hidden id=\"S:2\"><div>ctx-value</div></div>\n\
       <script>$RC('B:2', 'S:2')</script><script data-payload='2:[\"$\",\"$L3\",null,{},null,null,1]\n\
       '>window.srr_stream.push()</script>";
    ]

let suspense_with_sync_client_component () =
  let app () =
    React.Client_component
      {
        key = None;
        import_module = "./client.js";
        import_name = "Client";
        props = [];
        client =
          mk_suspense ~fallback:(React.string "Loading...")
            ~children:(React.createElement "div" [] [ React.string "Sync content" ])
            ();
      }
  in
  assert_html (app ())
    ~shell:
      "<!--$--><div>Sync content</div><!--/$--><script data-payload='0:[\"$\",\"$L1\",null,{},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    [ "<script data-payload='1:I[\"./client.js\",[],\"Client\"]\n'>window.srr_stream.push()</script>" ]

let text_with_ampersand () =
  let app = React.createElement "div" [] [ React.string "Tom & Jerry" ] in
  assert_html
    ~shell:
      "<div>Tom &amp; Jerry</div><script data-payload='0:[\"$\",\"div\",null,{\"children\":\"Tom &amp; \
       Jerry\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

let text_with_html_entity () =
  let app = React.createElement "div" [] [ React.string "Tom &amp; Jerry" ] in
  assert_html
    ~shell:
      "<div>Tom &amp;amp; Jerry</div><script data-payload='0:[\"$\",\"div\",null,{\"children\":\"Tom &amp;amp; \
       Jerry\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

let text_with_single_quote () =
  let app = React.createElement "div" [] [ React.string "it's" ] in
  assert_html
    ~shell:
      "<div>it&apos;s</div><script data-payload='0:[\"$\",\"div\",null,{\"children\":\"it&#x27;s\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

let text_with_script_tag () =
  let app = React.createElement "div" [] [ React.string "</script><script>alert('xss')</script>" ] in
  assert_html
    ~shell:
      "<div>&lt;/script&gt;&lt;script&gt;alert(&apos;xss&apos;)&lt;/script&gt;</div><script \
       data-payload='0:[\"$\",\"div\",null,{\"children\":\"</script><script>alert(&#x27;xss&#x27;)</script>\"},null,null,1]\n\
       '>window.srr_stream.push()</script>"
    app []

let timeout_closes_stream_for_hanging_suspense () =
  let never_resolves () =
    let promise, _resolver = Lwt.wait () in
    promise
  in
  let app =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( "NeverResolves",
             fun () ->
               let%lwt () = never_resolves () in
               Lwt.return (React.string "Should never appear") ))
      ()
  in
  let subscribed_elements = ref [] in
  let%lwt _html, subscribe = ReactServerDOM.render_html ~timeout:0.02 app in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  Alcotest.(check bool) "stream completed" true (List.length !subscribed_elements > 0);
  let all_content = String.concat "" !subscribed_elements in
  let end_script = "<script>window.srr_stream.close()</script>" in
  Alcotest.(check bool) "stream end script received" true (String.ends_with ~suffix:end_script all_content);
  Lwt.return ()

let timeout_does_not_affect_fast_renders () =
  let app =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( "FastComponent",
             fun () ->
               let%lwt () = Lwt.pause () in
               Lwt.return (React.string "Fast content") ))
      ()
  in
  let subscribed_elements = ref [] in
  let%lwt _html, subscribe = ReactServerDOM.render_html ~timeout:1.0 app in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  let all_content = String.concat "" !subscribed_elements in
  let end_script = "<script>window.srr_stream.close()</script>" in
  Alcotest.(check bool) "stream end script received" true (String.ends_with ~suffix:end_script all_content);
  let contains_div_hidden =
    try
      ignore (Str.search_forward (Str.regexp_string "<div hidden") all_content 0);
      true
    with Not_found -> false
  in
  Alcotest.(check bool) "async content was received" true contains_div_hidden;
  Lwt.return ()

let never_resolving_component name =
  React.Async_component
    ( name,
      fun () ->
        let promise, _resolver = Lwt.wait () in
        let%lwt () = promise in
        Lwt.return (React.string "Should never appear") )

let timeout_emits_client_render_instruction_per_pending_boundary () =
  let app =
    React.createElement "div" []
      [
        mk_suspense ~fallback:(React.string "Loading A") ~children:(never_resolving_component "NeverResolvesA") ();
        mk_suspense ~fallback:(React.string "Loading B") ~children:(never_resolving_component "NeverResolvesB") ();
      ]
  in
  let subscribed_elements = ref [] in
  let%lwt html, subscribe = ReactServerDOM.render_html ~env:`Dev ~progressive_chunk_size:1 ~timeout:0.02 app in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  let contains_substring str sub =
    match Str.search_forward (Str.regexp_string sub) str 0 with exception Not_found -> false | _ -> true
  in
  (* The shell contains both boundaries as pending fallbacks *)
  Alcotest.(check bool)
    "shell contains the first pending boundary" true
    (contains_substring html {|<!--$?--><template id="B:2"></template>Loading A<!--/$-->|});
  Alcotest.(check bool)
    "shell contains the second pending boundary" true
    (contains_substring html {|<!--$?--><template id="B:3"></template>Loading B<!--/$-->|});
  (* On timeout: an error row rejects each pending row of the RSC payload, the $RX definition is emitted once, one
     $RX call per pending boundary (with the error detail in dev), and the stream closes *)
  assert_list_of_strings !subscribed_elements
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:E{\"message\":\"The render timed \
       out.\",\"stack\":null,\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script><script data-payload='3:E{\"message\":\"The render timed \
       out.\",\"stack\":null,\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script><script>$RX=function(b,c,d,e,f){var \
       a=document.getElementById(b);a&&(b=a.previousSibling,b.data=\"$!\",a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};;$RX(\"B:2\",\"\",\"Switched \
       to client rendering because the server rendering aborted due to:\\n\\nThe render timed \
       out.\")</script><script>$RX(\"B:3\",\"\",\"Switched to client rendering because the server rendering aborted \
       due to:\\n\\nThe render timed out.\")</script><script>window.srr_stream.close()</script>";
    ];
  Lwt.return ()

let timeout_in_prod_emits_only_digest () =
  let app =
    mk_suspense ~fallback:(React.string "Loading...") ~children:(never_resolving_component "NeverResolves") ()
  in
  let subscribed_elements = ref [] in
  let%lwt _html, subscribe = ReactServerDOM.render_html ~env:`Prod ~progressive_chunk_size:1 ~timeout:0.02 app in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  (* In production only the digest is passed to the error row and $RX, no error detail *)
  assert_list_of_strings !subscribed_elements
    [
      "<script data-payload='1:\"$Sreact.suspense\"\n'>window.srr_stream.push()</script>";
      "<script data-payload='2:E{\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script><script>$RX=function(b,c,d,e,f){var \
       a=document.getElementById(b);a&&(b=a.previousSibling,b.data=\"$!\",a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};;$RX(\"B:2\",\"\")</script><script>window.srr_stream.close()</script>";
    ];
  Lwt.return ()

let timeout_rejects_pending_promise_prop_row () =
  (* A promise passed as a client component prop is an async row of the RSC payload with no Suspense boundary: on
     timeout it must be rejected with an error row (so the client-side $@ reference settles) without any $RX script
     (there is no boundary to flip). *)
  let never_resolves, _resolver = Lwt.wait () in
  let app =
    React.Client_component
      {
        key = None;
        props = [ ("promise", React.Model.Promise (never_resolves, fun res -> React.Model.Json (`String res))) ];
        client = React.string "Client with a pending promise";
        import_module = "./client-with-props.js";
        import_name = "ClientWithProps";
      }
  in
  let subscribed_elements = ref [] in
  let%lwt html, subscribe = ReactServerDOM.render_html ~env:`Dev ~progressive_chunk_size:1 ~timeout:0.02 app in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  let contains_substring str sub =
    match Str.search_forward (Str.regexp_string sub) str 0 with exception Not_found -> false | _ -> true
  in
  (* The shell references the pending promise row *)
  Alcotest.(check bool) "shell references the pending promise row" true (contains_substring html "$@");
  let all_content = String.concat "" !subscribed_elements in
  Alcotest.(check bool)
    "no $RX script is emitted without pending boundaries" false (contains_substring all_content "$RX");
  assert_list_of_strings !subscribed_elements
    [
      "<script data-payload='2:I[\"./client-with-props.js\",[],\"ClientWithProps\"]\n\
       '>window.srr_stream.push()</script>";
      "<script data-payload='1:E{\"message\":\"The render timed \
       out.\",\"stack\":null,\"env\":\"Server\",\"digest\":\"\"}\n\
       '>window.srr_stream.push()</script><script>window.srr_stream.close()</script>";
    ];
  Lwt.return ()

let timeout_with_late_resolving_boundary_does_not_crash () =
  let async_exceptions = ref [] in
  let previous_hook = !Lwt.async_exception_hook in
  (Lwt.async_exception_hook := fun exn -> async_exceptions := Printexc.to_string exn :: !async_exceptions);
  let app =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( "ResolvesAfterTimeout",
             fun () ->
               let%lwt () = Lwt_unix.sleep 0.05 in
               Lwt.return (React.string "Too late") ))
      ()
  in
  let subscribed_elements = ref [] in
  let%lwt _html, subscribe = ReactServerDOM.render_html ~progressive_chunk_size:1 ~timeout:0.01 app in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  (* Let the boundary resolve after the timeout: its completion must not push into the closed stream nor raise *)
  let%lwt () = Lwt_unix.sleep 0.06 in
  Lwt.async_exception_hook := previous_hook;
  assert_list_of_strings !async_exceptions [];
  let all_content = String.concat "" !subscribed_elements in
  let contains_substring str sub =
    match Str.search_forward (Str.regexp_string sub) str 0 with exception Not_found -> false | _ -> true
  in
  Alcotest.(check bool) "the pending boundary got a $RX call" true (contains_substring all_content {|$RX("B:2"|});
  Alcotest.(check bool)
    "content never reaches the stream after the timeout" false
    (contains_substring all_content "Too late");
  Alcotest.(check bool)
    "stream end script received" true
    (String.ends_with ~suffix:"<script>window.srr_stream.close()</script>" all_content);
  Lwt.return ()

let progressive_chunk_size_batches_small_chunks () =
  let app =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( "AsyncComponent",
             fun () ->
               let%lwt () = Lwt.pause () in
               Lwt.return (React.string "Async content") ))
      ()
  in
  let chunks_small = ref [] in
  let%lwt _html1, subscribe1 = ReactServerDOM.render_html ~progressive_chunk_size:1 app in
  let%lwt () =
    subscribe1 (fun element ->
        chunks_small := !chunks_small @ [ element ];
        Lwt.return ())
  in
  let chunks_large = ref [] in
  let%lwt _html2, subscribe2 = ReactServerDOM.render_html ~progressive_chunk_size:8192 app in
  let%lwt () =
    subscribe2 (fun element ->
        chunks_large := !chunks_large @ [ element ];
        Lwt.return ())
  in
  Alcotest.(check bool)
    "larger chunk size produces fewer or equal chunks" true
    (List.length !chunks_large <= List.length !chunks_small);
  let small_content = String.concat "" !chunks_small in
  let large_content = String.concat "" !chunks_large in
  Alcotest.(check string) "same content regardless of chunk size" small_content large_content;
  Lwt.return ()

let timeout_end_script_appears_exactly_once () =
  let app =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( "AlmostDone",
             fun () ->
               let%lwt () = Lwt.pause () in
               Lwt.return (React.string "Just in time") ))
      ()
  in
  let subscribed_elements = ref [] in
  let%lwt _html, subscribe = ReactServerDOM.render_html ~timeout:0.01 app in
  let%lwt () =
    subscribe (fun element ->
        subscribed_elements := !subscribed_elements @ [ element ];
        Lwt.return ())
  in
  let all_content = String.concat "" !subscribed_elements in
  let end_script = "<script>window.srr_stream.close()</script>" in
  let count_occurrences hay needle =
    let len = String.length needle in
    let rec aux acc start =
      match String.index_from_opt hay start needle.[0] with
      | None -> acc
      | Some i ->
          if i + len <= String.length hay && String.sub hay i len = needle then aux (acc + 1) (i + 1)
          else aux acc (i + 1)
    in
    if String.length hay = 0 || String.length needle = 0 then 0 else aux 0 0
  in
  let occurrences = count_occurrences all_content end_script in
  Alcotest.(check int) "end script appears exactly once" 1 occurrences;
  Lwt.return ()

let progressive_chunk_size_zero_does_not_raise () =
  let app = React.createElement "div" [] [ React.string "Hello" ] in
  let%lwt _html, subscribe = ReactServerDOM.render_html ~progressive_chunk_size:0 app in
  let%lwt () = subscribe (fun _element -> Lwt.return ()) in
  Lwt.return ()

let progressive_chunk_size_negative_does_not_raise () =
  let app = React.createElement "div" [] [ React.string "Hello" ] in
  let%lwt _html, subscribe = ReactServerDOM.render_html ~progressive_chunk_size:(-1) app in
  let%lwt () = subscribe (fun _element -> Lwt.return ()) in
  Lwt.return ()

let skip_root_omits_html_content () =
  let app = React.createElement "div" [] [ React.string "Should not appear" ] in
  let%lwt html, _subscribe = ReactServerDOM.render_html ~skipRoot:true app in
  let has_div = Str.string_match (Str.regexp ".*<div>.*") html 0 in
  Alcotest.(check bool) "should not contain div" false has_div;
  let has_script = Str.string_match (Str.regexp ".*<script.*") html 0 in
  Alcotest.(check bool) "should contain scripts" true has_script;
  Lwt.return ()

let tests =
  [
    test "debug_adds_debug_info" debug_adds_debug_info;
    test "debug_nested_owner_chain" debug_nested_owner_chain;
    test "debug_async_component_owner_chain" debug_async_component_owner_chain;
    test "debug_not_emitted_without_flag" debug_not_emitted_without_flag;
    test "suspense_with_sync_client_component" suspense_with_sync_client_component;
    test "text_with_ampersand" text_with_ampersand;
    test "text_with_html_entity" text_with_html_entity;
    test "text_with_single_quote" text_with_single_quote;
    test "text_with_script_tag" text_with_script_tag;
    test "client_with_element_props" client_with_element_props;
    test "null_element" null_element;
    test "element_with_dangerously_set_inner_html" element_with_dangerously_set_inner_html;
    test "static_element" static_element;
    test "suppress_hydration_warning_in_model" suppress_hydration_warning_in_model;
    test "input_element_with_value" input_element_with_value;
    test "upper_case_component" upper_case_component;
    test "async_component_without_promise" async_component_without_promise;
    test "suspense_without_promise" suspense_without_promise;
    test "with_sleepy_promise" with_sleepy_promise;
    test "client_with_promise_props" client_with_promise_props;
    test "client_with_promise_failed_props" client_with_promise_failed_props;
    test "client_component_with_async_component" client_component_with_async_component;
    test "async_component_with_promise" async_component_with_promise;
    test "suspense_with_error" suspense_with_error;
    test "suspense_with_error_in_async" suspense_with_error_in_async;
    test "suspense_with_error_under_lowercase" suspense_with_error_under_lowercase;
    test "error_without_suspense" error_without_suspense;
    test "client_with_sync_error_under_client_suspense" client_with_sync_error_under_client_suspense;
    test "client_with_sync_error_under_client_suspense_in_prod" client_with_sync_error_under_client_suspense_in_prod;
    test "client_with_async_error_under_client_suspense" client_with_async_error_under_client_suspense;
    test "client_with_async_error_under_client_suspense_in_prod" client_with_async_error_under_client_suspense_in_prod;
    test "writer_subtree_with_client_component" writer_subtree_with_client_component;
    test "client_with_error_without_suspense" client_with_error_without_suspense;
    test "client_with_error_under_server_suspense" client_with_error_under_server_suspense;
    test "error_in_toplevel_in_async" error_in_toplevel_in_async;
    test "suspense_in_a_list_with_error" suspense_in_a_list_with_error;
    test "server_function_as_action" server_function_as_action;
    test "nested_context" nested_context;
    test "context_preserved_across_async_suspense" context_preserved_across_async_suspense;
    test "context_nested_providers_across_async_suspense" context_nested_providers_across_async_suspense;
    test "context_client_component_reads_context_across_async_suspense"
      context_client_component_reads_context_across_async_suspense;
    test ~timeout:500 "timeout_closes_stream_for_hanging_suspense" timeout_closes_stream_for_hanging_suspense;
    test ~timeout:500 "timeout_emits_client_render_instruction_per_pending_boundary"
      timeout_emits_client_render_instruction_per_pending_boundary;
    test ~timeout:500 "timeout_in_prod_emits_only_digest" timeout_in_prod_emits_only_digest;
    test ~timeout:500 "timeout_rejects_pending_promise_prop_row" timeout_rejects_pending_promise_prop_row;
    test ~timeout:500 "timeout_with_late_resolving_boundary_does_not_crash"
      timeout_with_late_resolving_boundary_does_not_crash;
    test ~timeout:500 "timeout_does_not_affect_fast_renders" timeout_does_not_affect_fast_renders;
    test ~timeout:500 "progressive_chunk_size_batches_small_chunks" progressive_chunk_size_batches_small_chunks;
    test ~timeout:500 "timeout_end_script_appears_exactly_once" timeout_end_script_appears_exactly_once;
    test "progressive_chunk_size_zero_does_not_raise" progressive_chunk_size_zero_does_not_raise;
    test "progressive_chunk_size_negative_does_not_raise" progressive_chunk_size_negative_does_not_raise;
    test "skip_root_omits_html_content" skip_root_omits_html_content;
  ]
