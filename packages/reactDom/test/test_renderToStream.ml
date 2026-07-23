let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left
let assert_list ty left right = Alcotest.check (Alcotest.list ty) "should be equal" right left

let test title fn =
  let isCI = match Sys.getenv_opt "CI" with Some _ -> true | None -> false in
  ( Printf.sprintf "ReactDOM.renderToStream / %s" title,
    [
      Alcotest_lwt.test_case "" `Quick (fun _switch () ->
          let start = Unix.gettimeofday () in
          let timeout =
            let%lwt () = Lwt_unix.sleep (if isCI then 0.05 else 0.02) in
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

let assert_stream (stream : string Lwt_stream.t) expected =
  let%lwt content = Lwt_stream.to_list stream in
  if content = [] then Lwt.return (Alcotest.fail "stream should not be empty")
  else Lwt.return (assert_list Alcotest.string content expected)

let mk_suspense ?key ?fallback ?children () = React.Suspense.make ?key (React.Suspense.makeProps ?fallback ?children ())

let mk_context context ~value ~children () =
  React.Context.provider context (React.Context.makeProps ~value ~children ())

module Sleep = struct
  let cached = ref false
  let destroy () = cached := false

  let delay v =
    if cached.contents then Lwt.return v
    else (
      cached.contents <- true;
      let%lwt () = Lwt.pause () in
      Lwt.return v)
end

let deffered_component ~seconds ~children () =
  React.Async_component
    ( "deffered_component",
      fun () ->
        let%lwt () = if seconds <= 0. then Lwt.pause () else Lwt_unix.sleep seconds in
        Lwt.return
          (React.createElement "div" []
             [ React.string ("Sleep " ^ Float.to_string seconds ^ " seconds"); React.string ", "; children ]) )

let silly_stream () =
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
      ( "app",
        fun () ->
          let delay = React.Experimental.usePromise (Sleep.delay 0.001) in
          React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello "; React.float delay ] ] )
  in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_stream stream [ "<div><span>Hello <!-- -->0.001</span></div>" ]

let suspense_without_promise () =
  let hi =
    React.Upper_case_component
      ("hi", fun () -> React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello" ] ])
  in
  let app () = mk_suspense ~fallback:(React.string "Loading...") ~children:hi () in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<div><span>Hello</span></div>" ]

let text_after_element_with_text_child () =
  let app () =
    React.createElement "div" []
      [ React.string "before "; React.createElement "span" [] [ React.string "inner" ]; React.string " after" ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<div>before <span>inner</span> after</div>" ]

let suspense_with_resolved_text_after_element_with_text_child () =
  let app () =
    let deferred () =
      React.Async_component
        ( "deferred",
          fun () ->
            let%lwt () = Lwt.pause () in
            Lwt.return
              (React.createElement "div" []
                 [
                   React.string "before "; React.createElement "span" [] [ React.string "inner" ]; React.string " after";
                 ]) )
    in
    mk_suspense ~fallback:(React.string "Loading...") ~children:(deferred ()) ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>Loading...<!--/$-->";
      "<div hidden id=\"S:0\"><div>before <span>inner</span> after</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let assert_raises exn fn =
  match%lwt fn () with
  | exception exn -> Lwt.return (assert_string (Printexc.to_string exn) (Printexc.to_string exn))
  | _ -> Alcotest.failf "Expected exception %s" (Printexc.to_string exn)

let always_throwing_component () =
  React.Upper_case_component ("always throwing", fun () -> raise (Failure "always throwing"))

let uppercase_component_always_throwing () =
  let app () = always_throwing_component () in
  assert_raises (Failure "always throwing") (fun () ->
      ReactDOM.renderToStream (React.Upper_case_component ("app", app)))

let suspense_with_always_throwing () =
  (* This test is very fragile since it relies on the stack trace being the same (so line numbers and methods should match).
     We disable backtracing to avoid having to match the backtrace *)
  let prev = Printexc.backtrace_status () in
  Printexc.record_backtrace false;
  let app () = mk_suspense ~fallback:(React.string "Loading...") ~children:(always_throwing_component ()) () in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  Printexc.record_backtrace prev;
  assert_stream stream
    [ "<!--$!--><template data-msg=\"Failure(&quot;always throwing&quot;)\n\"></template>Loading...<!--/$-->" ]

let suspense_with_always_throwing_in_prod () =
  (* In production no error detail (message/backtrace) may leak into the HTML *)
  let app () = mk_suspense ~fallback:(React.string "Loading...") ~children:(always_throwing_component ()) () in
  let%lwt stream, _abort = ReactDOM.renderToStream ~env:`Prod (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<!--$!--><template></template>Loading...<!--/$-->" ]

let suspense_with_react_use () =
  Sleep.destroy ();
  let time =
    React.Upper_case_component
      ( "time",
        fun () ->
          let delay = React.Experimental.usePromise (Sleep.delay 0.005) in
          React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello "; React.float delay ] ] )
  in
  let app () = mk_suspense ~fallback:(React.string "Loading...") ~children:time () in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>Loading...<!--/$-->";
      "<div hidden id=\"S:0\"><div><span>Hello <!-- -->0.005</span></div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let with_custom_component () =
  let custom_component =
    React.Upper_case_component
      ( "custom component",
        fun () -> React.createElement "div" [] [ React.createElement "span" [] [ React.string "Custom Component" ] ] )
  in
  let app () = React.createElement "div" [] [ custom_component ] in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<div><div><span>Custom Component</span></div></div>" ]

let with_multiple_custom_components () =
  let custom_component =
    React.Upper_case_component
      ( "custom component",
        fun () -> React.createElement "div" [] [ React.createElement "span" [] [ React.string "Custom Component" ] ] )
  in
  let app () = React.createElement "div" [] [ custom_component; custom_component ] in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<div><div><span>Custom Component</span></div><div><span>Custom Component</span></div></div>" ]

let async_component () =
  let app () =
    React.Async_component ("app", fun () -> Lwt.return (React.createElement "span" [] [ React.string "yow" ]))
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<span>yow</span>" ]

let suspense_with_async_component () =
  let app () =
    React.createElement "div" []
      [
        mk_suspense ~fallback:(React.string "Fallback 1")
          ~children:(deffered_component ~seconds:0. ~children:(React.string "lol") ())
          ();
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<div><!--$?--><template id=\"B:0\"></template>Fallback 1<!--/$--></div>";
      "<div hidden id=\"S:0\"><div>Sleep 0. seconds<!-- -->, <!-- -->lol</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let suspense_with_nested_suspense () =
  let app () =
    mk_suspense ~fallback:(React.string "Fallback 1")
      ~children:
        (deffered_component ~seconds:0.
           ~children:
             (mk_suspense ~fallback:(React.string "Fallback 2")
                ~children:(deffered_component ~seconds:0. ~children:(React.string "lol") ())
                ())
           ())
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>Fallback 1<!--/$-->";
      "<div hidden id=\"S:0\"><div>Sleep 0. seconds<!-- -->, <!--$?--><template id=\"B:1\"></template>Fallback \
       2<!--/$--></div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
      "<div hidden id=\"S:1\"><div>Sleep 0. seconds<!-- -->, <!-- -->lol</div></div>";
      "<script>$RC('B:1','S:1')</script>";
    ]

let suspense_with_nested_suspense_with_error () =
  let prev = Printexc.backtrace_status () in
  Printexc.record_backtrace false;
  let app () =
    mk_suspense ~fallback:(React.string "Fallback 1")
      ~children:
        (deffered_component ~seconds:0.
           ~children:(mk_suspense ~fallback:(React.string "Fallback 2") ~children:(always_throwing_component ()) ())
           ())
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  Printexc.record_backtrace prev;
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>Fallback 1<!--/$-->";
      "<div hidden id=\"S:0\"><div>Sleep 0. seconds<!-- -->, <!--$!--><template data-msg=\"Failure(&quot;always \
       throwing&quot;)\n\
       \"></template>Fallback 2<!--/$--></div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let async_component_without_suspense () =
  let app () = React.createElement "main" [] [ deffered_component ~seconds:0. ~children:(React.string "lol") () ] in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<main><div>Sleep 0. seconds<!-- -->, <!-- -->lol</div></main>" ]

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
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<!DOCTYPE html><html><style type=\"text/css\">* { color: red; }</style></html>" ]

let suspense_with_multiple_children () =
  let app () =
    React.createElement "div" []
      [
        mk_suspense ~fallback:(React.string "Loading 1")
          ~children:(deffered_component ~seconds:0.001 ~children:(React.string "First") ())
          ();
        mk_suspense ~fallback:(React.string "Loading 2")
          ~children:(deffered_component ~seconds:0.002 ~children:(React.string "Second") ())
          ();
        mk_suspense ~fallback:(React.string "Loading 3")
          ~children:(deffered_component ~seconds:0.003 ~children:(React.string "Third") ())
          ();
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<div><!--$?--><template id=\"B:0\"></template>Loading 1<!--/$--><!--$?--><template \
       id=\"B:1\"></template>Loading 2<!--/$--><!--$?--><template id=\"B:2\"></template>Loading 3<!--/$--></div>";
      "<div hidden id=\"S:0\"><div>Sleep 0.001 seconds<!-- -->, <!-- -->First</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
      "<div hidden id=\"S:1\"><div>Sleep 0.002 seconds<!-- -->, <!-- -->Second</div></div>";
      "<script>$RC('B:1','S:1')</script>";
      "<div hidden id=\"S:2\"><div>Sleep 0.003 seconds<!-- -->, <!-- -->Third</div></div>";
      "<script>$RC('B:2','S:2')</script>";
    ]

let suspense_with_multiple_children_reordered () =
  let app () =
    React.createElement "div" []
      [
        mk_suspense ~fallback:(React.string "Loading 3")
          ~children:(deffered_component ~seconds:0.003 ~children:(React.string "Third") ())
          ();
        mk_suspense ~fallback:(React.string "Loading 1")
          ~children:(deffered_component ~seconds:0.001 ~children:(React.string "First") ())
          ();
        mk_suspense ~fallback:(React.string "Loading 2")
          ~children:(deffered_component ~seconds:0.002 ~children:(React.string "Second") ())
          ();
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<div><!--$?--><template id=\"B:0\"></template>Loading 3<!--/$--><!--$?--><template \
       id=\"B:1\"></template>Loading 1<!--/$--><!--$?--><template id=\"B:2\"></template>Loading 2<!--/$--></div>";
      "<div hidden id=\"S:1\"><div>Sleep 0.001 seconds<!-- -->, <!-- -->First</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:1','S:1')</script>";
      "<div hidden id=\"S:2\"><div>Sleep 0.002 seconds<!-- -->, <!-- -->Second</div></div>";
      "<script>$RC('B:2','S:2')</script>";
      "<div hidden id=\"S:0\"><div>Sleep 0.003 seconds<!-- -->, <!-- -->Third</div></div>";
      "<script>$RC('B:0','S:0')</script>";
    ]

let suspense_with_nested_suspenses () =
  let app () =
    mk_suspense ~fallback:(React.string "Outer loading")
      ~children:
        (React.createElement "div" []
           [
             React.string "Before";
             mk_suspense ~fallback:(React.string "Inner loading 1")
               ~children:(deffered_component ~seconds:0.001 ~children:(React.string "First") ())
               ();
             mk_suspense ~fallback:(React.string "Inner loading 2")
               ~children:(deffered_component ~seconds:0.002 ~children:(React.string "Second") ())
               ();
           ])
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<div>Before<!--$?--><template id=\"B:0\"></template>Inner loading 1<!--/$--><!--$?--><template \
       id=\"B:1\"></template>Inner loading 2<!--/$--></div>";
      "<div hidden id=\"S:0\"><div>Sleep 0.001 seconds<!-- -->, <!-- -->First</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
      "<div hidden id=\"S:1\"><div>Sleep 0.002 seconds<!-- -->, <!-- -->Second</div></div>";
      "<script>$RC('B:1','S:1')</script>";
    ]

let suspense_with_concurrent_suspenses () =
  let app () =
    React.createElement "div" []
      [
        React.string "Static content";
        React.createElement "div"
          [ React.JSX.String ("id", "id", "hydrate1") ]
          [
            mk_suspense ~fallback:(React.string "Loading 1")
              ~children:(deffered_component ~seconds:0.001 ~children:(React.string "Hydrated 1") ())
              ();
          ];
        React.createElement "div"
          [ React.JSX.String ("id", "id", "hydrate2") ]
          [
            mk_suspense ~fallback:(React.string "Loading 2")
              ~children:(deffered_component ~seconds:0.002 ~children:(React.string "Hydrated 2") ())
              ();
          ];
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<div>Static content<div id=\"hydrate1\"><!--$?--><template id=\"B:0\"></template>Loading 1<!--/$--></div><div \
       id=\"hydrate2\"><!--$?--><template id=\"B:1\"></template>Loading 2<!--/$--></div></div>";
      "<div hidden id=\"S:0\"><div>Sleep 0.001 seconds<!-- -->, <!-- -->Hydrated 1</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
      "<div hidden id=\"S:1\"><div>Sleep 0.002 seconds<!-- -->, <!-- -->Hydrated 2</div></div>";
      "<script>$RC('B:1','S:1')</script>";
    ]

let suspense_with_comments () =
  let app () =
    React.createElement "div" []
      [
        React.createElement "div" [] [ React.string "<!-- tricky comment -->" ];
        mk_suspense ~fallback:(React.string "Loading")
          ~children:(deffered_component ~seconds:0. ~children:(React.string "Content") ())
          ();
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<div><div>&lt;!-- tricky comment --&gt;</div><!--$?--><template id=\"B:0\"></template>Loading<!--/$--></div>";
      "<div hidden id=\"S:0\"><div>Sleep 0. seconds<!-- -->, <!-- -->Content</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let abort_app () =
  let app () =
    React.createElement "div" []
      [
        mk_suspense ~fallback:(React.string "Loading 1")
          ~children:(deffered_component ~seconds:0.003 ~children:(React.string "Content 1") ())
          ();
        mk_suspense ~fallback:(React.string "Loading 2")
          ~children:(deffered_component ~seconds:0.003 ~children:(React.string "Content 2") ())
          ();
      ]
  in
  React.Upper_case_component ("app", app)

let abort_shell_chunk =
  "<div><!--$?--><template id=\"B:0\"></template>Loading 1<!--/$--><!--$?--><template id=\"B:1\"></template>Loading \
   2<!--/$--></div>"

(* Records exceptions raised inside Lwt.async while [fn] runs: an unguarded push into the closed stream after abort
   would crash the process through the default hook. *)
let with_async_exception_hook fn =
  let async_exceptions = ref [] in
  let previous_hook = !Lwt.async_exception_hook in
  (Lwt.async_exception_hook := fun exn -> async_exceptions := Printexc.to_string exn :: !async_exceptions);
  let%lwt result = fn () in
  Lwt.async_exception_hook := previous_hook;
  Lwt.return (result, List.rev !async_exceptions)

let abort_with_pending_boundaries () =
  let%lwt (first_chunk, remaining), async_exceptions =
    with_async_exception_hook (fun () ->
        let%lwt stream, abort = ReactDOM.renderToStream (abort_app ()) in
        let%lwt first_chunk = Lwt_stream.get stream in
        (* Abort while both boundaries are still pending *)
        abort ();
        let%lwt remaining = Lwt_stream.to_list stream in
        (* Let the deferred components resolve after the abort: their completions must not push into the closed
           stream nor raise *)
        let%lwt () = Lwt_unix.sleep 0.005 in
        Lwt.return (first_chunk, remaining))
  in
  (match first_chunk with
  | Some chunk -> assert_string chunk abort_shell_chunk
  | None -> Alcotest.fail "Expected the shell chunk before abort");
  assert_list Alcotest.string remaining
    [
      "<script>$RX=function(b,c,d,e,f){var \
       a=document.getElementById(b);a&&(b=a.previousSibling,b.data=\"$!\",a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};;$RX(\"B:0\",\"\",\"Switched \
       to client rendering because the server rendering aborted due to:\\n\\nThe render was aborted by the server \
       without a reason.\")</script>";
      "<script>$RX(\"B:1\",\"\",\"Switched to client rendering because the server rendering aborted due to:\\n\\nThe \
       render was aborted by the server without a reason.\")</script>";
    ];
  assert_list Alcotest.string async_exceptions [];
  Lwt.return ()

let abort_with_pending_boundaries_in_prod () =
  let%lwt stream, abort = ReactDOM.renderToStream ~env:`Prod (abort_app ()) in
  let%lwt first_chunk = Lwt_stream.get stream in
  abort ();
  let%lwt remaining = Lwt_stream.to_list stream in
  (match first_chunk with
  | Some chunk -> assert_string chunk abort_shell_chunk
  | None -> Alcotest.fail "Expected the shell chunk before abort");
  (* In production only the digest is passed to $RX, no error detail *)
  assert_list Alcotest.string remaining
    [
      "<script>$RX=function(b,c,d,e,f){var \
       a=document.getElementById(b);a&&(b=a.previousSibling,b.data=\"$!\",a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};;$RX(\"B:0\",\"\")</script>";
      "<script>$RX(\"B:1\",\"\")</script>";
    ];
  Lwt.return ()

let abort_is_idempotent () =
  let%lwt stream, abort = ReactDOM.renderToStream (abort_app ()) in
  let%lwt _first_chunk = Lwt_stream.get stream in
  abort ();
  (* A second abort on a closed stream must be a no-op *)
  abort ();
  let%lwt remaining = Lwt_stream.to_list stream in
  Alcotest.(check int) "only one $RX chunk per pending boundary" 2 (List.length remaining);
  Lwt.return ()

let abort_after_completed_render_is_noop () =
  let app () =
    mk_suspense ~fallback:(React.string "Loading")
      ~children:(deffered_component ~seconds:0. ~children:(React.string "Content") ())
      ()
  in
  let%lwt stream, abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  let%lwt content = Lwt_stream.to_list stream in
  (* The render is fully flushed and the stream closed, aborting afterwards must not raise nor emit $RX *)
  abort ();
  assert_list Alcotest.string content
    [
      "<!--$?--><template id=\"B:0\"></template>Loading<!--/$-->";
      "<div hidden id=\"S:0\"><div>Sleep 0. seconds<!-- -->, <!-- -->Content</div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ];
  Lwt.return ()

let context_basic () =
  let context = React.createContext "default" in
  let consumer =
    React.Upper_case_component
      ( "consumer",
        fun () ->
          let value = React.useContext context in
          React.createElement "span" [] [ React.string value ] )
  in
  let app () = mk_context context ~value:"provided" ~children:consumer () in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<span>provided</span>" ]

let context_default_value () =
  let context = React.createContext "fallback" in
  let app =
    React.Upper_case_component
      ( "consumer",
        fun () ->
          let value = React.useContext context in
          React.createElement "span" [] [ React.string value ] )
  in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_stream stream [ "<span>fallback</span>" ]

let context_nested_providers () =
  let context = React.createContext "default" in
  let consumer () =
    React.Upper_case_component
      ( "consumer",
        fun () ->
          let value = React.useContext context in
          React.createElement "span" [] [ React.string value ] )
  in
  let app () =
    mk_context context ~value:"outer"
      ~children:
        (React.list
           [
             consumer ();
             React.Upper_case_component
               ("inner_provider", fun () -> mk_context context ~value:"inner" ~children:(consumer ()) ());
             consumer ();
           ])
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<span>outer</span><span>inner</span><span>outer</span>" ]

let context_multiple_independent () =
  let context_a = React.createContext "a-default" in
  let context_b = React.createContext "b-default" in
  let consumer () =
    React.Upper_case_component
      ( "consumer",
        fun () ->
          let a = React.useContext context_a in
          let b = React.useContext context_b in
          React.createElement "div" [] [ React.string a; React.string "-"; React.string b ] )
  in
  let app () =
    mk_context context_a ~value:"a-provided"
      ~children:(mk_context context_b ~value:"b-provided" ~children:(consumer ()) ())
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<div>a-provided<!-- -->-<!-- -->b-provided</div>" ]

let context_with_suspense () =
  let context = React.createContext "default" in
  let consumer =
    React.Upper_case_component
      ( "consumer",
        fun () ->
          let value = React.useContext context in
          React.createElement "span" [] [ React.string value ] )
  in
  let app () =
    mk_context context ~value:"provided"
      ~children:(mk_suspense ~fallback:(React.string "loading") ~children:consumer ())
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<span>provided</span>" ]

let async_component_with_use_id () =
  let app =
    React.Async_component
      ( "app",
        fun () ->
          let id = React.useId () in
          Lwt.return (React.createElement "div" [ React.JSX.String ("id", "id", id) ] []) )
  in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_stream stream [ "<div id=\"\xc2\xabR0\xc2\xbb\"></div>" ]

let async_component_with_use_id_and_sibling () =
  let async_with_id =
    React.Async_component
      ( "AsyncWithId",
        fun () ->
          let id = React.useId () in
          Lwt.return (React.createElement "div" [ React.JSX.String ("id", "id", id) ] []) )
  in
  let sync_with_id =
    React.Upper_case_component
      ( "SyncWithId",
        fun () ->
          let id = React.useId () in
          React.createElement "span" [ React.JSX.String ("id", "id", id) ] [] )
  in
  let app = React.createElement "div" [] [ async_with_id; sync_with_id ] in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_stream stream [ "<div><div id=\"\xc2\xabR1\xc2\xbb\"></div><span id=\"\xc2\xabR2\xc2\xbb\"></span></div>" ]

let async_component_with_use_id_in_suspense () =
  let async_with_id =
    React.Async_component
      ( "AsyncWithId",
        fun () ->
          let id = React.useId () in
          let%lwt () = Lwt.pause () in
          Lwt.return (React.createElement "div" [ React.JSX.String ("id", "id", id) ] []) )
  in
  let app = mk_suspense ~fallback:(React.string "loading") ~children:async_with_id () in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>loading<!--/$-->";
      "<div hidden id=\"S:0\"><div id=\"\xc2\xabR0\xc2\xbb\"></div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let async_component_with_multiple_use_ids () =
  let app =
    React.Async_component
      ( "app",
        fun () ->
          let id1 = React.useId () in
          let id2 = React.useId () in
          Lwt.return
            (React.createElement "div"
               [ React.JSX.String ("data-id1", "data-id1", id1); React.JSX.String ("data-id2", "data-id2", id2) ]
               []) )
  in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_stream stream [ "<div data-id1=\"\xc2\xabR0\xc2\xbb\" data-id2=\"\xc2\xabR0H1\xc2\xbb\"></div>" ]

let multiple_async_components_without_suspense () =
  let app () =
    React.createElement "div" []
      [
        deffered_component ~seconds:0. ~children:(React.string "First") ();
        deffered_component ~seconds:0. ~children:(React.string "Second") ();
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<div><div>Sleep 0. seconds<!-- -->, <!-- -->First</div><div>Sleep 0. seconds<!-- -->, <!-- -->Second</div></div>";
    ]

let context_provider_with_suspended_consumer () =
  let context = React.createContext "default" in
  let async_consumer =
    React.Async_component
      ( "async_consumer",
        fun () ->
          (* useContext must be called synchronously, before yielding *)
          let value = React.useContext context in
          let%lwt () = Lwt.pause () in
          Lwt.return (React.createElement "span" [] [ React.string value ]) )
  in
  let app () =
    (* Provider inside Suspense children — so it's re-rendered in the deferred path *)
    mk_suspense ~fallback:(React.string "loading")
      ~children:(mk_context context ~value:"from-provider" ~children:async_consumer ())
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>loading<!--/$-->";
      "<div hidden id=\"S:0\"><span>from-provider</span></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

let async_component_returning_suspense_with_async_children () =
  let app () =
    mk_suspense ~fallback:(React.string "Outer loading")
      ~children:
        (React.Async_component
           ( "outer_async",
             fun () ->
               let%lwt () = Lwt.pause () in
               Lwt.return
                 (mk_suspense ~fallback:(React.string "Inner loading")
                    ~children:(deffered_component ~seconds:0. ~children:(React.string "deep") ())
                    ()) ))
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>Outer loading<!--/$-->";
      "<div hidden id=\"S:0\"><!--$?--><template id=\"B:1\"></template>Inner loading<!--/$--></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
      "<div hidden id=\"S:1\"><div>Sleep 0. seconds<!-- -->, <!-- -->deep</div></div>";
      "<script>$RC('B:1','S:1')</script>";
    ]

let static_element_in_stream () =
  let original = React.createElement "div" [] [ React.string "Hello" ] in
  let app = React.Static { prerendered = "<div>Hello</div>"; original } in
  let%lwt stream, _abort = ReactDOM.renderToStream app in
  assert_stream stream [ "<div>Hello</div>" ]

let client_component_error_in_stream () =
  let app =
    React.Client_component
      { key = None; props = []; client = React.Empty; import_module = "test_module"; import_name = "TestComponent" }
  in
  assert_raises
    (Invalid_argument
       "Client components can't be rendered on the server via renderToStream. Please use the React server components \
        API instead. module: test_module") (fun () -> ReactDOM.renderToStream app)

let suspense_with_failed_promise () =
  let prev = Printexc.backtrace_status () in
  Printexc.record_backtrace false;
  let app () =
    mk_suspense ~fallback:(React.string "Error fallback")
      ~children:(React.Async_component ("failing_async", fun () -> Lwt.fail (Failure "async failure")))
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  Printexc.record_backtrace prev;
  assert_stream stream
    [ "<!--$!--><template data-msg=\"Failure(&quot;async failure&quot;)\n\"></template>Error fallback<!--/$-->" ]

(* The promise is still sleeping when the shell flushes (the fallback goes out), then rejects: the boundary must flip
   to client rendering via $RX instead of escaping into Lwt.async_exception_hook (which would kill the process) or
   leaving the stream open forever. *)
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
  let prev = Printexc.backtrace_status () in
  Printexc.record_backtrace false;
  let%lwt (first_chunk, remaining), async_exceptions =
    with_async_exception_hook (fun () ->
        let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", late_failing_app)) in
        let%lwt first_chunk = Lwt_stream.get stream in
        let%lwt remaining = Lwt_stream.to_list stream in
        Lwt.return (first_chunk, remaining))
  in
  Printexc.record_backtrace prev;
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
  (* In production only the digest is passed to $RX, no error detail *)
  assert_list Alcotest.string remaining
    [
      "<script>$RX=function(b,c,d,e,f){var \
       a=document.getElementById(b);a&&(b=a.previousSibling,b.data=\"$!\",a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};;$RX(\"B:0\",\"\")</script>";
    ];
  Lwt.return ()

let fragment_in_stream () =
  let app () =
    React.Fragment
      (React.createElement "div" []
         [ React.createElement "span" [] [ React.string "a" ]; React.createElement "span" [] [ React.string "b" ] ])
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<div><span>a</span><span>b</span></div>" ]

let list_in_stream () =
  let app () =
    React.createElement "ul" []
      [
        React.List
          [
            React.createElement "li" [] [ React.string "one" ];
            React.createElement "li" [] [ React.string "two" ];
            React.createElement "li" [] [ React.string "three" ];
          ];
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<ul><li>one</li><li>two</li><li>three</li></ul>" ]

let array_in_stream () =
  let app () =
    React.createElement "ul" []
      [
        React.Array
          [| React.createElement "li" [] [ React.string "one" ]; React.createElement "li" [] [ React.string "two" ] |];
      ]
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<ul><li>one</li><li>two</li></ul>" ]

let empty_element_in_stream () =
  let app () = React.createElement "div" [] [ React.Empty; React.string "hello"; React.Empty ] in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream [ "<div>hello</div>" ]

let dangerous_html_in_suspense () =
  let app () =
    mk_suspense ~fallback:(React.string "Loading...")
      ~children:
        (React.Async_component
           ( "Dangerous and sleep",
             fun () ->
               let%lwt () = Lwt.pause () in
               Lwt.return
                 (React.createElement "div"
                    [
                      React.JSX.dangerouslyInnerHtml
                        (let html_content = "<div>Dangerous HTML</div>" in
                         object
                           method __html = html_content
                         end);
                    ]
                    []) ))
      ()
  in
  let%lwt stream, _abort = ReactDOM.renderToStream (React.Upper_case_component ("app", app)) in
  assert_stream stream
    [
      "<!--$?--><template id=\"B:0\"></template>Loading...<!--/$-->";
      "<div hidden id=\"S:0\"><div><div>Dangerous HTML</div></div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
    ]

(* Pauses on the first render only; subsequent renders resolve synchronously. Needed to reproduce the
   boundary-completes-while-shell-is-parked race: the boundary's async block re-renders its children after the
   promise resolves, and only a now-synchronous child lets the block complete (and hit [waiting = 0]) while the main
   walk is still parked. *)
let once_pausing_component ~name ~children () =
  let resolved = ref false in
  React.Async_component
    ( name,
      fun () ->
        if !resolved then Lwt.return children
        else (
          resolved := true;
          let%lwt () = Lwt.pause () in
          Lwt.return children) )

let boundary_resolves_while_shell_is_suspended () =
  (* A Suspense boundary that fully completes while the main walk is parked awaiting a top-level (unwrapped) async
     component. The root walk counts as a pending unit: the boundary hitting [waiting = 0] must not close the stream
     before the shell push (which used to reject the render with Lwt_stream.Closed). *)
  let app =
    React.createElement "div" []
      [
        mk_suspense ~fallback:(React.string "Loading")
          ~children:(once_pausing_component ~name:"inside" ~children:(React.string "Inner") ())
          ();
        once_pausing_component ~name:"outside" ~children:(React.string "Outside") ();
      ]
  in
  let%lwt chunks, async_exceptions =
    with_async_exception_hook (fun () ->
        let%lwt stream, _abort = ReactDOM.renderToStream app in
        Lwt_stream.to_list stream)
  in
  assert_list Alcotest.string async_exceptions [];
  assert_list Alcotest.string chunks
    [
      "<div hidden id=\"S:0\">Inner</div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}$RC('B:0','S:0')</script>";
      "<div>InnerOutside</div>";
    ];
  Lwt.return ()

let tests =
  [
    test "silly_stream" silly_stream;
    test "render_inner_html" render_inner_html;
    test "react_use_without_suspense" react_use_without_suspense;
    test "uppercase_component_always_throwing" uppercase_component_always_throwing;
    test "suspense_with_react_use" suspense_with_react_use;
    test "async component" async_component;
    test "async_component_without_suspense" async_component_without_suspense;
    test "suspense_without_promise" suspense_without_promise;
    test "text_after_element_with_text_child" text_after_element_with_text_child;
    test "suspense_with_resolved_text_after_element_with_text_child"
      suspense_with_resolved_text_after_element_with_text_child;
    test "suspense_with_async_component" suspense_with_async_component;
    test "suspense_with_always_throwing" suspense_with_always_throwing;
    test "suspense_with_always_throwing_in_prod" suspense_with_always_throwing_in_prod;
    test "boundary_resolves_while_shell_is_suspended" boundary_resolves_while_shell_is_suspended;
    test "suspense_with_nested_suspense" suspense_with_nested_suspense;
    test "suspense_with_nested_suspenses" suspense_with_nested_suspenses;
    test "suspense_with_nested_suspense_with_error" suspense_with_nested_suspense_with_error;
    test "suspense_with_multiple_children" suspense_with_multiple_children;
    test "suspense_with_multiple_children_reordered" suspense_with_multiple_children_reordered;
    test "suspense_with_concurrent_suspenses" suspense_with_concurrent_suspenses;
    test "suspense_with_comments" suspense_with_comments;
    test "abort_with_pending_boundaries" abort_with_pending_boundaries;
    test "abort_with_pending_boundaries_in_prod" abort_with_pending_boundaries_in_prod;
    test "abort_is_idempotent" abort_is_idempotent;
    test "abort_after_completed_render_is_noop" abort_after_completed_render_is_noop;
    test "context_basic" context_basic;
    test "context_default_value" context_default_value;
    test "context_nested_providers" context_nested_providers;
    test "context_multiple_independent" context_multiple_independent;
    test "context_with_suspense" context_with_suspense;
    test "async_component_with_use_id" async_component_with_use_id;
    test "async_component_with_use_id_and_sibling" async_component_with_use_id_and_sibling;
    test "async_component_with_use_id_in_suspense" async_component_with_use_id_in_suspense;
    test "async_component_with_multiple_use_ids" async_component_with_multiple_use_ids;
    test "multiple_async_components_without_suspense" multiple_async_components_without_suspense;
    test "context_provider_with_suspended_consumer" context_provider_with_suspended_consumer;
    test "async_component_returning_suspense_with_async_children" async_component_returning_suspense_with_async_children;
    test "static_element_in_stream" static_element_in_stream;
    test "client_component_error_in_stream" client_component_error_in_stream;
    test "suspense_with_failed_promise" suspense_with_failed_promise;
    test "suspense_with_promise_that_rejects_after_flush" suspense_with_promise_that_rejects_after_flush;
    test "suspense_rejects_after_flush_in_prod" suspense_rejects_after_flush_in_prod;
    test "fragment_in_stream" fragment_in_stream;
    test "list_in_stream" list_in_stream;
    test "array_in_stream" array_in_stream;
    test "empty_element_in_stream" empty_element_in_stream;
    test "dangerous_html_in_suspense" dangerous_html_in_suspense;
  ]
