open Alcotest

let assert_string left right = (check string) "should be equal" right left

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

let tests =
  ( (* FIXME: those test shouldn't rely on renderToStaticMarkup,
       make an alcotest TESTABLE component *)
    "React.cloneElement"
  , [ test_case "empty component" `Quick test_clone_empty
    ; test_case "attributes component" `Quick test_clone_attributes
    ; test_case "ordered attributes component" `Quick
        test_clone_order_attributes
    ] )
