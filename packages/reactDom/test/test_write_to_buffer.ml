let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let write element =
  let buf = Buffer.create 128 in
  ReactDOM.write_to_buffer buf element;
  Buffer.contents buf

let empty_element () = assert_string (write React.null) ""

let single_element () =
  let div = React.createElement "div" [] [] in
  assert_string (write div) "<div></div>"

let nested_elements () =
  let div = React.createElement "div" [] [ React.createElement "span" [] [] ] in
  assert_string (write div) "<div><span></span></div>"

let self_closing_tag () =
  let input = React.createElement "input" [] [] in
  assert_string (write input) "<input />"

let text_content () =
  let p = React.createElement "p" [] [ React.string "hello" ] in
  assert_string (write p) "<p>hello</p>"

let no_text_separators () =
  (* write_to_buffer should NOT add <!-- --> between consecutive text nodes *)
  let div = React.createElement "div" [] [ React.string "hello"; React.string "world" ] in
  assert_string (write div) "<div>helloworld</div>"

let no_doctype () =
  (* write_to_buffer should NOT inject <!DOCTYPE html> *)
  let html = React.createElement "html" [] [] in
  assert_string (write html) "<html></html>"

let string_attributes () =
  let a =
    React.createElement "a"
      [ React.JSX.String ("href", "href", "page.html"); React.JSX.String ("target", "target", "_blank") ]
      []
  in
  assert_string (write a) {|<a href="page.html" target="_blank"></a>|}

let bool_true_attribute () =
  let input = React.createElement "input" [ React.JSX.Bool ("checked", "checked", true) ] [] in
  assert_string (write input) "<input checked />"

let bool_false_attribute () =
  let input = React.createElement "input" [ React.JSX.Bool ("disabled", "disabled", false) ] [] in
  assert_string (write input) "<input />"

let style_attribute () =
  let div = React.createElement "div" [ React.JSX.style (ReactDOMStyle.make ~color:"red" ~border:"none" ()) ] [] in
  assert_string (write div) {|<div style="color:red;border:none"></div>|}

let html_escaping () =
  let div = React.createElement "div" [] [ React.string "a < b & c > d \"e\" 'f'" ] in
  assert_string (write div) "<div>a &lt; b &amp; c &gt; d &quot;e&quot; &apos;f&apos;</div>"

let attribute_escaping () =
  let div = React.createElement "div" [ React.JSX.String ("title", "title", "a < b & \"c\"") ] [] in
  assert_string (write div) {|<div title="a &lt; b &amp; &quot;c&quot;"></div>|}

let dangerously_set_inner_html () =
  let div = React.createElement "div" [ React.JSX.DangerouslyInnerHtml "<b>raw</b>" ] [] in
  assert_string (write div) "<div><b>raw</b></div>"

let fragment () =
  let component = React.fragment (React.list [ React.createElement "div" [] []; React.createElement "span" [] [] ]) in
  assert_string (write component) "<div></div><span></span>"

let list_children () =
  let div = React.createElement "div" [] [ React.list [ React.string "a"; React.string "b" ] ] in
  assert_string (write div) "<div>ab</div>"

let array_children () =
  let div = React.createElement "div" [] [ React.array [| React.string "x"; React.string "y" |] ] in
  assert_string (write div) "<div>xy</div>"

let upper_case_component () =
  let app = React.Upper_case_component ("app", fun () -> React.createElement "div" [] [ React.string "component" ]) in
  assert_string (write app) "<div>component</div>"

let suspense_success () =
  (* On success, write_to_buffer renders children without suspense markers *)
  let el =
    React.Suspense
      {
        key = None;
        children = React.createElement "div" [] [ React.string "ok" ];
        fallback = React.createElement "div" [] [ React.string "loading" ];
      }
  in
  assert_string (write el) "<div>ok</div>"

let suspense_fallback_on_error () =
  (* On error, write_to_buffer renders fallback without suspense markers *)
  let el =
    React.Suspense
      {
        key = None;
        children = React.Upper_case_component ("Throws", fun () -> raise (Failure "boom"));
        fallback = React.createElement "div" [] [ React.string "fallback" ];
      }
  in
  assert_string (write el) "<div>fallback</div>"

let static_element () =
  let original = React.createElement "div" [] [ React.string "Hello" ] in
  let app = React.Static { prerendered = "<div>Hello</div>"; original } in
  assert_string (write app) "<div>Hello</div>"

let event_attributes_ignored () =
  let onClick (_event : React.Event.Mouse.t) : unit = () in
  let button =
    React.createElement "button"
      [ React.JSX.String ("name", "name", "btn"); React.JSX.Event ("onClick", React.JSX.Mouse onClick) ]
      []
  in
  assert_string (write button) {|<button name="btn"></button>|}

let ref_attributes_ignored () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.createElement "span" [ React.JSX.Ref (ReactDOM.Ref.callbackDomRef (fun _ -> ())) ] [ React.string "hi" ]
      )
  in
  assert_string (write app) "<span>hi</span>"

let react_custom_attributes_ignored () =
  let div =
    React.createElement "div"
      [
        React.JSX.String ("key", "key", "k1");
        React.JSX.Bool ("suppressContentEditableWarning", "suppressContentEditableWarning", true);
        React.JSX.String ("class", "className", "test");
      ]
      []
  in
  assert_string (write div) {|<div class="test"></div>|}

let async_component_raises () =
  let app = React.Async_component ("app", fun () -> Lwt.return (React.createElement "span" [] [ React.string "hi" ])) in
  let raises () =
    let _result = write app in
    ()
  in
  Alcotest.check_raises "Expected invalid argument"
    (Invalid_argument "Async components can't be rendered synchronously via write_to_buffer.")
    raises

let context () =
  let ctx = React.createContext "default" in
  let provider = React.Context.provider ctx in
  let consumer () =
    let value = React.useContext ctx in
    React.createElement "span" [] [ React.string value ]
  in
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          provider
            (React.Context.makeProps ~value:"provided"
               ~children:(React.Upper_case_component ("consumer", fun () -> consumer ()))
               ()) )
  in
  assert_string (write app) "<span>provided</span>"

let test title fn = (Printf.sprintf "ReactDOM.write_to_buffer / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    test "empty element" empty_element;
    test "single element" single_element;
    test "nested elements" nested_elements;
    test "self-closing tag" self_closing_tag;
    test "text content" text_content;
    test "no text separators between consecutive text nodes" no_text_separators;
    test "no doctype injection for html tag" no_doctype;
    test "string attributes" string_attributes;
    test "bool true attribute" bool_true_attribute;
    test "bool false attribute" bool_false_attribute;
    test "style attribute" style_attribute;
    test "html escaping" html_escaping;
    test "attribute escaping" attribute_escaping;
    test "dangerouslySetInnerHTML" dangerously_set_inner_html;
    test "fragment" fragment;
    test "list children" list_children;
    test "array children" array_children;
    test "upper case component" upper_case_component;
    test "suspense success renders without markers" suspense_success;
    test "suspense fallback renders without markers" suspense_fallback_on_error;
    test "static element" static_element;
    test "event attributes ignored" event_attributes_ignored;
    test "ref attributes ignored" ref_attributes_ignored;
    test "react custom attributes ignored" react_custom_attributes_ignored;
    test "async component raises" async_component_raises;
    test "context" context;
  ]
