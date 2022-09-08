open Alcotest

module React = struct
  let attribute_to_string (k, v) =
    match k with "" -> "" | _ -> Printf.sprintf "%s=\"%s\"" k v

  let attributes_to_string attrs =
    match attrs with
    | [] -> ""
    | _ -> String.concat " " (List.map attribute_to_string attrs)

  let is_self_closing_tag = function "input" -> true | _ -> false

  let createElement tag attributes =
    match is_self_closing_tag tag with
    | true -> Printf.sprintf "<%s%s />" tag (attributes_to_string attributes)
    | false ->
        Printf.sprintf "<%s%s></%s>" tag (attributes_to_string attributes) tag
end

module ReactDOMServer = struct
  let renderToString _component = ""
end

let expect_msg = "should be equal"
let assert_string left right = (check string) expect_msg right left
let test_tag () = assert_string (React.createElement "div" []) "<div></div>"

let test_empty_attributes () =
  assert_string (React.createElement "div" [ ("", "") ]) "<div></div>"

let test_attributes () =
  assert_string
    (React.createElement "a" [ ("href", "google.html"); ("target", "_blank") ])
    "<a href=\"google.html\" target=\"_blank\"></a>"

let test_children () =
  assert_string (React.createElement "div" []) "<div></div>"

let test_closing_tag () =
  assert_string (React.createElement "input" []) "<input />"

let () =
  let open Alcotest in
  run "Test suit"
    [ ( "React"
      , [ test_case "div" `Quick test_tag
        ; test_case "empty attributes" `Quick test_empty_attributes
        ; test_case "attributes" `Quick test_attributes
        ; test_case "children" `Quick test_children
        ; test_case "self-closing tag" `Quick test_closing_tag
        ] )
    ; ("ReactDOMServer", [])
    ]
