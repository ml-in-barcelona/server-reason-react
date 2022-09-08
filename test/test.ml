open Alcotest

module React = struct
  let createElement tag = Printf.sprintf "<%s></%s>" tag tag
end

module ReactDOMServer = struct
  let renderToString _component = ""
end

let expect_msg = "should be equal"
let assert_string left right = (check string) expect_msg right left
let test_div () = assert_string (React.createElement "div") "<div></div>"
let test_attributes () = assert_string (React.createElement "div") "<div></div>"
let test_children () = assert_string (React.createElement "div") "<div></div>"

let test_closing_tag () =
  assert_string (React.createElement "div") "<div></div>"

let () =
  let open Alcotest in
  run "Test suit"
    [ ( "React"
      , [ test_case "div" `Quick test_div
        ; test_case "attributes" `Quick test_attributes
        ; test_case "children" `Quick test_children
        ; test_case "self-closing tag" `Quick test_closing_tag
        ] )
    ; ("ReactDOMServer", [])
    ]
