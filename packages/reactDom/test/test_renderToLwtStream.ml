let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let make ~delay =
  let () = React.use (Lwt_unix.sleep delay) in
  React.createElement "div" [||]
    [
      React.createElement "span" [||]
        [ React.string "Hello"; React.string "Hello" ];
    ]

let cleanup switch abort =
  let free () = Lwt.return () in
  Lwt_switch.add_hook (Some switch) free;
  Lwt.async (fun () ->
      abort ();
      failwith "All is broken");
  Lwt.return ()

let suspense_one switch () =
  let _pipe, abort = ReactDOM.renderToLwtStream (make ~delay:0.1) in

  assert_string "asdf"
    "<div data-reactroot=\"\"><span>Hello<!-- -->Hello</span></div>";
  cleanup switch abort

let case title fn = Alcotest_lwt.test_case title `Quick fn
let tests = ("renderToLwtStream", [ case "suspense_one" suspense_one ])
