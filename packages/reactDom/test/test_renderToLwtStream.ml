let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let assert_list ty left right =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

let make ~delay =
  let () = React.use (Lwt_unix.sleep delay) in
  React.createElement "div" [||]
    [
      React.createElement "span" [||]
        [ React.string "Hello"; React.float delay ];
    ]

let assert_stream (stream : string Lwt_stream.t) expected =
  let open Lwt.Infix in
  Lwt_stream.to_list stream >>= fun content ->
  if content = [] then Lwt.return @@ Alcotest.fail "stream should not be empty"
  else Lwt.return @@ assert_list Alcotest.string content expected

let test_silly_stream _switch () : unit Lwt.t =
  let stream, push = Lwt_stream.create () in
  push (Some "first");
  push (Some "secondo");
  push None;
  assert_stream stream [ "first"; "secondo" ]

let suspense_one _switch () : unit Lwt.t =
  let timer = React.Upper_case_component (fun () -> make ~delay:0.1) in
  let stream, _abort = ReactDOM.renderToLwtStream timer in
  assert_stream stream [ "Hello"; "1." ]

let case title fn = Alcotest_lwt.test_case title `Quick fn

let tests =
  ( "renderToLwtStream",
    [
      case "test_silly_stream" test_silly_stream;
      case "suspense_one" suspense_one;
    ] )
