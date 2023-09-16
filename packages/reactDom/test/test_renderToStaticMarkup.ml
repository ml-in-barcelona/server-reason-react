let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let single_empty_tag () =
  let div = React.createElement "div" [||] [] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div></div>"

let empty_string_attribute () =
  let div = React.createElement "div" [| React.JSX.String ("class", "") |] [] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"\"></div>"

let string_attributes () =
  let a =
    React.createElement "a"
      [|
        React.JSX.String ("href", "google.html");
        React.JSX.String ("target", "_blank");
      |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup a)
    "<a href=\"google.html\" target=\"_blank\"></a>"

let bool_attributes () =
  let a =
    React.createElement "input"
      [|
        React.JSX.String ("type", "checkbox");
        React.JSX.String ("name", "cheese");
        React.JSX.Bool ("checked", true);
        React.JSX.Bool ("disabled", false);
      |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup a)
    "<input type=\"checkbox\" name=\"cheese\" checked />"

let truthy_attributes () =
  let component =
    React.createElement "input"
      [| React.JSX.String ("aria-hidden", "true") |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<input aria-hidden=\"true\" />"

let self_closing_tag () =
  let input = React.createElement "input" [||] [] in
  assert_string (ReactDOM.renderToStaticMarkup input) "<input />"

let dom_element_innerHtml () =
  let p = React.createElement "p" [||] [ React.string "text" ] in
  assert_string (ReactDOM.renderToStaticMarkup p) "<p>text</p>"

let children () =
  let children = React.createElement "div" [||] [] in
  let div = React.createElement "div" [||] [ children ] in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div><div></div></div>"

let ignored_attributes_on_jsx () =
  let div =
    React.createElement "div"
      [|
        React.JSX.String ("key", "uniqueKeyId");
        React.JSX.Bool ("suppressContentEditableWarning", true);
      |]
      []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div></div>"

let fragment () =
  let div = React.createElement "div" [||] [] in
  let component = React.fragment ~children:(React.list [ div; div ]) () in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div></div><div></div>"

let ignore_nulls () =
  let div = React.createElement "div" [||] [] in
  let span = React.createElement "span" [||] [] in
  let component = React.createElement "div" [||] [ div; span; React.null ] in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div><div></div><span></span></div>"

let fragments_and_texts () =
  let component =
    React.createElement "div" [||]
      [
        React.fragment ~children:(React.list [ React.string "foo" ]) ();
        React.string "bar";
        React.createElement "b" [||] [];
      ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div>foobar<b></b></div>"

let inline_styles () =
  let component =
    React.createElement "button"
      [| React.JSX.Style "color: red; border: none" |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<button style=\"color: red; border: none\"></button>"

let encode_attributes () =
  let component =
    React.createElement "div"
      [|
        React.JSX.String ("about", "\' <");
        React.JSX.String ("data-user-path", "what/the/path");
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
      [|
        React.JSX.String ("type", "application/javascript");
        React.JSX.DangerouslyInnerHtml "console.log(\"Hi!\")";
      |]
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
    React.createElement "section" [||] [ React.int value ]
end

let context () =
  let component =
    React.Upper_case_component
      (fun () ->
        ContextProvider.make ~value:20
          ~children:
            (React.Upper_case_component (fun () -> ContextConsumer.make ()))
          ())
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<section>20</section>"

let use_state () =
  let state, setState = React.useState (fun () -> "LOL") in

  let onClick _event = setState (fun _prev -> "OMG") in

  let component =
    React.createElement "div" [||]
      [
        React.createElement "button"
          [| React.JSX.Event ("onClick", Mouse onClick) |]
          [];
        React.createElement "span" [||] [ React.string state ];
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
    React.createElement "div" [| React.JSX.DangerouslyInnerHtml "foo" |] []
  in
  assert_string (ReactDOM.renderToStaticMarkup component) "<div>foo</div>"

let make ~name () =
  let onClick (event : ReactEvent.Mouse.t) : unit = ignore event in
  React.createElement "button"
    ([|
       Some (React.JSX.String ("name", (name : string)));
       Some
         (React.JSX.Event
            ( "event",
              React.JSX.Event.Mouse (onClick : ReactEvent.Mouse.t -> unit) ));
     |]
    |> Array.to_list
    |> List.filter_map (fun a -> a)
    |> Array.of_list)
    []

let event () =
  assert_string
    (ReactDOM.renderToStaticMarkup (make ~name:"json" ()))
    "<button name=\"json\"></button>"

let className () =
  let div =
    React.createElement "div" [| React.JSX.String ("class", "lol") |] []
  in
  assert_string (ReactDOM.renderToStaticMarkup div) "<div class=\"lol\"></div>"

let className_2 () =
  let component =
    React.createElement "div"
      [| React.JSX.String ("class", "flex xs:justify-center overflow-hidden") |]
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup component)
    "<div class=\"flex xs:justify-center overflow-hidden\"></div>"

let _onclick_render_as_string () =
  let component =
    React.createElement "div"
      [| React.JSX.Event ("_onclick", Inline "$(this).hide()") |]
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
    (ReactDOM.renderToStaticMarkup div)
    "<div><span>This is valid HTML5</span></div>"

let dom_props_should_work () =
  let div =
    React.createElement "div"
      (ReactDOM.domProps ~key:"uniq" ~className:"mabutton" ())
      []
  in
  assert_string
    (ReactDOM.renderToStaticMarkup div)
    "<div class=\"mabutton\"></div>"

let render_svg () =
  let path =
    React.createElement "path"
      [|
        React.JSX.String
          ( "d",
            "M 5 3 C 3.9069372 3 3 3.9069372 3 5 L 3 19 C 3 20.093063 \
             3.9069372 21 5 21 L 19 21 C 20.093063 21 21 20.093063 21 19 L 21 \
             12 L 19 12 L 19 19 L 5 19 L 5 5 L 12 5 L 12 3 L 5 3 z M 14 3 L 14 \
             5 L 17.585938 5 L 8.2929688 14.292969 L 9.7070312 15.707031 L 19 \
             6.4140625 L 19 10 L 21 10 L 21 3 L 14 3 z" );
      |]
      []
  in
  let svg =
    React.createElement "svg"
      [|
        React.JSX.String ("xmlns", "http://www.w3.org/2000/svg");
        React.JSX.String ("viewBox", "0 0 24 24");
        React.JSX.String ("width", "24px");
        React.JSX.String ("height", "24px");
      |]
      [ path ]
  in
  assert_string
    (ReactDOM.renderToStaticMarkup svg)
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\" \
     width=\"24px\" height=\"24px\"><path d=\"M 5 3 C 3.9069372 3 3 3.9069372 \
     3 5 L 3 19 C 3 20.093063 3.9069372 21 5 21 L 19 21 C 20.093063 21 21 \
     20.093063 21 19 L 21 12 L 19 12 L 19 19 L 5 19 L 5 5 L 12 5 L 12 3 L 5 3 \
     z M 14 3 L 14 5 L 17.585938 5 L 8.2929688 14.292969 L 9.7070312 15.707031 \
     L 19 6.4140625 L 19 10 L 21 10 L 21 3 L 14 3 z\"></path></svg>"

let case title fn = Alcotest_lwt.test_case_sync title `Quick fn

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

let tests =
  ( "renderToStaticMarkup",
    [
      case "single_empty_tag" single_empty_tag;
      case "empty_string_attribute" empty_string_attribute;
      case "bool_attributes" bool_attributes;
      case "truthy_attributes" truthy_attributes;
      case "ignore_nulls" ignore_nulls;
      case "string_attributes" string_attributes;
      case "self_closing_tag" self_closing_tag;
      case "dom_element_innerHtml" dom_element_innerHtml;
      case "children" children;
      case "className" className;
      case "className_2" className_2;
      case "fragment" fragment;
      case "fragments_and_texts" fragments_and_texts;
      case "ignored_attributes_on_jsx" ignored_attributes_on_jsx;
      case "inline_styles" inline_styles;
      case "encode_attributes" encode_attributes;
      case "dom_props_should_work" dom_props_should_work;
      case "dangerouslySetInnerHtml" dangerouslySetInnerHtml;
      case "context" context;
      case "use_state" use_state;
      case "use_memo" use_memo;
      case "use_callback" use_callback;
      case "inner_html" inner_html;
      case "event" event;
      case "_onclick_render_as_string" _onclick_render_as_string;
      case "render_with_doc_type" render_with_doc_type;
      case "render_svg" render_svg;
    ] )
