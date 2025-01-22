let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left
let assert_list ty left right = Alcotest.check (Alcotest.list ty) "should be equal" right left

let test title fn =
  ( Printf.sprintf "ReactDOM.renderToStream / %s" title,
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

let assert_stream (stream : string Lwt_stream.t) expected =
  let%lwt content = Lwt_stream.to_list stream in
  if content = [] then Lwt.return (Alcotest.fail "stream should not be empty")
  else Lwt.return (assert_list Alcotest.string content expected)

module Sleep = struct
  let cached = ref false
  let destroy () = cached := false

  let delay v =
    if cached.contents then Lwt.return v
    else (
      cached.contents <- true;
      let%lwt () = Lwt_unix.sleep v in
      Lwt.return v)
end

let deffered_component ~seconds ~children () =
  React.Async_component
    (fun () ->
      let%lwt () = Lwt_unix.sleep seconds in
      Lwt.return
        (React.createElement "div" []
           [ React.string ("Sleep " ^ Float.to_string seconds ^ " seconds"); React.string ", "; children ]))

let test_silly_stream () =
  let stream, push = Lwt_stream.create () in
  push (Some "first");
  push (Some "secondo");
  push (Some "trienio");
  push None;
  assert_stream stream [ "first"; "secondo"; "trienio" ]

let react_use_without_suspense () =
  Sleep.destroy ();
  let app =
    React.Upper_case_component
      (fun () ->
        let delay = React.Experimental.use (Sleep.delay 0.01) in
        React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello "; React.float delay ] ])
  in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_stream stream [ "<div><span>Hello <!-- -->0.01</span></div>" ]

let suspense_without_promise () =
  let hi =
    React.Upper_case_component
      (fun () -> React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello" ] ])
  in
  let app () = React.Suspense.make ~fallback:(React.string "Loading...") ~children:hi () in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream [ "<div><span>Hello</span></div>" ]

let assert_raises exn fn =
  match%lwt fn () with
  | exception exn -> Lwt.return (assert_string (Printexc.to_string exn) (Printexc.to_string exn))
  | _ -> Alcotest.failf "Expected exception %s" (Printexc.to_string exn)

let always_throwing_component () = React.Upper_case_component (fun () -> raise (Failure "always throwing"))

let uppercase_component_always_throwing () =
  let app () = always_throwing_component () in
  assert_raises (Failure "always throwing") (fun () -> ReactDOM.renderToStream (React.Upper_case_component app))

let suspense_with_always_throwing () =
  (* This test is very fragile since it relies on the stack trace being the same (so line numbers and methods should match).
     We disable backtracing to avoid having to match the backtrace *)
  Printexc.record_backtrace false;
  let app () = React.Suspense.make ~fallback:(React.string "Loading...") ~children:(always_throwing_component ()) () in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  (* and we need to enable it back for the next test *)
  Printexc.record_backtrace true;
  assert_stream stream
    [ "<!--$!--><template data-msg=\"Failure(&quot;always throwing&quot;)\n\"></template>Loading...<!--/$-->" ]

let suspense_with_react_use () =
  Sleep.destroy ();
  let time =
    React.Upper_case_component
      (fun () ->
        let delay = React.Experimental.use (Sleep.delay 0.05) in
        React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello "; React.float delay ] ])
  in
  let app () = React.Suspense.make ~fallback:(React.string "Loading...") ~children:time () in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>Loading...<!--/$-->";
      "<div hidden id=\"S:0\"><div><span>Hello <!-- -->0.05</span></div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let test_with_custom_component () =
  let custom_component =
    React.Upper_case_component
      (fun () -> React.createElement "div" [] [ React.createElement "span" [] [ React.string "Custom Component" ] ])
  in
  let app () = React.createElement "div" [] [ custom_component ] in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream [ "<div><div><span>Custom Component</span></div></div>" ]

let test_with_multiple_custom_components () =
  let custom_component =
    React.Upper_case_component
      (fun () -> React.createElement "div" [] [ React.createElement "span" [] [ React.string "Custom Component" ] ])
  in
  let app () = React.createElement "div" [] [ custom_component; custom_component ] in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream [ "<div><div><span>Custom Component</span></div><div><span>Custom Component</span></div></div>" ]

let async_component () =
  let app () = React.Async_component (fun () -> Lwt.return (React.createElement "span" [] [ React.string "yow" ])) in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream [ "<span>yow</span>" ]

let suspense_with_async_component () =
  let app () =
    React.createElement "div" []
      [
        React.Suspense.make ~fallback:(React.string "Fallback 1")
          ~children:(deffered_component ~seconds:0.02 ~children:(React.string "lol") ())
          ();
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream
    [
      "<div><!--$?--><template id=\"B:0\"></template>Fallback 1<!--/$--></div>";
      "<div hidden id=\"S:0\"><div>Sleep 0.02 seconds<!-- -->, <!-- -->lol</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let suspense_with_nested_suspense () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Fallback 1")
      ~children:
        (deffered_component ~seconds:0.02
           ~children:
             (React.Suspense.make ~fallback:(React.string "Fallback 2")
                ~children:(deffered_component ~seconds:0.02 ~children:(React.string "lol") ())
                ())
           ())
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>Fallback 1<!--/$-->";
      "<div hidden id=\"S:0\"><div>Sleep 0.02 seconds<!-- -->, <!--$?--><template id=\"B:1\"></template>Fallback \
       2<!--/$--></div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
      "<div hidden id=\"S:1\"><div>Sleep 0.02 seconds<!-- -->, <!-- -->lol</div></div>";
      "<script>$RC('B:1','S:1')</script>";
    ]

let suspense_with_nested_suspense_with_error () =
  let app () =
    React.Suspense.make ~fallback:(React.string "Fallback 1")
      ~children:
        (deffered_component ~seconds:0.02
           ~children:
             (let _ = Printexc.record_backtrace false in
              React.Suspense.make ~fallback:(React.string "Fallback 2") ~children:(always_throwing_component ()) ())
           ())
      ()
  in
  Printexc.record_backtrace true;
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>Fallback 1<!--/$-->";
      "<div hidden id=\"S:0\"><div>Sleep 0.02 seconds<!-- -->, <!--$!--><template data-msg=\"Failure(&quot;always \
       throwing&quot;)\n\
       \"></template>Fallback 2<!--/$--></div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let async_component_without_suspense () =
  let app () = React.createElement "main" [] [ deffered_component ~seconds:0.02 ~children:(React.string "lol") () ] in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream [ "<main><div>Sleep 0.02 seconds<!-- -->, <!-- -->lol</div></main>" ]

let render_inner_html () =
  let globalStyles = "* { color: red; }" in
  let style =
    React.createElement "style"
      (Stdlib.List.filter_map Fun.id
         [
           Some (React.JSX.String ("type", "type", ("text/css" : string)));
           Some
             (React.JSX.dangerouslyInnerHtml
                (object
                   method __html = globalStyles
                end));
         ])
      []
  in
  let app () = React.createElement "html" [] [ style ] in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream [ "<!DOCTYPE html><html><style type=\"text/css\">* { color: red; }</style></html>" ]

let suspense_with_multiple_children () =
  let app () =
    React.createElement "div" []
      [
        React.Suspense.make ~fallback:(React.string "Loading 1")
          ~children:(deffered_component ~seconds:0.1 ~children:(React.string "First") ())
          ();
        React.Suspense.make ~fallback:(React.string "Loading 2")
          ~children:(deffered_component ~seconds:0.2 ~children:(React.string "Second") ())
          ();
        React.Suspense.make ~fallback:(React.string "Loading 3")
          ~children:(deffered_component ~seconds:0.3 ~children:(React.string "Third") ())
          ();
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component app) in
  assert_stream stream
    [
      "<div><!--$?--><template id=\"B:0\"></template>Loading 1<!--/$--><!--$?--><template \
       id=\"B:1\"></template>Loading 2<!--/$--><!--$?--><template id=\"B:2\"></template>Loading 3<!--/$--></div>";
      "<div hidden id=\"S:0\"><div>Sleep 0.1 seconds<!-- -->, <!-- -->First</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
      "<div hidden id=\"S:1\"><div>Sleep 0.2 seconds<!-- -->, <!-- -->Second</div></div>";
      "<script>$RC('B:1','S:1')</script>";
      "<div hidden id=\"S:2\"><div>Sleep 0.3 seconds<!-- -->, <!-- -->Third</div></div>";
      "<script>$RC('B:2','S:2')</script>";
    ]

let tests =
  [
    test "silly_stream" test_silly_stream;
    test "render_inner_html" render_inner_html;
    test "react_use_without_suspense" react_use_without_suspense;
    test "uppercase_component_always_throwing" uppercase_component_always_throwing;
    test "suspense_with_react_use" suspense_with_react_use;
    test "async component" async_component;
    test "suspense_without_promise" suspense_without_promise;
    test "async_component_without_suspense" async_component_without_suspense;
    test "suspense_with_async_component" suspense_with_async_component;
    test "suspense_with_always_throwing" suspense_with_always_throwing;
    test "suspense_with_nested_suspense" suspense_with_nested_suspense;
    test "suspense_with_nested_suspense_with_error" suspense_with_nested_suspense_with_error;
    test "suspense_with_multiple_children" suspense_with_multiple_children;
  ]
