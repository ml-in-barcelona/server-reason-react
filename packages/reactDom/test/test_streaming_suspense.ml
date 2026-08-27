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
    test "suspense_with_promise_that_rejects_after_flush" suspense_with_promise_that_rejects_after_flush;
    test "suspense_rejects_after_flush_in_prod" suspense_rejects_after_flush_in_prod;
  ]
