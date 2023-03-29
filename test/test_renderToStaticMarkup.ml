let assert_string left right =
  (Alcotest.check Alcotest.string) "should be equal" right left

let tag () =
  let div = React.createElement "div" [||] [] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div></div>"

let empty_attribute () =
  let div =
    React.createElement "div" [| React.Attribute.String ("className", "") |] []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"\"></div>"

let attributes () =
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

let bool_attributes () =
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

let closing_tag () =
  let input = React.createElement "input" [||] [] in
  assert_string (ReactDOM.renderToStaticMarkup input) "<input />"

let innerhtml () =
  let p = React.createElement "p" [||] [ React.string "text" ] in
  assert_string (ReactDOM.renderToStaticMarkup p) "<p>text</p>"

let children () =
  let children = React.createElement "div" [||] [] in
  let div = React.createElement "div" [||] [ children ] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div><div></div></div>"

let ignored_attributes_on_jsx () =
  let div =
    React.createElement "div"
      [| React.Attribute.String ("key", "uniqueKeyId")
       ; React.Attribute.String ("wat", "randomAttributeThatShouldBeIgnored")
       ; React.Attribute.Bool ("suppressContentEditableWarning", true)
      |]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div></div>"

let className () =
  let div =
    React.createElement "div"
      [| React.Attribute.String ("className", "lol") |]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"lol\"></div>"

let fragment () =
  let div = React.createElement "div" [||] [] in
  let component = React.Element.Fragment [ div; div ] in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div></div><div></div>"

let nulls () =
  let div = React.createElement "div" [||] [] in
  let span = React.createElement "span" [||] [] in
  let component = React.createElement "div" [||] [ div; span; React.null ] in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div><div></div><span></span></div>"

let fragments_and_texts () =
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

let default_value () =
  let component =
    React.createElement "input"
      [| React.Attribute.String ("defaultValue", "lol") |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<input value=\"lol\" />"

let inline_styles () =
  let component =
    React.createElement "button"
      [| React.Attribute.Style "color: red; border: none" |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<button style=\"color: red; border: none\"></button>"

let encode_attributes () =
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

let dangerouslySetInnerHtml () =
  let component =
    React.createElement "script"
      [| React.Attribute.String ("type", "application/javascript")
       ; React.Attribute.DangerouslyInnerHtml "console.log(\"Hi!\")"
      |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<script type=\"application/javascript\">console.log(\"Hi!\")</script>"

let context () =
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

let use_state () =
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

let use_memo () =
  let memo = React.useMemo (fun () -> 23) in
  let component = React.createElement "header" [||] [ React.int memo ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<header>23</header>"

let use_callback () =
  let memo = React.useCallback (fun () -> 23) in
  let component = React.createElement "header" [||] [ React.int (memo ()) ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<header>23</header>"

let inner_html () =
  let component =
    React.createElement "div"
      [| React.Attribute.DangerouslyInnerHtml "foo" |]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div>foo</div>"

let use_context () =
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

let event () =
  assert_string
    (ReactDOM.renderToStaticMarkup (make ~name:"json" ()))
    "<button name=\"json\"></button>"

let className_2 () =
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

let _onclick_render_as_string () =
  let component =
    React.createElement "div"
      [| React.Attribute.Event ("_onclick", Inline "$(this).hide()") |]
      []
  in

  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div onclick=\"$(this).hide()\"></div>"

let render_with_doc_type () =
  let div =
    React.createElement "div" [||]
      [ React.createElement "span" [||] [ React.string "This is valid HTML5" ] ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup ~docType:ReactDOM.HTML5 div)
    "<!DOCTYPE html><div><span>This is valid HTML5</span></div>"

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( "renderToStaticMarkup"
  , [ case "div" tag
    ; case "empty attribute" empty_attribute
    ; case "bool attributes" bool_attributes
    ; case "ignore nulls" nulls
    ; case "attributes" attributes
    ; case "self-closing tag" closing_tag
    ; case "inner text" innerhtml
    ; case "children" children
    ; case "className turns into class" className
    ; case "test_className" className_2
    ; case "fragment is empty" fragment
    ; case "fragment and text concat nicely" fragments_and_texts
    ; case "defaultValue should be value" default_value
    ; case "attributes that gets ignored" ignored_attributes_on_jsx
    ; case "inline styles" inline_styles
    ; case "escape HTML attributes" encode_attributes
    ; case "innerHTML" dangerouslySetInnerHtml
    ; case "createContext" context
    ; case "useContext" use_context
    ; case "useState" use_state
    ; case "useMemo" use_memo
    ; case "useCallback" use_callback
    ; case "innerHtml" inner_html
    ; case "events" event
    ; case "_onclick" _onclick_render_as_string
    ; case "!DOCTYPE" render_with_doc_type
    ] )
