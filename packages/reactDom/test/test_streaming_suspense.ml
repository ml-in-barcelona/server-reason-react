open Test_renderToStream

let writer_with_async_suspense_in_stream () =
  let child () =
    mk_suspense ~fallback:(React.string "Loading")
      ~children:(deffered_component ~seconds:0. ~children:(React.string "Done") ())
      ()
  in
  let app =
    React.Writer
      {
        emit =
          (fun buf ~separators ->
            Buffer.add_string buf "<div>";
            let (_ : bool) = ReactDOM.write_element_to_buffer_internal buf ~separators ~prev_text:false (child ()) in
            Buffer.add_string buf "</div>");
        original = (fun () -> React.createElement "div" [] [ child () ]);
      }
  in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_stream stream
    [
      "<div><!--$?--><template id=\"B:0\"></template>Loading<!--/$--></div>";
      "<div hidden id=\"S:0\"><div>Sleep 0. seconds<!-- -->, <!-- -->Done</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let writer_with_suspending_component_in_stream () =
  let promise = Lwt.map (fun () -> "Done") (Lwt.pause ()) in
  let renders = ref 0 in
  let child () =
    mk_suspense ~fallback:(React.string "Loading")
      ~children:
        (React.Upper_case_component
           ( "reads_promise",
             fun () ->
               incr renders;
               React.createElement "span" [] [ React.string (React.Experimental.usePromise promise) ] ))
      ()
  in
  let app =
    React.Writer
      {
        emit =
          (fun buf ~separators ->
            Buffer.add_string buf "<div>";
            let (_ : bool) = ReactDOM.write_element_to_buffer_internal buf ~separators ~prev_text:false (child ()) in
            Buffer.add_string buf "</div>");
        original = (fun () -> React.createElement "div" [] [ child () ]);
      }
  in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  let%lwt () =
    assert_chunks stream
      [
        "<div><!--$?--><template id=\"B:0\"></template>Loading<!--/$--></div>";
        "<div hidden id=\"S:0\"><span>Done</span></div>";
        "<script>$RC('B:0','S:0')</script>";
      ]
  in
  Alcotest.(check int) "suspending child renders twice (suspend + resume), not during writer emit" 2 !renders;
  Lwt.return ()

let writer_with_throwing_suspense_in_stream () =
  let make_app renders =
    let child () =
      mk_suspense ~fallback:(React.string "Loading")
        ~children:
          (React.Upper_case_component
             ( "throws",
               fun () ->
                 incr renders;
                 raise (Failure "boom") ))
        ()
    in
    React.Writer
      {
        emit =
          (fun buf ~separators ->
            Buffer.add_string buf "<div>";
            let (_ : bool) = ReactDOM.write_element_to_buffer_internal buf ~separators ~prev_text:false (child ()) in
            Buffer.add_string buf "</div>");
        original = (fun () -> React.createElement "div" [] [ child () ]);
      }
  in
  let prod_renders = ref 0 in
  let%lwt stream, _abort = ReactDOM.renderToStream ~env:`Prod (make_app prod_renders) in
  let%lwt () = assert_chunks stream [ "<div><!--$!--><template></template>Loading<!--/$--></div>" ] in
  Alcotest.(check int) "throwing child renders once in prod" 1 !prod_renders;
  let previous = Printexc.backtrace_status () in
  Printexc.record_backtrace false;
  let dev_renders = ref 0 in
  let%lwt stream, _abort = ReactDOM.renderToStream ~env:`Dev (make_app dev_renders) in
  Printexc.record_backtrace previous;
  let%lwt () =
    assert_chunks stream
      [ "<div><!--$!--><template data-msg=\"Failure(&quot;boom&quot;)\n\"></template>Loading<!--/$--></div>" ]
  in
  Alcotest.(check int) "throwing child renders once in dev" 1 !dev_renders;
  Lwt.return ()

let writer_with_text_around_suspense_in_stream () =
  let suspense () = mk_suspense ~fallback:(React.string "Loading") ~children:(React.string "b") () in
  let app =
    React.Writer
      {
        emit =
          (fun buf ~separators ->
            Buffer.add_string buf "<div>";
            let prev = ReactDOM.write_element_to_buffer_internal buf ~separators ~prev_text:false (React.string "a") in
            let prev = ReactDOM.write_element_to_buffer_internal buf ~separators ~prev_text:prev (suspense ()) in
            let (_ : bool) =
              ReactDOM.write_element_to_buffer_internal buf ~separators ~prev_text:prev (React.string "c")
            in
            Buffer.add_string buf "</div>");
        original = (fun () -> React.createElement "div" [] [ React.string "a"; suspense (); React.string "c" ]);
      }
  in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_chunks stream [ "<div>a<!--$-->b<!--/$-->c</div>" ]

let render_to_string_inside_streaming_writer () =
  let inner_pending, _resolve_inner = Lwt.wait () in
  let render_inner () =
    let inner =
      mk_suspense ~fallback:(React.string "Inner")
        ~children:
          (React.Upper_case_component
             ("reads_inner", fun () -> React.string (React.Experimental.usePromise inner_pending)))
        ()
    in
    React.createElement "span" [] [ React.string (ReactDOM.renderToString inner) ]
  in
  let sync_only_writer =
    React.Writer
      {
        emit =
          (fun buf ~separators ->
            Buffer.add_string buf "<div>";
            let (_ : bool) =
              ReactDOM.write_element_to_buffer_internal buf ~separators ~prev_text:false
                (React.Upper_case_component ("calls_render_to_string", render_inner))
            in
            Buffer.add_string buf "</div>");
        original =
          (fun () ->
            React.createElement "div" [] [ React.Upper_case_component ("calls_render_to_string", render_inner) ]);
      }
  in
  let%lwt stream, _abort = ReactDOM.renderToStream sync_only_writer in
  let%lwt () = assert_chunks stream [ "<div><span>&lt;!--$!--&gt;Inner&lt;!--/$--&gt;</span></div>" ] in
  let outer_promise = Lwt.map (fun () -> "Done") (Lwt.pause ()) in
  let outer_suspense () =
    mk_suspense ~fallback:(React.string "Outer")
      ~children:
        (React.Upper_case_component
           ( "reads_outer",
             fun () -> React.createElement "p" [] [ React.string (React.Experimental.usePromise outer_promise) ] ))
      ()
  in
  let with_sibling_suspense =
    React.Writer
      {
        emit =
          (fun buf ~separators ->
            Buffer.add_string buf "<div>";
            let prev =
              ReactDOM.write_element_to_buffer_internal buf ~separators ~prev_text:false
                (React.Upper_case_component ("calls_render_to_string", render_inner))
            in
            let (_ : bool) =
              ReactDOM.write_element_to_buffer_internal buf ~separators ~prev_text:prev (outer_suspense ())
            in
            Buffer.add_string buf "</div>");
        original =
          (fun () ->
            React.createElement "div" []
              [ React.Upper_case_component ("calls_render_to_string", render_inner); outer_suspense () ]);
      }
  in
  let%lwt stream, _abort = ReactDOM.renderToStream with_sibling_suspense in
  assert_chunks stream
    [
      "<div><span>&lt;!--$!--&gt;Inner&lt;!--/$--&gt;</span><!--$?--><template \
       id=\"B:0\"></template>Outer<!--/$--></div>";
      "<div hidden id=\"S:0\"><p>Done</p></div>";
      "<script>$RC('B:0','S:0')</script>";
    ]

let late_failing_app () =
  mk_suspense ~fallback:(React.string "Loading")
    ~children:
      (React.Async_component
         ( "late_failing_async",
           fun () ->
             let%lwt () = Lwt_unix.sleep 0.005 in
             Lwt.fail (Failure "late failure") ))
    ()

let suspense_with_promise_that_rejects_after_flush () =
  let previous = Printexc.backtrace_status () in
  Printexc.record_backtrace false;
  let%lwt (first_chunk, remaining), async_exceptions =
    with_async_exception_hook (fun () ->
        let%lwt stream, _abort =
          ReactDOM.renderToStream ~env:`Dev (React.Upper_case_component ("app", late_failing_app))
        in
        let%lwt first_chunk = Lwt_stream.get stream in
        let%lwt remaining = Lwt_stream.to_list stream in
        Lwt.return (first_chunk, remaining))
  in
  Printexc.record_backtrace previous;
  (match first_chunk with
  | Some chunk -> assert_string chunk "<!--$?--><template id=\"B:0\"></template>Loading<!--/$-->"
  | None -> Alcotest.fail "Expected the shell chunk with the fallback");
  assert_list Alcotest.string remaining
    [
      "<script>$RX=function(b,c,d,e,f){var \
       a=document.getElementById(b);a&&(b=a.previousSibling,b.data=\"$!\",a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};;$RX(\"B:0\",\"\",\"Switched \
       to client rendering because the server rendering errored:\\n\\nFailure(\\\"late failure\\\")\")</script>";
    ];
  assert_list Alcotest.string async_exceptions [];
  Lwt.return ()

let suspense_rejects_after_flush_in_prod () =
  let%lwt stream, _abort = ReactDOM.renderToStream ~env:`Prod (React.Upper_case_component ("app", late_failing_app)) in
  let%lwt first_chunk = Lwt_stream.get stream in
  let%lwt remaining = Lwt_stream.to_list stream in
  (match first_chunk with
  | Some chunk -> assert_string chunk "<!--$?--><template id=\"B:0\"></template>Loading<!--/$-->"
  | None -> Alcotest.fail "Expected the shell chunk with the fallback");
  assert_list Alcotest.string remaining
    [
      "<script>$RX=function(b,c,d,e,f){var \
       a=document.getElementById(b);a&&(b=a.previousSibling,b.data=\"$!\",a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};;$RX(\"B:0\",\"\")</script>";
    ];
  Lwt.return ()

let tests =
  [
    test "writer_with_async_suspense_in_stream" writer_with_async_suspense_in_stream;
    test "writer_with_suspending_component_in_stream" writer_with_suspending_component_in_stream;
    test "writer_with_throwing_suspense_in_stream" writer_with_throwing_suspense_in_stream;
    test "writer_with_text_around_suspense_in_stream" writer_with_text_around_suspense_in_stream;
    test "render_to_string_inside_streaming_writer" render_to_string_inside_streaming_writer;
    test "suspense_with_promise_that_rejects_after_flush" suspense_with_promise_that_rejects_after_flush;
    test "suspense_rejects_after_flush_in_prod" suspense_rejects_after_flush_in_prod;
  ]
