open Alcotest

let assert_string left right = (check string) "should be equal" right left

let test_tag () =
  let div = React.createElement "div" [||] [] in
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

let test_ignored_attributes_on_jsx () =
  let div =
    React.createElement "div"
      [| React.Attribute.String ("key", "uniqueKeyId")
       ; React.Attribute.String ("wat", "randomAttributeThatShouldBeIgnored")
       ; React.Attribute.Bool ("suppressContentEditableWarning", true)
      |]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div></div>"

let test_className () =
  let div =
    React.createElement "div"
      [| React.Attribute.String ("className", "lol") |]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"lol\"></div>"

let test_fragment () =
  let div = React.createElement "div" [||] [] in
  let component = React.Element.Fragment [ div; div ] in
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
      [ React.Element.Fragment [ React.string "foo" ]
      ; React.string "bar"
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
      [| React.Attribute.Style "color: red; border: none" |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<button style=\"color: red; border: none\"></button>"

let test_encode_attributes () =
  let component =
    React.createElement "div"
      [| React.Attribute.String ("about", "\' <")
       ; React.Attribute.String ("data-user-path", "what/the/path")
      |]
      [ React.string "& \"" ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div about=\"&#x27; &lt;\" data-user-path=\"what/the/path\">&amp; \
     &quot;</div>"

let test_dangerouslySetInnerHtml () =
  let component =
    React.createElement "script"
      [| React.Attribute.String ("type", "application/javascript")
         (* ; React.Attribute.DangerouslyInnerHtml (React.makeDangerouslySetInnerHTML "console.log(\"Hi!\")") *)
      |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div type=\"application/javascript\">console.log(\"Hi!\")</div>"

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
  let state, setState = React.useState (fun () -> "LOL") in

  let onClick _event = setState (fun _prev -> "OMG") in

  let component =
    React.createElement "div" [||]
      [ React.createElement "button"
          [| React.Attribute.Event ("onClick", Mouse onClick) |]
          []
      ; React.createElement "span" [||] [ React.string state ]
      ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div><button></button><span>LOL</span></div>"

let test_use_memo () =
  let memo = React.useMemo (fun () -> 23) in
  let component = React.createElement "header" [||] [ React.int memo ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<header>23</header>"

let test_use_callback () =
  let memo = React.useCallback (fun () -> 23) in
  let component = React.createElement "header" [||] [ React.int (memo ()) ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<header>23</header>"

let test_inner_html () =
  let component =
    React.createElement "div"
      [| React.Attribute.DangerouslyInnerHtml "foo" |]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div>foo</div>"

let test_use_context () =
  let context = React.createContext 10 in
  let context_user () =
    let number = React.useContext context in
    React.createElement "section" [||] [ React.int number ]
  in
  let component = context.provider ~value:0 ~children:[ context_user ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<section>0</section>"

let make ~name () =
  let onClick (event : ReactEvent.Mouse.t) : unit = ignore event in
  React.createElement "button"
    ([| Some (React.Attribute.String ("name", (name : string)))
      ; Some
          (React.Attribute.Event
             ("event", React.EventT.Mouse (onClick : ReactEvent.Mouse.t -> unit)))
     |]
    |> Array.to_list
    |> List.filter_map (fun a -> a)
    |> Array.of_list)
    []

let test_event () =
  assert_string
    (ReactDOM.renderToStaticMarkup (make ~name:"json" ()))
    "<button name=\"json\"></button>"

let test_className_2 () =
  let component =
    React.createElement "div"
      [| React.Attribute.String
           ("className", "flex xs:justify-center overflow-hidden")
      |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div class=\"flex xs:justify-center overflow-hidden\"></div>"

let tests =
  ( "renderToStaticMarkup"
  , [ test_case "div" `Quick test_tag
    ; test_case "empty attribute" `Quick test_empty_attribute
    ; test_case "bool attributes" `Quick test_bool_attributes
    ; test_case "ignore nulls" `Quick test_nulls
    ; test_case "attributes" `Quick test_attributes
    ; test_case "self-closing tag" `Quick test_closing_tag
    ; test_case "inner text" `Quick test_innerhtml
    ; test_case "children" `Quick test_children
    ; test_case "className turns into class" `Quick test_className
    ; test_case "test_className" `Quick test_className_2
    ; test_case "fragment is empty" `Quick test_fragment
    ; test_case "fragment and text concat nicely" `Quick
        test_fragments_and_texts
    ; test_case "defaultValue should be value" `Quick test_default_value
    ; test_case "attributes that gets ignored" `Quick
        test_ignored_attributes_on_jsx
    ; test_case "inline styles" `Quick test_inline_styles
    ; test_case "escape HTML attributes" `Quick test_encode_attributes
    ; test_case "innerHTML" `Quick test_dangerouslySetInnerHtml
    ; test_case "createContext" `Quick test_context
    ; test_case "useContext" `Quick test_use_context
    ; test_case "useState" `Quick test_use_state
    ; test_case "useMemo" `Quick test_use_memo
    ; test_case "useCallback" `Quick test_use_callback
    ; test_case "innerHtml" `Quick test_inner_html
    ; test_case "events" `Quick test_event
    ] )
