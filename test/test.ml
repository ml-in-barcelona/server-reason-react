open Alcotest

module React = struct
  type element =
    { tag : string
    ; attributes : (string * string) list
    ; children : element list
    }

  type closed_element =
    { tag : string
    ; attributes : (string * string) list
    }

  type node =
    | Element of element
    | Closed_element of closed_element
    | Text of string

  let is_self_closing_tag = function
    | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link"
    | "meta" | "param" | "source" | "track" | "wbr" ->
        true
    | _ -> false

  let createElement tag attributes children =
    match is_self_closing_tag tag with
    | false -> Element { tag; attributes; children }
    | true -> Closed_element { tag; attributes }
end

module ReactDOMServer = struct
  let attribute_to_string (k, v) = Printf.sprintf "%s=\"%s\"" k v

  let attributes_to_string attrs =
    let attributes = List.filter (fun (k, v) -> v != "" || k != "") attrs in
    match attributes with
    | [] -> ""
    | _ -> " " ^ String.concat " " (attributes |> List.map attribute_to_string)

  let renderToString node =
    match node with
    | React.Element { tag; attributes; _ } ->
        let children = "" in
        Printf.sprintf "<%s%s>%s</%s>" tag
          (attributes_to_string attributes)
          children tag
    | React.Closed_element { tag; attributes } ->
        Printf.sprintf "<%s%s />" tag (attributes_to_string attributes)
    | React.Text str -> Printf.sprintf "%s" str
end

let expect_msg = "should be equal"
let assert_string left right = (check string) expect_msg right left

let test_tag () =
  let div = React.createElement "div" [] [] in
  assert_string (ReactDOMServer.renderToString div) "<div></div>"

let test_empty_attributes () =
  let div = React.createElement "div" [ ("", "") ] [] in
  assert_string (ReactDOMServer.renderToString div) "<div></div>"

let test_attributes () =
  let a =
    React.createElement "a" [ ("href", "google.html"); ("target", "_blank") ] []
  in
  assert_string
    (ReactDOMServer.renderToString a)
    "<a href=\"google.html\" target=\"_blank\"></a>"

let test_closing_tag () =
  let input = React.createElement "input" [] [] in
  assert_string (ReactDOMServer.renderToString input) "<input />"

let test_innerhtml () =
  let p = React.createElement "p" [ ("children", "text") ] [] in
  assert_string (ReactDOMServer.renderToString p) "<p>text</p>"

let test_children () =
  let _children = React.createElement "div" [] [] in
  let div = React.createElement "div" [] [] in
  assert_string (ReactDOMServer.renderToString div) "<div></div>"

let () =
  let open Alcotest in
  run "Tests"
    [ ( "ReactDOMServer"
      , [ test_case "div" `Quick test_tag
        ; test_case "empty attributes" `Quick test_empty_attributes
        ; test_case "attributes" `Quick test_attributes
        ; test_case "self-closing tag" `Quick test_closing_tag
        ; test_case "children" `Quick test_children
        ] )
    ]
