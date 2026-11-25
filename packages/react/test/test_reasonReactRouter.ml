let test title fn = Alcotest.test_case title `Quick fn
let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let show (url : ReasonReactRouter.url) =
  Printf.sprintf "path=[%s] search=%s hash=%s" (String.concat ";" url.path) url.search url.hash

let with_url url children = ReasonReactRouter.ServerUrl.make (ReasonReactRouter.ServerUrl.makeProps ~url ~children ())

let use_url_reader () =
  React.Upper_case_component ("reader", fun () -> React.string (show (ReasonReactRouter.useUrl ())))

let initial_url_reader () =
  React.Upper_case_component ("reader", fun () -> React.string (show (ReasonReactRouter.dangerouslyGetInitialUrl ())))

let render element = ReactDOM.renderToStaticMarkup element
let use_url_without_server_url () = assert_string (render (use_url_reader ())) "path=[] search= hash="

let use_url_with_server_url () =
  assert_string (render (with_url "/a/b?x=1#h" (use_url_reader ()))) "path=[a;b] search=x=1 hash=h"

let dangerously_get_initial_url_with_server_url () =
  assert_string (render (with_url "/a/b?x=1#h" (initial_url_reader ()))) "path=[a;b] search=x=1 hash=h"

let server_url_with_jsx () =
  let app = (ReasonReactRouter.ServerUrl.createElement ~url:"/jsx?q" ~children:[ use_url_reader () ] () [@JSX]) in
  assert_string (render app) "path=[jsx] search=q hash="

let nested_server_url_overrides () =
  let app =
    with_url "/outer" (React.list [ use_url_reader (); with_url "/inner?q" (use_url_reader ()); use_url_reader () ])
  in
  assert_string (render app) "path=[outer] search= hash=path=[inner] search=q hash=path=[outer] search= hash="

let explicit_server_url_wins () =
  let app =
    with_url "/provided"
      (React.Upper_case_component
         ( "reader",
           fun () ->
             let url = ReasonReactRouter.useUrl ~serverUrl:{ path = [ "explicit" ]; search = ""; hash = "" } () in
             React.string (show url) ))
  in
  assert_string (render app) "path=[explicit] search= hash="

let explicit_server_url_string_wins () =
  let app =
    with_url "/provided"
      (React.Upper_case_component
         ( "reader",
           fun () ->
             React.string (show (ReasonReactRouter.dangerouslyGetInitialUrl ~serverUrlString:"/explicit?s#h" ())) ))
  in
  assert_string (render app) "path=[explicit] search=s hash=h"

let server_url_is_scoped_to_render () =
  let _ = render (with_url "/a" (use_url_reader ())) in
  assert_string (show (ReasonReactRouter.dangerouslyGetInitialUrl ())) "path=[] search= hash="

let parsing_cases =
  [
    ("", "path=[] search= hash=");
    ("/", "path=[] search= hash=");
    ("/a/b/", "path=[a;b] search= hash=");
    ("/a//b", "path=[a;b] search= hash=");
    ("/?x=1", "path=[] search=x=1 hash=");
    ("/a/?x=1&y=2", "path=[a] search=x=1&y=2 hash=");
    ("/a?", "path=[a] search= hash=");
    ("/a#", "path=[a] search= hash=");
    ("/a?#", "path=[a] search= hash=");
    ("/a#h", "path=[a] search= hash=h");
    ("/a?x?y", "path=[a] search=x?y hash=");
    ("/a#h?x", "path=[a] search= hash=h?x");
    ("/a%20b/c", "path=[a%20b;c] search= hash=");
  ]

let parsing () =
  List.iter
    (fun (input, expected) ->
      let seen = ref "" in
      let reader =
        React.Upper_case_component
          ( "reader",
            fun () ->
              seen := show (ReasonReactRouter.useUrl ());
              React.null )
      in
      let _ = render (with_url input reader) in
      Alcotest.check Alcotest.string input expected !seen;
      Alcotest.check Alcotest.string input expected
        (show (ReasonReactRouter.dangerouslyGetInitialUrl ~serverUrlString:input ())))
    parsing_cases

let async_reader () =
  React.Async_component
    ( "async_reader",
      fun () ->
        let url = ReasonReactRouter.useUrl () in
        let%lwt () = Lwt_unix.sleep 0.001 in
        Lwt.return (React.string (show url)) )

let suspense children = React.Suspense.make (React.Suspense.makeProps ~fallback:(React.string "loading") ~children ())

let stream_reads_server_url_after_suspending () =
  Lwt_main.run
    (let%lwt stream, _abort = ReactDOM.renderToStream (with_url "/s/t?q=1#h" (suspense (async_reader ()))) in
     let%lwt chunks = Lwt_stream.to_list stream in
     let html = String.concat "" chunks in
     let expected = "path=[s;t] search=q=1 hash=h" in
     let contains =
       let rec go i =
         i + String.length expected <= String.length html
         && (String.sub html i (String.length expected) = expected || go (i + 1))
       in
       go 0
     in
     Alcotest.check Alcotest.bool html true contains;
     Lwt.return ())

let model_reads_server_url_after_suspending () =
  Lwt_main.run
    (let output = ref [] in
     let subscribe chunk =
       output := chunk :: !output;
       Lwt.return ()
     in
     let%lwt () = ReactServerDOM.render_model ~subscribe (with_url "/m?q#h" (suspense (async_reader ()))) in
     Alcotest.check Alcotest.bool
       (String.concat "" (List.rev !output))
       true
       (List.mem "2:\"path=[m] search=q hash=h\"\n" !output);
     Lwt.return ())

let reader_after_wait delay =
  React.Async_component
    ( "late_reader",
      fun () ->
        let%lwt () = Lwt_unix.sleep delay in
        let url = ReasonReactRouter.useUrl () in
        let%lwt () = Lwt_unix.sleep delay in
        Lwt.return (React.string (show url ^ "|" ^ show (ReasonReactRouter.useUrl ()))) )

let stream_html element =
  let%lwt stream, _abort = ReactDOM.renderToStream element in
  let%lwt chunks = Lwt_stream.to_list stream in
  Lwt.return (String.concat "" chunks)

let has text needle =
  let length = String.length needle in
  let rec go index =
    index + length <= String.length text && (String.sub text index length = needle || go (index + 1))
  in
  go 0

let concurrent_streams_keep_their_url () =
  let render url delay =
    stream_html (with_url url (suspense (React.list [ reader_after_wait delay; async_reader () ])))
  in
  let first, second = Lwt_main.run (Lwt.both (render "/first?a" 0.004) (render "/second?b" 0.001)) in
  let first_url = "path=[first] search=a hash=" and second_url = "path=[second] search=b hash=" in
  Alcotest.check Alcotest.bool first true (has first (first_url ^ "|" ^ first_url) && not (has first "path=[second]"));
  Alcotest.check Alcotest.bool second true
    (has second (second_url ^ "|" ^ second_url) && not (has second "path=[first]"))

let tests =
  ( "ReasonReactRouter",
    [
      test "useUrl without ServerUrl" use_url_without_server_url;
      test "useUrl with ServerUrl" use_url_with_server_url;
      test "dangerouslyGetInitialUrl with ServerUrl" dangerously_get_initial_url_with_server_url;
      test "ServerUrl with JSX" server_url_with_jsx;
      test "nested ServerUrl overrides" nested_server_url_overrides;
      test "explicit serverUrl wins" explicit_server_url_wins;
      test "explicit serverUrlString wins" explicit_server_url_string_wins;
      test "ServerUrl is scoped to the render" server_url_is_scoped_to_render;
      test "url parsing" parsing;
      test "renderToStream reads ServerUrl after suspending" stream_reads_server_url_after_suspending;
      test "render_model reads ServerUrl after suspending" model_reads_server_url_after_suspending;
      test "concurrent renderToStream renders keep their own ServerUrl after waits" concurrent_streams_keep_their_url;
    ] )
