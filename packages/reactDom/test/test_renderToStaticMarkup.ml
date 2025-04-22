let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let single_empty_tag () =
  let div = React.createElement "div" [] [] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div></div>"

let html_doctype () =
  let app = React.createElement "html" [] [] in
  assert_string (ReactDOM.renderToStaticMarkup app) "<!DOCTYPE html><html></html>"

let empty_string_attribute () =
  let div = React.createElement "div" [ React.JSX.String ("class", "className", "") ] [] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"\"></div>"

let string_attributes () =
  let a =
    React.createElement "a"
      [ React.JSX.String ("href", "href", "google.html"); React.JSX.String ("target", "target", "_blank") ]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup a) "<a href=\"google.html\" target=\"_blank\"></a>"

let bool_attributes () =
  let a =
    React.createElement "input"
      [
        React.JSX.String ("type", "type", "checkbox");
        React.JSX.String ("name", "name", "cheese");
        React.JSX.Bool ("checked", "checked", true);
        React.JSX.Bool ("disabled", "disabled", false);
      ]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup a) "<input type=\"checkbox\" name=\"cheese\" checked />"

let truthy_attributes () =
  let component = React.createElement "input" [ React.JSX.String ("aria-hidden", "ariaHidden", "true") ] [] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<input aria-hidden=\"true\" />"

let self_closing_tag () =
  let input = React.createElement "input" [] [] in
  assert_string (ReactDOM.renderToStaticMarkup input) "<input />"

let dom_element_innerHtml () =
  let p = React.createElement "p" [] [ React.string "text" ] in
  assert_string (ReactDOM.renderToStaticMarkup p) "<p>text</p>"

let children () =
  let children = React.createElement "div" [] [] in
  let div = React.createElement "div" [] [ children ] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div><div></div></div>"

let ignored_attributes_on_jsx () =
  let div =
    React.createElement "div"
      [
        React.JSX.String ("key", "key", "uniqueKeyId");
        React.JSX.Bool ("suppressContentEditableWarning", "suppressContentEditableWarning", true);
      ]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div></div>"

let fragment () =
  let div = React.createElement "div" [] [] in
  let component = React.fragment (React.list [ div; div ]) in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div></div><div></div>"

