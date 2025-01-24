let yojson = Alcotest.testable Yojson.Safe.pretty_print ( = )
let check_json = Alcotest.check yojson "should be equal"
let assert_json left right = Alcotest.check yojson "should be equal" right left

let assert_list (type a) (ty : a Alcotest.testable) (left : a list) (right : a list) =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_list_of_strings (left : string list) (right : string list) =
  Alcotest.check (Alcotest.list Alcotest.string) "should be equal" right left

let test title fn =
  ( Printf.sprintf "ReactServerDOM.render_to_html / %s" title,
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

let assert_html (left : Html.element) (right : string) = assert_string (Html.to_string left) right

let text_encoder_script =
  "<script>\n\
   let enc = new TextEncoder();\n\
   let srr_stream = (window.srr_stream = {});\n\
   srr_stream.push = () => {\n\
  \  srr_stream._c.enqueue(enc.encode(document.currentScript.dataset.payload));\n\
   };\n\
   srr_stream.close = () => {\n\
  \  srr_stream._c.close();\n\
   };\n\
   srr_stream.readable_stream = new ReadableStream({ start(c) { srr_stream._c = c; } });\n\
  \        </script>"

let rc_function_script =
  "<script>function \
   $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
   f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
   e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}</script>"
  ^ text_encoder_script

let stream_close_script = "<script>window.srr_stream.close()</script>"

let assert_sync_payload app sync_body =
  match%lwt ReactServerDOM.render_to_html app with
  | Done { head; body; end_script } ->
      assert_html head text_encoder_script;
      assert_html body sync_body;
      assert_html end_script stream_close_script;
      Lwt.return ()
  | Async _ -> Lwt.return (Alcotest.fail "Async should not be returned by render_to_html")

let assert_html_list (elements : Html.element list) (expected : string list) =
  assert_list_of_strings (List.map Html.to_string elements) expected

let assert_async_payload element ~shell assertion_list =
  match%lwt ReactServerDOM.render_to_html element with
  | Done _ -> Lwt.return (Alcotest.fail "Sync should be returned by render_to_html")
  | Async { head; shell = outcome_shell; subscribe } ->
      assert_html head rc_function_script;
      assert_html outcome_shell shell;
      let subscribed_elements = ref [] in
      let%lwt () =
        subscribe (fun element ->
            subscribed_elements := !subscribed_elements @ [ element ];
            Lwt.return ())
      in
      assert_html_list subscribed_elements.contents assertion_list;
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
  assert_sync_payload app "<script data-payload='0:null\n'>window.srr_stream.push()</script>"

let upper_case_component () =
  let app =
    React.Upper_case_component
      (fun () ->
        React.createElement "div" []
          [
            React.createElement "section" [] [ React.createElement "article" [] [ React.string "Deep Server Content" ] ];
          ])
  in
  assert_sync_payload app
    "<div><section><article>Deep Server Content</article></section></div><script \
     data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"section\",null,{\"children\":[[\"$\",\"article\",null,{\"children\":[\"Deep \
     Server Content\"]}]]}]]}]\n\
     '>window.srr_stream.push()</script>"

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
  assert_sync_payload app
    "<div><section><article>Deep Server Content</article></section></div><script \
     data-payload='0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"section\",null,{\"children\":[[\"$\",\"article\",null,{\"children\":[\"Deep \
     Server Content\"]}]]}]]}]\n\
     '>window.srr_stream.push()</script>"

let suspense_without_promise () =
  let app () = loading_suspense ~children:(React.string "Resolved") () in
  assert_sync_payload (app ())
    "<!--$?-->Resolved<!--/$--><script \
     data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"Resolved\"}]\n\
     '>window.srr_stream.push()</script>"

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
  assert_async_payload (app ())
    ~shell:
      "<!--$?--><template id=\"B:1\"></template>Loading...<!--/$--><script \
       data-payload='0:[\"$\",\"$Sreact.suspense\",null,{\"fallback\":\"Loading...\",\"children\":\"$L1\"}]\n\
       '>window.srr_stream.push()</script>"
    [ "<div><section><article>Deep Server Content</article></section></div>"; stream_close_script ]

let client_with_promise_props () =
  let delayed_value ~ms value =
    let%lwt () = Lwt_unix.sleep (Int.to_float ms /. 100.0) in
    Lwt.return value
  in
  let app () =
    React.Upper_case_component
      (fun () ->
        React.List
          [|
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props =
                  [ ("promise", React.Promise (delayed_value ~ms:200 "||| Resolved |||", fun res -> `String res)) ];
                client = React.string "Client with Props";
                import_module = "./client-with-props.js";
                import_name = "ClientWithProps";
              };
          |])
  in
  assert_async_payload (app ())
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
    test "upper_case_component" upper_case_component;
    test "async_component_without_promise" async_component_without_promise;
    test "suspense_without_promise" suspense_without_promise;
    test "with_sleepy_promise" with_sleepy_promise;
    test "client_with_promise_props" client_with_promise_props;
  ]
