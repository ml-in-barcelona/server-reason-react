open Alcotest

module HTML = struct
  (* https://discuss.ocaml.org/t/html-encoding-of-string/4289/4 *)
  (* If problems http://projects.camlcity.org/projects/dl/ocamlnet-4.1.6/doc/html-main/Netencoding.Html.html *)
  let escape s =
    let add = Buffer.add_string in
    let len = String.length s in
    let b = Buffer.create len in
    let max_idx = len - 1 in
    let flush b start i =
      if start < len then Buffer.add_substring b s start (i - start)
    in
    let rec escape_inner start i =
      if i > max_idx then flush b start i
      else
        let next = i + 1 in
        match String.get s i with
        | '&' ->
            flush b start i;
            add b "&amp;";
            escape_inner next next
        | '<' ->
            flush b start i;
            add b "&lt;";
            escape_inner next next
        | '>' ->
            flush b start i;
            add b "&gt;";
            escape_inner next next
        | '\'' ->
            flush b start i;
            add b "&apos;";
            escape_inner next next
        | '\"' ->
            flush b start i;
            add b "&quot;";
            escape_inner next next
        | ' ' ->
            flush b start i;
            add b "&nbsp;";
            escape_inner next next
        | _ -> escape_inner start next
    in
    escape_inner 0 0 |> ignore;
    Buffer.contents b
end

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
    (* should we add here all Symbols from React? *)
    type t =
      | Element of Element.t
      | Closed_element of Closed_element.t
      | Text of string
      | Fragment of t list
      | Empty
      (* To support expressions as functions. Used in React.Context.Consumer *)
      (* How the f* I can type Function f being 'a -> 'b.
         Eventually It could be Function2 'a -> 'b -> 'c and Function3, etc *)
      (* Need to think where those are called as well *)
      | Function
      | Provider of ((unit -> unit) * t list)
      | Consumer of (unit -> t list)
  end =
    Node

  and Attribute : sig
    type t =
      | Bool of (string * bool)
      | String of (string * string)
      | Style of (string * string) list
    (* | Ref | DangerouslyInnerHtml *)
  end =
    Attribute

  let is_self_closing_tag = function
    | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link"
    | "meta" | "param" | "source" | "track" | "wbr" ->
        true
    | _ -> false

  exception Invalid_children of string

  let compare_styles left right =
    List.compare
      (fun (a, va) (b, vb) -> String.compare a b + String.compare va vb)
      left right

  let compare_attribute left right =
    let open Attribute in
    match (left, right) with
    | Bool (left_key, _), Bool (right_key, _) ->
        String.compare left_key right_key
    | String (left_key, _), String (right_key, _) ->
        String.compare left_key right_key
    | Style lstyles, Style rstyles -> compare_styles lstyles rstyles
    | _ -> 0

  let clone_attribute acc attr new_attr =
    let open Attribute in
    match (attr, new_attr) with
    | Bool (left, _), Bool (right, value) when left == right ->
        Bool (left, value) :: acc
    | String (left, _), String (right, value) when left == right ->
        String (left, value) :: acc
    | _ -> new_attr :: acc

  module StringMap = Map.Make (String)

  type attributes = Attribute.t StringMap.t

  let attributes_to_map attrs =
    List.fold_left
      (fun acc attr ->
        match attr with
        | Attribute.Bool (key, value) ->
            StringMap.add key (Attribute.Bool (key, value)) acc
        | Attribute.String (key, value) ->
            StringMap.add key (Attribute.String (key, value)) acc
        | Attribute.Style _ -> acc)
      StringMap.empty attrs

  let clone_attributes attributes new_attributes =
    let attribute_map = attributes_to_map attributes in
    let new_attribute_map = attributes_to_map new_attributes in
    StringMap.merge
      (fun _key attr new_attr ->
        match (attr, new_attr) with
        | Some attr, Some new_attr -> Some (clone_attribute [] attr new_attr)
        | Some attr, None -> Some [ attr ]
        | None, Some new_attr -> Some [ new_attr ]
        | None, None -> None)
      attribute_map new_attribute_map
    |> StringMap.bindings
    |> List.map (fun (_, attrs) -> attrs)
    |> List.flatten |> List.rev
    |> List.sort compare_attribute

  let createElement tag attributes children =
    match is_self_closing_tag tag with
    | true when List.length children > 0 ->
        (* TODO: Add test for this *)
        (* QUESTION: should raise or return monad? *)
        raise @@ Invalid_children "closing tag with children isn't valid"
    | true -> Node.Closed_element { tag; attributes }
    | false -> Node.Element { tag; attributes; children }

  (* cloneElements overrides childrens *)
  let cloneElement element new_attributes new_childrens =
    let open Node in
    match element with
    | Element { tag; attributes; children = _ } ->
        Element
          { tag
          ; attributes = clone_attributes attributes new_attributes
          ; children = new_childrens
          }
    | Closed_element { tag; attributes } ->
        Closed_element
          { tag; attributes = clone_attributes attributes new_attributes }
    | Fragment _childrens -> Fragment new_childrens
    | Text t -> Text t
    | Empty -> Empty
    (* How does context nodes on cloneElement? *)
    | Function -> Function
    | Provider child -> Provider child
    | Consumer child -> Consumer child

  type 'a context =
    { provider : value:'a -> children:Node.t list -> Node.t
    ; consumer : children:('a -> Node.t list) -> Node.t
    }

  (* Maybe its wrong *)
  let createContext (initial_value : 'a) : 'a context =
    let ref_value = ref initial_value in
    { provider =
        (fun ~value ~children ->
          Node.Provider ((fun () -> ref_value.contents <- value), children))
    ; consumer =
        (fun ~children -> Node.Consumer (fun () -> children ref_value.contents))
    }

  (*
    Fragments are Symbol[] in JavaScript and can be used as tags on createElement
    Such as React.createElement(React.Fragment, null, null), but they may contain childrens.
    We created a new "Node" constructor to represent this case. Check babel transformation for more details: https://babeljs.io/repl/#?browsers=defaults%2C%20not%20ie%2011%2C%20not%20ie_mob%2011&build=&builtIns=false&corejs=false&spec=false&loose=false&code_lz=DwJQpghgxgLgdAMQE4QOYFswDsYD4BQABIcAA64AyA9gDYTAD05-j408yamOuQA&debug=false&forceAllTransforms=false&shippedProposals=false&circleciRepo=&evaluate=false&fileSize=false&timeTravel=false&sourceType=module&lineWrap=true&presets=env%2Creact&prettier=true&targets=Node-18&version=7.19.0&externalPlugins=&assumptions=%7B%7D *)
  let fragment children = Node.Fragment children

  (* ReasonReact APIs *)
  let string txt = Node.Text txt
  let null = Node.Empty
  let int i = Node.Text (string_of_int i)

  (* FIXME: float_of_string might be different on the browser *)
  let float f = Node.Text (string_of_float f)
end

module ReactDOMServer = struct
  open React

  let attribute_name_to_jsx k =
    match k with
    | "className" -> "class"
    | "htmlFor" -> "for"
    (* serialize defaultX props to the X attribute *)
    (* FIXME: Add link *)
    | "defaultValue" -> "value"
    | "defaultChecked" -> "checked"
    | "defaultSelected" -> "selected"
    | _ -> k

  let styles_to_string styles =
    styles
    |> List.map (fun (k, v) -> k ^ ": " ^ String.trim v)
    |> String.concat "; "

  (* FIXME: We don't have any way to test Ref, since Ref constructor isn't
     available due to the unknown of their type *)
  (* This list can go long!? *)
  let attribute_is_not_html = function "ref" -> true | _ -> false

  let attribute_to_string attr =
    let open Attribute in
    match attr with
    (* false attributes don't get rendered *)
    | Bool (_, false) -> ""
    | Bool (k, true) -> Printf.sprintf "%s" k
    | Style styles -> Printf.sprintf "style=\"%s\"" (styles_to_string styles)
    | String (k, _) when attribute_is_not_html k -> ""
    | String (k, v) ->
        Printf.sprintf "%s=\"%s\"" (attribute_name_to_jsx k) (HTML.escape v)

  let attribute_is_not_empty = function
    | Attribute.String (k, _v) -> k != ""
    | Bool (k, _) -> k != ""
    | Style styles -> List.length styles != 0

  (* FIXME: Remove empty style attributes or class *)
  let attribute_is_not_valid = attribute_is_not_empty

  let attributes_to_string attrs =
    let attributes = List.filter attribute_is_not_valid attrs in
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
  let renderToStaticMarkup (component : Node.t) =
    let is_root = ref true in
    let rec render_to_string_inner component =
      let root_attribute =
        match is_root.contents with true -> data_react_root_attr | false -> ""
      in
      match component with
      | Node.Empty -> ""
      | Fragment [] -> ""
      (* If function contains a fn as payload. Should this run on renderToStaticMarkup? *)
      | Function -> ""
      | Text text -> HTML.escape text
      | Provider (set_context, children) ->
          (* We set the context on renderToStaticMarkup *)
          print_endline "render prov";
          set_context ();
          children |> List.map render_to_string_inner |> String.concat ""
      | Consumer children ->
          print_endline "render consu";
          children () |> List.map render_to_string_inner |> String.concat ""
      | Fragment children ->
          let stringed_childs =
            children |> List.map render_to_string_inner |> String.concat ""
          in
          Printf.sprintf "%s" stringed_childs
      | Element { tag; attributes; children } ->
          is_root.contents <- false;
          let attributes = attributes_to_string attributes in
          let childrens =
            children |> List.map render_to_string_inner |> String.concat ""
          in
          Printf.sprintf "<%s%s%s>%s</%s>" tag root_attribute attributes
            childrens tag
      | Closed_element { tag; attributes } ->
          is_root.contents <- false;
          let attributes = attributes_to_string attributes in
          Printf.sprintf "<%s%s%s />" tag root_attribute attributes
    in
    render_to_string_inner component
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
    (ReactDOMServer.renderToStaticMarkup div)
    "<div data-reactroot=\"\"></div>"

let test_empty_attributes () =
  let div = React.createElement "div" [ React.Attribute.String ("", "") ] [] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup div)
    "<div data-reactroot=\"\"></div>"

let test_empty_attribute () =
  let div =
    React.createElement "div" [ React.Attribute.String ("className", "") ] []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup div)
    "<div data-reactroot=\"\" class=\"\"></div>"

let test_attributes () =
  let a =
    React.createElement "a"
      [ React.Attribute.String ("href", "google.html")
      ; React.Attribute.String ("target", "_blank")
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup a)
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
    (ReactDOMServer.renderToStaticMarkup a)
    "<input data-reactroot=\"\" type=\"checkbox\" name=\"cheese\" checked />"

let test_closing_tag () =
  let input = React.createElement "input" [] [] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup input)
    "<input data-reactroot=\"\" />"

let test_innerhtml () =
  let p = React.createElement "p" [] [ React.string "text" ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup p)
    "<p data-reactroot=\"\">text</p>"

let test_children () =
  let children = React.createElement "div" [] [] in
  let div = React.createElement "div" [] [ children ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup div)
    "<div data-reactroot=\"\"><div></div></div>"

let test_className () =
  let div =
    React.createElement "div" [ React.Attribute.String ("className", "lol") ] []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup div)
    "<div data-reactroot=\"\" class=\"lol\"></div>"

let test_fragment () =
  let div = React.createElement "div" [] [] in
  let component = React.fragment [ div; div ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<div data-reactroot=\"\"></div><div></div>"

let test_nulls () =
  let div = React.createElement "div" [] [] in
  let span = React.createElement "span" [] [] in
  let component = React.createElement "div" [] [ div; span; React.null ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<div data-reactroot=\"\"><div></div><span></span></div>"

let test_fragments_and_texts () =
  let component =
    React.createElement "div" []
      [ React.fragment [ React.Node.Text "foo" ]
      ; React.Node.Text "bar"
      ; React.createElement "b" [] []
      ]
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<div data-reactroot=\"\">foobar<b></b></div>"

let test_default_value () =
  let component =
    React.createElement "input"
      [ React.Attribute.String ("defaultValue", "lol") ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<input data-reactroot=\"\" value=\"lol\" />"

let test_inline_styles () =
  let component =
    React.createElement "button"
      [ React.Attribute.Style [ ("color", "red"); ("border", "none") ] ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<button data-reactroot=\"\" style=\"color: red; border: none\"></button>"

let test_escape_attributes () =
  let component =
    React.createElement "div"
      [ React.Attribute.String ("a", "\' <") ]
      [ React.string "& \"" ]
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<div data-reactroot=\"\" a=\"&apos;&nbsp;&lt;\">&amp;&nbsp;&quot;</div>"

let test_clone_empty () =
  let component =
    React.createElement "div" [ React.Attribute.String ("val", "33") ] []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    (ReactDOMServer.renderToStaticMarkup (React.cloneElement component [] []))

let test_clone_attributes () =
  let component =
    React.createElement "div" [ React.Attribute.String ("val", "33") ] []
  in
  let expected =
    React.createElement "div"
      [ React.Attribute.String ("val", "31")
      ; React.Attribute.Bool ("lola", true)
      ]
      []
  in
  let cloned =
    React.cloneElement component
      [ React.Attribute.Bool ("lola", true)
      ; React.Attribute.String ("val", "31")
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup cloned)
    (ReactDOMServer.renderToStaticMarkup expected)

let test_clone_order_attributes () =
  let component = React.createElement "div" [] [] in
  let expected =
    React.createElement "div"
      [ React.Attribute.String ("val", "31")
      ; React.Attribute.Bool ("lola", true)
      ]
      []
  in
  let cloned =
    React.cloneElement component
      [ React.Attribute.Bool ("lola", true)
      ; React.Attribute.String ("val", "31")
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup cloned)
    (ReactDOMServer.renderToStaticMarkup expected)

let test_context () =
  let context = React.createContext 10 in
  let component =
    context.provider ~value:20
      ~children:
        [ context.consumer ~children:(fun value ->
              [ React.createElement "section" [] [ React.int value ] ])
        ]
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<section data-reactroot=\"\">20</section>"

let () =
  let open Alcotest in
  run "Tests"
    [ ( "ReactDOMServer.renderToStaticMarkup"
      , [ test_case "div" `Quick test_tag
        ; test_case "empty attribute" `Quick test_empty_attribute
        ; test_case "empty attributes" `Quick test_empty_attributes
        ; test_case "bool attributes" `Quick test_bool_attributes
        ; test_case "ignore nulls" `Quick test_nulls
        ; test_case "attributes" `Quick test_attributes
        ; test_case "self-closing tag" `Quick test_closing_tag
        ; test_case "inner text" `Quick test_innerhtml
        ; test_case "children" `Quick test_children
        ; test_case "className turns into class" `Quick test_className
        ; test_case "fragment is empty" `Quick test_fragment
        ; test_case "fragment and text concat nicely" `Quick
            test_fragments_and_texts
        ; test_case "defaultValue should be value" `Quick test_default_value
        ; test_case "inline styles" `Quick test_inline_styles
        ; test_case "escape HTML attributes" `Quick test_escape_attributes
        ; test_case "createContext" `Quick test_context
        ] )
    ; ( (* FIXME: those test shouldn't rely on renderToStaticMarkup, make a TESTABLE component*)
        "React.cloneElement"
      , [ test_case "empty component" `Quick test_clone_empty
        ; test_case "attributes component" `Quick test_clone_attributes
        ; test_case "ordered attributes component" `Quick
            test_clone_order_attributes
        ] )
    ]
