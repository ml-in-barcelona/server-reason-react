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
      | Fragment of t list
      | Empty (* is this needed? Only used in React.null *)
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

  (* ReasonReact APIs *)
  let string txt = Node.Text txt
  let null = Node.Empty
  let int i = Node.Text (string_of_int i)

  (* FIXME: float_of_string might be different on the browser *)
  let float f = Node.Text (string_of_float f)

  (*
    Fragments are Symbol[] in JavaScript and can be used as tags on createElement
    Such as React.createElement(React.Fragment, null, null), but they may contain childrens.
    We created a new "Node" constructor to represent this case. Check babel transformation for more details: https://babeljs.io/repl/#?browsers=defaults%2C%20not%20ie%2011%2C%20not%20ie_mob%2011&build=&builtIns=false&corejs=false&spec=false&loose=false&code_lz=DwJQpghgxgLgdAMQE4QOYFswDsYD4BQABIcAA64AyA9gDYTAD05-j408yamOuQA&debug=false&forceAllTransforms=false&shippedProposals=false&circleciRepo=&evaluate=false&fileSize=false&timeTravel=false&sourceType=module&lineWrap=true&presets=env%2Creact&prettier=true&targets=Node-18&version=7.19.0&externalPlugins=&assumptions=%7B%7D *)
  let fragment children = Node.Fragment children
end

module ReactDOMServer = struct
  open React

  let attribute_name_to_jsx k =
    match k with "className" -> "class" | "htmlFor" -> "for" | _ -> k

  let attribute_to_string attr =
    match attr with
    | Attribute.String (k, v) ->
        Printf.sprintf "%s=\"%s\"" (attribute_name_to_jsx k) v
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

  (* FIXME: Add link to source *)
  let react_root_attr_name = "data-reactroot"
  let data_react_root_attr = Printf.sprintf " %s=\"\"" react_root_attr_name

  (* is_root starts at true, and only goes to false when renders an element or closed element *)

  let renderToString (component : Node.t) =
    let is_root = ref true in
    let rec render_to_string_rec component =
      let root_attribute =
        match is_root.contents with true -> data_react_root_attr | false -> ""
      in
      match component with
      | Node.Empty -> ""
      | Fragment [] -> ""
      | Text text -> text
      | Fragment childs ->
          let childrens =
            childs |> List.map render_to_string_rec |> String.concat ""
          in
          Printf.sprintf "%s" childrens
      | Element { tag; attributes; children } ->
          is_root.contents <- false;
          let attributes = attributes_to_string attributes in
          let childrens =
            children |> List.map render_to_string_rec |> String.concat ""
          in
          Printf.sprintf "<%s%s%s>%s</%s>" tag root_attribute attributes
            childrens tag
      | Closed_element { tag; attributes } ->
          is_root.contents <- false;
          let attributes = attributes_to_string attributes in
          Printf.sprintf "<%s%s%s />" tag root_attribute attributes
    in
    render_to_string_rec component
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
  assert_string
    (ReactDOMServer.renderToString div)
    "<div data-reactroot=\"\"></div>"

let test_empty_attributes () =
  let div = React.createElement "div" [ React.Attribute.String ("", "") ] [] in
  assert_string
    (ReactDOMServer.renderToString div)
    "<div data-reactroot=\"\"></div>"

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
    "<a data-reactroot=\"\" href=\"google.html\" target=\"_blank\"></a>"

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
    "<input data-reactroot=\"\" type=\"checkbox\" name=\"cheese\" checked />"

let test_closing_tag () =
  let input = React.createElement "input" [] [] in
  assert_string
    (ReactDOMServer.renderToString input)
    "<input data-reactroot=\"\" />"

let test_innerhtml () =
  let p = React.createElement "p" [] [ React.string "text" ] in
  assert_string
    (ReactDOMServer.renderToString p)
    "<p data-reactroot=\"\">text</p>"

let test_children () =
  let children = React.createElement "div" [] [] in
  let div = React.createElement "div" [] [ children ] in
  assert_string
    (ReactDOMServer.renderToString div)
    "<div data-reactroot=\"\"><div></div></div>"

let test_className () =
  let div =
    React.createElement "div" [ React.Attribute.String ("className", "lol") ] []
  in
  assert_string
    (ReactDOMServer.renderToString div)
    "<div data-reactroot=\"\" class=\"lol\"></div>"

let test_fragment () =
  let div = React.createElement "div" [] [] in
  let component = React.fragment [ div; div ] in
  assert_string
    (ReactDOMServer.renderToString component)
    "<div data-reactroot=\"\"></div><div></div>"

let () =
  let open Alcotest in
  run "ReactDOMServer test suite"
    [ ( "renderToString"
      , [ test_case "div" `Quick test_tag
        ; test_case "empty attributes" `Quick test_empty_attributes
        ; test_case "bool attributes" `Quick test_bool_attributes
        ; test_case "attributes" `Quick test_attributes
        ; test_case "self-closing tag" `Quick test_closing_tag
        ; test_case "inner text" `Quick test_innerhtml
        ; test_case "children" `Quick test_children
        ; test_case "className -> class" `Quick test_className
        ; test_case "fragment" `Quick test_fragment
        ] )
    ]
