open Alcotest
module React = Main.React
module ReactDOM = Main.ReactDOMServer

let assert_string left right = (check string) "should be equal" right left

let test_tag () =
  let div = React.createElement "div" [||] [] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div></div>"

let test_empty_attributes () =
  let div =
    React.createElement "div" [| React.Attribute.String ("", "") |] []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div></div>"

let test_empty_attribute () =
  let div =
    React.createElement "div" [| React.Attribute.String ("className", "") |] []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"\"></div>"

let test_attributes () =
  let a =
    React.createElement "a"
      [| React.Attribute.String ("href", "google.html")
       ; React.Attribute.String ("target", "_blank")
      |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup a)
    "<a href=\"google.html\" target=\"_blank\"></a>"

let test_bool_attributes () =
  let a =
    React.createElement "input"
      [| React.Attribute.String ("type", "checkbox")
       ; React.Attribute.String ("name", "cheese")
       ; React.Attribute.Bool ("checked", true)
       ; React.Attribute.Bool ("disabled", false)
      |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup a)
    "<input type=\"checkbox\" name=\"cheese\" checked />"

let test_closing_tag () =
  let input = React.createElement "input" [||] [] in
  assert_string (ReactDOM.renderToStaticMarkup input) "<input />"

let test_innerhtml () =
  let p = React.createElement "p" [||] [ React.string "text" ] in
  assert_string (ReactDOM.renderToStaticMarkup p) "<p>text</p>"

let test_children () =
  let children = React.createElement "div" [||] [] in
  let div = React.createElement "div" [||] [ children ] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div><div></div></div>"

let test_className () =
  let div =
    React.createElement "div"
      [| React.Attribute.String ("className", "lol") |]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"lol\"></div>"

let test_fragment () =
  let div = React.createElement "div" [||] [] in
  let component = React.Node.Fragment [ div; div ] in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div></div><div></div>"

let test_nulls () =
  let div = React.createElement "div" [||] [] in
  let span = React.createElement "span" [||] [] in
  let component = React.createElement "div" [||] [ div; span; React.null ] in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div><div></div><span></span></div>"

let test_fragments_and_texts () =
  let component =
    React.createElement "div" [||]
      [ React.Node.Fragment [ React.Node.Text "foo" ]
      ; React.Node.Text "bar"
      ; React.createElement "b" [||] []
      ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div>foobar<b></b></div>"

let test_default_value () =
  let component =
    React.createElement "input"
      [| React.Attribute.String ("defaultValue", "lol") |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<input value=\"lol\" />"

let test_inline_styles () =
  let component =
    React.createElement "button"
      [| React.Attribute.Style [ ("color", "red"); ("border", "none") ] |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<button style=\"color: red; border: none\"></button>"

let test_escape_attributes () =
  let component =
    React.createElement "div"
      [| React.Attribute.String ("a", "\' <") |]
      [ React.string "& \"" ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div a=\"&apos;&nbsp;&lt;\">&amp;&nbsp;&quot;</div>"

let test_clone_empty () =
  let component =
    React.createElement "div" [| React.Attribute.Bool ("hidden", true) |] []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    (ReactDOM.renderToStaticMarkup (React.cloneElement component [||] []))

let test_clone_attributes () =
  let component =
    React.createElement "div" [| React.Attribute.String ("val", "33") |] []
  in
  let expected =
    React.createElement "div"
      [| React.Attribute.String ("val", "31")
       ; React.Attribute.Bool ("lola", true)
      |]
      []
  in
  let cloned =
    React.cloneElement component
      [| React.Attribute.Bool ("lola", true)
       ; React.Attribute.String ("val", "31")
      |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup cloned)
    (ReactDOM.renderToStaticMarkup expected)

let test_clone_order_attributes () =
  let component = React.createElement "div" [||] [] in
  let expected =
    React.createElement "div"
      [| React.Attribute.String ("val", "31")
       ; React.Attribute.Bool ("lola", true)
      |]
      []
  in
  let cloned =
    React.cloneElement component
      [| React.Attribute.Bool ("lola", true)
       ; React.Attribute.String ("val", "31")
      |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup cloned)
    (ReactDOM.renderToStaticMarkup expected)

let test_context () =
  let context = React.createContext 10 in
  let component =
    context.provider ~value:20
      ~children:
        [ (fun () ->
            context.consumer ~children:(fun value ->
                [ React.createElement "section" [||] [ React.int value ] ]))
        ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<section>20</section>"

let test_use_state () =
  let state, _setState = React.useStateValue "LOL" in
  let component = React.createElement "section" [||] [ React.string state ] in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<section>LOL</section>"

let test_use_memo () =
  let memo = React.useMemo (fun () -> 23) in
  let component = React.createElement "header" [||] [ React.int memo ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<header>23</header>"

let test_use_callback () =
  let memo = React.useCallback (fun () -> 23) in
  let component = React.createElement "header" [||] [ React.int (memo ()) ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<header>23</header>"

let test_use_context () =
  let context = React.createContext 10 in
  let context_user () =
    let number = React.useContext context in
    React.createElement "section" [||] [ React.int number ]
  in
  let component = context.provider ~value:0 ~children:[ context_user ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<section>0</section>"

let test_two_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" ~fontSize:"24px" () in
  assert_string styles "background: #333; font-size: 24px"

let test_one_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" () in
  assert_string styles "background: #333"

let () =
  let open Alcotest in
  run "Tests"
    [ ( "renderToStaticMarkup"
      , [ test_case "div" `Quick test_tag
        ; test_case "empty attribute" `Quick test_empty_attribute
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
        ; test_case "useContext" `Quick test_use_context
        ; test_case "useState" `Quick test_use_state
        ; test_case "useMemo" `Quick test_use_memo
        ; test_case "useCallback" `Quick test_use_callback
        ] )
    ; ( (* FIXME: those test shouldn't rely on renderToStaticMarkup,
           make an alcotest TESTABLE component *)
        "React.cloneElement"
      , [ test_case "empty component" `Quick test_clone_empty
        ; test_case "attributes component" `Quick test_clone_attributes
        ; test_case "ordered attributes component" `Quick
            test_clone_order_attributes
        ] )
    ; ( "ReactDOM.Style.make"
      , [ test_case "generate one style" `Quick test_one_styles
        ; test_case "generate more than one style" `Quick test_two_styles
        ] )
    ]