let ignore_nulls () =
  let div = React.createElement "div" [] [] in
  let span = React.createElement "span" [] [] in
  let component = React.createElement "div" [] [ div; span; React.null ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div><div></div><span></span></div>"

let fragments_and_texts () =
  let component =
    React.createElement "div" []
      [ React.fragment (React.list [ React.string "foo" ]); React.string "bar"; React.createElement "b" [] [] ]
  in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div>foobar<b></b></div>"

let lists_and_arrays () =
  let component =
    React.createElement "div" []
      [
        React.fragment (React.list [ React.string "This feels "; React.int 100 ]);
        React.createElement "br" [] [];
        React.fragment
          (React.array [| React.string "This doesn't "; React.string "feel right"; React.string " but it works." |]);
      ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div>This feels 100<br />This doesn&apos;t feel right but it works.</div>"

let inline_styles () =
  let component =
    React.createElement "button" [ React.JSX.style (ReactDOMStyle.make ~color:"red" ~border:"none" ()) ] []
  in
  assert_string (ReactDOM.renderToStaticMarkup component) "<button style=\"color:red;border:none\"></button>"

let encode_attributes () =
  let component =
    React.createElement "div"
      [
        React.JSX.String ("about", "about", "\' <");
        React.JSX.String ("data-user-path", "data-user-path", "what/the/path");
      ]
      [ React.string "& \"" ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div about=\"&apos; &lt;\" data-user-path=\"what/the/path\">&amp; &quot;</div>"

let dangerouslySetInnerHtml () =
  let component =
    React.createElement "script"
      [
        React.JSX.String ("type", "type", "application/javascript");
        React.JSX.DangerouslyInnerHtml "console.log(\"Hi!\")";
      ]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<script type=\"application/javascript\">console.log(\"Hi!\")</script>"

let context = React.createContext 10

module ContextProvider = struct
  include React.Context

  let make = React.Context.provider context
end

module ContextConsumer = struct
  let make () =
    let value = React.useContext context in
    React.createElement "section" [] [ React.int value ]
end

let context () =
  let component =
    React.Upper_case_component
      ( "component",
        fun () ->
          ContextProvider.make ~value:20
            ~children:(React.Upper_case_component ("context", fun () -> ContextConsumer.make ()))
            () )
  in
  assert_string (ReactDOM.renderToStaticMarkup component) "<section>20</section>"

let use_state () =
  let state, setState = React.useState (fun () -> "LOL") in

  let onClick _event = setState (fun _prev -> "OMG") in

  let component =
    React.createElement "div" []
      [
        React.createElement "button" [ React.JSX.Event ("onClick", Mouse onClick) ] [];
        React.createElement "span" [] [ React.string state ];
      ]
  in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div><button></button><span>LOL</span></div>"

let use_memo () =
  let memo = React.useMemo (fun () -> 23) in
  let component = React.createElement "header" [] [ React.int memo ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<header>23</header>"

let use_callback () =
  let memo = React.useCallback (fun () -> 23) in
  let component = React.createElement "header" [] [ React.int (memo ()) ] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<header>23</header>"

let inner_html () =
  let component = React.createElement "div" [ React.JSX.DangerouslyInnerHtml "foo" ] [] in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div>foo</div>"

let make ~name () =
  let onClick (event : React.Event.Mouse.t) : unit = ignore event in
  React.createElement "button"
    [
      React.JSX.String ("name", "name", (name : string));
      React.JSX.Event ("onClick", React.JSX.Mouse (onClick : React.Event.Mouse.t -> unit));
    ]
    []

let event () = assert_string (ReactDOM.renderToStaticMarkup (make ~name:"json" ())) "<button name=\"json\"></button>"

let className () =
  let div = React.createElement "div" [ React.JSX.String ("class", "className", "lol") ] [] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"lol\"></div>"

let className_2 () =
  let component =
    React.createElement "div" [ React.JSX.String ("class", "className", "flex xs:justify-center overflow-hidden") ] []
  in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div class=\"flex xs:justify-center overflow-hidden\"></div>"

let className_3 () =
  let component =
    React.fragment
      (React.list
         [
           React.createElement "div" [ React.JSX.String ("class", "className", "flex") ] [];
           React.createElement "div" (ReactDOM.domProps ~className:"flex" ()) [];
         ])
  in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div class=\"flex\"></div><div class=\"flex\"></div>"

let render_with_doc_type () =
  let div = React.createElement "div" [] [ React.createElement "span" [] [ React.string "This is valid HTML5" ] ] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div><span>This is valid HTML5</span></div>"

let dom_props_should_work () =
  let div = React.createElement "div" (ReactDOM.domProps ~key:"uniq" ~className:"mabutton" ()) [] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"mabutton\"></div>"

let render_svg () =
  let path =
    React.createElement "path"
      [
        React.JSX.String
          ( "d",
            "d",
            "M 5 3 C 3.9069372 3 3 3.9069372 3 5 L 3 19 C 3 20.093063 3.9069372 21 5 21 L 19 21 C 20.093063 21 21 \
             20.093063 21 19 L 21 12 L 19 12 L 19 19 L 5 19 L 5 5 L 12 5 L 12 3 L 5 3 z M 14 3 L 14 5 L 17.585938 5 L \
             8.2929688 14.292969 L 9.7070312 15.707031 L 19 6.4140625 L 19 10 L 21 10 L 21 3 L 14 3 z" );
      ]
      []
  in
  let svg =
    React.createElement "svg"
      [
        React.JSX.String ("xmlns", "xmlns", "http://www.w3.org/2000/svg");
        React.JSX.String ("viewBox", "viewBox", "0 0 24 24");
        React.JSX.String ("width", "width", "24px");
        React.JSX.String ("height", "height", "24px");
      ]
      [ path ]
  in
  assert_string (ReactDOM.renderToStaticMarkup svg)
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\" width=\"24px\" height=\"24px\"><path d=\"M 5 3 C \
     3.9069372 3 3 3.9069372 3 5 L 3 19 C 3 20.093063 3.9069372 21 5 21 L 19 21 C 20.093063 21 21 20.093063 21 19 L 21 \
     12 L 19 12 L 19 19 L 5 19 L 5 5 L 12 5 L 12 3 L 5 3 z M 14 3 L 14 5 L 17.585938 5 L 8.2929688 14.292969 L \
     9.7070312 15.707031 L 19 6.4140625 L 19 10 L 21 10 L 21 3 L 14 3 z\"></path></svg>"

(* TODO: add cases for React.Suspense
   function Button() {
      return <button>0</button>;
    }

    function SuspendedButton() {
      throw new Promise(() => {});
      return <button>0</button>;
    }


    ReactDOMServer.renderToString(
      <Suspense fallback={<p>This is a callback</p>}>
        <Button />
      </Suspense>
    );
    // <!--$--><button>0</button><!--/$-->


    ReactDOMServer.renderToString(
      <Suspense fallback={<p>This is a callback</p>}>
        <SuspendedButton />
      </Suspense>
    );
    // <!--$!--><p>This is a callback</p><!--/$-->
*)

let ref_as_callback_prop_works () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.createElement "span"
            [ React.JSX.Ref (ReactDOM.Ref.callbackDomRef (fun _ -> ())) ]
            [ React.string "yow" ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<span>yow</span>"

let ref_as_prop_works () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let tableRootRef = React.useRef Js.Nullable.null in
          React.createElement "span" [ React.JSX.Ref (ReactDOM.Ref.domRef tableRootRef) ] [ React.string "yow" ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<span>yow</span>"

let async_component () =
  let app = React.Async_component ("app", fun () -> Lwt.return (React.createElement "span" [] [ React.string "yow" ])) in
  let raises () =
    let _ = ReactDOM.renderToStaticMarkup app in
    ()
  in
  Alcotest.check_raises "Expected invalid argument"
    (Invalid_argument
       "Async components can't be rendered to static markup, since rendering is synchronous. Please use \
        `renderToStream` instead.")
    raises

let test title fn =
  (Printf.sprintf "ReactDOM.renderToStaticMarkup / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    test "html_doctype" html_doctype;
    test "single_empty_tag" single_empty_tag;
    test "empty_string_attribute" empty_string_attribute;
    test "bool_attributes" bool_attributes;
    test "truthy_attributes" truthy_attributes;
    test "ignore_nulls" ignore_nulls;
    test "string_attributes" string_attributes;
    test "self_closing_tag" self_closing_tag;
    test "dom_element_innerHtml" dom_element_innerHtml;
    test "children" children;
    test "className" className;
    test "className_2" className_2;
    test "className_3" className_3;
    test "fragment" fragment;
    test "fragments_and_texts" fragments_and_texts;
    test "ignored_attributes_on_jsx" ignored_attributes_on_jsx;
    test "inline_styles" inline_styles;
    test "encode_attributes" encode_attributes;
    test "dom_props_should_work" dom_props_should_work;
    test "dangerouslySetInnerHtml" dangerouslySetInnerHtml;
    test "context" context;
    test "use_state" use_state;
    test "use_memo" use_memo;
    test "use_callback" use_callback;
    test "inner_html" inner_html;
    test "event" event;
    test "render_with_doc_type" render_with_doc_type;
    test "render_svg" render_svg;
    test "ref_as_prop_works" ref_as_prop_works;
    test "ref_as_callback_prop_works" ref_as_callback_prop_works;
    test "async" async_component;
    test "lists_and_arrays" lists_and_arrays;
  ]
