open Alcotest

module React = struct
  (* Self referencing modules to have recursive type records without collission *)
  module rec Element : sig
    type t =
      { tag : string
      ; attributes : Attribute.t list
      ; children : Node.t list
      }
  end =
    Element

  and Closed_element : sig
    type t =
      { tag : string
      ; attributes : Attribute.t list
      }
  end =
    Closed_element

  and Node : sig
    type t =
      | Element of Element.t
      | Closed_element of Closed_element.t
      | Text of string
  end =
    Node

  and Attribute : sig
    type t =
      | Bool of (string * bool)
      | String of (string * string)
  end =
    Attribute

  let is_self_closing_tag = function
    | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link"
    | "meta" | "param" | "source" | "track" | "wbr" ->
        true
    | _ -> false

  exception Invalid_children of string

  let createElement tag attributes children =
    match is_self_closing_tag tag with
    | true when List.length children > 0 ->
        raise @@ Invalid_children "closing tag with children isn't valid"
    | true -> Node.Closed_element { tag; attributes }
    | false -> Node.Element { tag; attributes; children }
end

module ReactDOMServer = struct
  open React

  let attribute_to_string attr =
    match attr with
    | Attribute.String (k, v) -> Printf.sprintf "%s=\"%s\"" k v
    | Bool (k, true) -> Printf.sprintf "%s" k
    | Bool (_, false) -> ""

  let attribute_is_empty = function
    | Attribute.String (k, v) -> v != "" || k != ""
    | Attribute.Bool (k, _) -> k != ""

  let attributes_to_string attrs =
    let attributes = List.filter attribute_is_empty attrs in
    match attributes with
    | [] -> ""
    | _ ->
        " "
        ^ (String.concat " " (attributes |> List.map attribute_to_string)
          |> String.trim)

  let rec renderToString (component : Node.t) =
    match component with
    | Text text -> text
    | Element { tag; attributes; children } ->
        let childrens =
          children |> List.map renderToString |> String.concat ""
        in
        Printf.sprintf "<%s%s>%s</%s>" tag
          (attributes_to_string attributes)
          childrens tag
    | Closed_element { tag; attributes } ->
        Printf.sprintf "<%s%s />" tag (attributes_to_string attributes)
end

(*
  ********************************************************
  *                    TESTS                             *
  ********************************************************
*)

let expect_msg = "should be equal"
let assert_string left right = (check string) expect_msg right left

let test_tag () =
  let div = React.createElement "div" [] [] in
  assert_string (ReactDOMServer.renderToString div) "<div></div>"

let test_empty_attributes () =
  let div = React.createElement "div" [ React.Attribute.String ("", "") ] [] in
  assert_string (ReactDOMServer.renderToString div) "<div></div>"

let test_attributes () =
  let a =
    React.createElement "a"
      [ React.Attribute.String ("href", "google.html")
      ; React.Attribute.String ("target", "_blank")
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToString a)
    "<a href=\"google.html\" target=\"_blank\"></a>"

let test_bool_attributes () =
  let a =
    React.createElement "input"
      [ React.Attribute.String ("type", "checkbox")
      ; React.Attribute.String ("name", "cheese")
      ; React.Attribute.Bool ("checked", true)
      ; React.Attribute.Bool ("disabled", false)
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToString a)
    "<input type=\"checkbox\" name=\"cheese\" checked />"

let test_closing_tag () =
  let input = React.createElement "input" [] [] in
  assert_string (ReactDOMServer.renderToString input) "<input />"

let test_innerhtml () =
  let p =
    React.createElement "p" [ React.Attribute.String ("children", "text") ] []
  in
  assert_string (ReactDOMServer.renderToString p) "<p>text</p>"

let test_children () =
  let children = React.createElement "div" [] [] in
  let div = React.createElement "div" [] [ children ] in
  assert_string (ReactDOMServer.renderToString div) "<div><div></div></div>"

let () =
  let open Alcotest in
  run "Tests"
    [ ( "ReactDOMServer"
      , [ test_case "div" `Quick test_tag
        ; test_case "empty attributes" `Quick test_empty_attributes
        ; test_case "bool attributes" `Quick test_bool_attributes
        ; test_case "attributes" `Quick test_attributes
        ; test_case "self-closing tag" `Quick test_closing_tag
        ; test_case "children" `Quick test_children
        ] )
    ]
