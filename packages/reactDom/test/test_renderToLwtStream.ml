let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let assert_list ty left right =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let case title fn = Alcotest_lwt.test_case title `Quick fn

let assert_stream (stream : string Lwt_stream.t) expected =
  let open Lwt.Infix in
  Lwt_stream.to_list stream >>= fun content ->
  if content = [] then Lwt.return @@ Alcotest.fail "stream should not be empty"
  else Lwt.return @@ assert_list Alcotest.string content expected

module Sleep = struct
  let cached = ref false
  let destroy () = cached := false

  let delay v =
    if cached.contents then Lwt.return ()
    else
      let open Lwt.Infix in
      cached.contents <- true;
      Lwt_unix.sleep v >>= fun () -> Lwt.return ()
end

let test_silly_stream _switch () =
  let stream, push = Lwt_stream.create () in
  push (Some "first");
  push (Some "secondo");
  push (Some "trienio");
  push None;
  assert_stream stream [ "first"; "secondo"; "trienio" ]

let react_use_without_suspense _switch () =
  (* TODO: assert exception *)
  (* We clean the cache so we can re-use the same promise *)
  Sleep.destroy ();
  let delay = 0.1 in
  let app =
    React.Upper_case_component
      (fun () ->
        let () = React.use (Sleep.delay delay) in
        React.createElement "div" [||]
          [
            React.createElement "span" [||]
              [ React.string "Hello "; React.float delay ];
          ])
  in
  let stream, _abort = ReactDOM.renderToLwtStream app in
  assert_stream stream [ "<div><span>Hello 0.1</span></div>" ]

let suspense_without_promise _switch () =
  let hi =
    React.Upper_case_component
      (fun () ->
        React.createElement "div" [||]
          [ React.createElement "span" [||] [ React.string "Hello" ] ])
  in
  let app =
    React.Suspense { fallback = React.string "Loading..."; children = hi }
  in
  let stream, _abort = ReactDOM.renderToLwtStream app in
  assert_stream stream [ "<div><span>Hello</span></div>" ]

let suspense_with_always_throwing _switch () =
  let hi =
    React.Upper_case_component (fun () -> raise (Failure "always throwing"))
  in
  let app =
    React.Suspense { fallback = React.string "Loading..."; children = hi }
  in
  let stream, _abort = ReactDOM.renderToLwtStream app in
  assert_stream stream
    [ "<!--$?--><template id='B:0'></template>Loading...<!--/$-->" ]

let react_use_with_suspense _switch () =
  Sleep.destroy ();
  let delay = 0.5 in
  let time =
    React.Upper_case_component
      (fun () ->
        let () = React.use (Sleep.delay delay) in
        React.createElement "div" [||]
          [
            React.createElement "span" [||]
              [ React.string "Hello "; React.float delay ];
          ])
  in
  let app =
    React.Suspense { fallback = React.string "Loading..."; children = time }
  in
  let stream, _abort = ReactDOM.renderToLwtStream app in
  assert_stream stream
    [
      "<!--$?--><template id='B:0'></template>Loading...<!--/$-->";
      "<div hidden id='S:0'><div><span>Hello 0.5</span></div></div>";
      "<script>function \
       $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var \
       f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var \
       d=c.data;if(\"/$\"===d)if(0===e)break;else \
       e--;else\"$\"!==d&&\"$?\"!==d&&\"$!\"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data=\"$\";a._reactRetry&&a._reactRetry()}}</script>";
      "<script>$RC('B:0','S:0')</script>";
    ]

let tests =
  ( "renderToLwtStream",
    [
      case "test_silly_stream" test_silly_stream;
      (* case "react_use_without_suspense" react_use_without_suspense; *)
      case "suspense_with_always_throwing" suspense_with_always_throwing;
      case "suspense_without_promise" suspense_without_promise;
      case "react_use_with_suspense" react_use_with_suspense;
    ] )
