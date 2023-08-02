let assert_string = (left, right) => {
  Alcotest.check(Alcotest.string, "should be equal", right, left);
};

let tag = () => {
  let div = <div />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let empty_attribute = () => {
  let div = <div className="" />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div class=\"\"></div>",
  );
};

let bool_attribute = () => {
  let div = <div hidden=true />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div hidden></div>");
};

let bool_attributes = () => {
  let input =
    <input type_="checkbox" name="cheese" checked=true disabled=false />;
  assert_string(
    ReactDOM.renderToStaticMarkup(input),
    "<input type=\"checkbox\" name=\"cheese\" checked />",
  );
};

let innerhtml = () => {
  let p = <p> {React.string("text")} </p>;
  assert_string(ReactDOM.renderToStaticMarkup(p), "<p>text</p>");
};

let int_attribute = () => {
  let div = <div tabIndex=1 />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div tabIndex=\"1\"></div>",
  );
};

let style_attribute = () => {
  let div =
    <div style={ReactDOM.Style.make(~backgroundColor="gainsboro", ())} />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div style=\"background-color: gainsboro\"></div>",
  );
};

let ref_attribute = () => {
  let divRef = React.useRef(Js.Nullable.null);

  let div = <div ref={React.Ref.domRef(divRef)} />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let link_as_attribute = () => {
  let link = <link as_="image" rel="preload" href="https://sancho.dev/blog" />;
  assert_string(
    ReactDOM.renderToStaticMarkup(link),
    "<link as=\"image\" rel=\"preload\" href=\"https://sancho.dev/blog\" />",
  );
};

let innerhtml_attribute = () => {
  let div = <div dangerouslySetInnerHTML={"__html": "foo"} />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div>foo</div>");
};

let innerhtml_attribute_complex = () => {
  let div =
    <div dangerouslySetInnerHTML={"__html": "console.log(\"Lola\")"} />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div>console.log(\"Lola\")</div>",
  );
};

let int_opt_attribute_some = () => {
  let tabIndex = Some(1);
  let div = <div ?tabIndex />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div tabIndex=\"1\"></div>",
  );
};

let int_opt_attribute_none = () => {
  let tabIndex = None;
  let div = <div ?tabIndex />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let fragment = () => {
  let div = <> <div className="md:w-1/3" /> <div className="md:w-2/3" /> </>;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div class=\"md:w-1/3\"></div><div class=\"md:w-2/3\"></div>",
  );
};

module Container = {
  [@react.component]
  let make = (~children) => <div> children </div>;
};

let children_uppercase = () => {
  let component = <Container> <span /> </Container>;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    "<div><span></span></div>",
  );
};

let children_lowercase = () => {
  let component = <div> <span /> </div>;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    "<div><span></span></div>",
  );
};

let string_opt_attribute_some = () => {
  let className = Some("foo");
  let div = <div ?className />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div class=\"foo\"></div>",
  );
};

let string_opt_attribute_none = () => {
  let className = None;
  let div = <div ?className />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let bool_opt_attribute_some = () => {
  let hidden = Some(true);
  let div = <div ?hidden />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div hidden></div>");
};

let bool_opt_attribute_none = () => {
  let hidden = None;
  let div = <div ?hidden />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let style_opt_attribute_some = () => {
  let style = Some(ReactDOM.Style.make(~backgroundColor="gainsboro", ()));
  let div = <div ?style />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div style=\"background-color: gainsboro\"></div>",
  );
};

let style_opt_attribute_none = () => {
  let style = None;
  let div = <div ?style />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let ref_opt_attribute_some = () => {
  let divRef = React.useRef(Js.Nullable.null);
  let ref = Some(React.Ref.domRef(divRef));
  let div = <div ?ref />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let ref_opt_attribute_none = () => {
  let ref = None;
  let div = <div ?ref />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let onClick_empty = () => {
  let onClick = Some(_ => print_endline("clicked"));
  let div = <div ?onClick />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let onclick_inline_string = () => {
  let onClick = "console.log('clicked')";
  let div = <div _onclick=onClick />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div onclick=\"console.log('clicked')\"></div>",
  );
};

let svg = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        width="24px"
        height="24px">
        <path
          d="M 5 3 C 3.9069372 3 3 3.9069372 3 5 L 3 19 C 3 20.093063 3.9069372 21 5 21 L 19 21 C 20.093063 21 21 20.093063 21 19 L 21 12 L 19 12 L 19 19 L 5 19 L 5 5 L 12 5 L 12 3 L 5 3 z M 14 3 L 14 5 L 17.585938 5 L 8.2929688 14.292969 L 9.7070312 15.707031 L 19 6.4140625 L 19 10 L 21 10 L 21 3 L 14 3 z"
        />
      </svg>,
    ),
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\" width=\"24px\" height=\"24px\"><path d=\"M 5 3 C 3.9069372 3 3 3.9069372 3 5 L 3 19 C 3 20.093063 3.9069372 21 5 21 L 19 21 C 20.093063 21 21 20.093063 21 19 L 21 12 L 19 12 L 19 19 L 5 19 L 5 5 L 12 5 L 12 3 L 5 3 z M 14 3 L 14 5 L 17.585938 5 L 8.2929688 14.292969 L 9.7070312 15.707031 L 19 6.4140625 L 19 10 L 21 10 L 21 3 L 14 3 z\"></path></svg>",
  );
};

module Component = {
  [@react.component]
  let make = (~children: React.element, ~cosas as _) => {
    <div> children </div>;
  };
};

let children_flattening_one_element = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(
      <Component cosas=true> <span /> </Component>,
    ),
    "<div><span></span></div>",
  );
};

let children_flattening_multiple_elements = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(
      <Component cosas=false> <div> <span /> </div> <span /> </Component>,
    ),
    "<div><div><span></span></div><span></span></div>",
  );
};

let case = (title, fn) => Alcotest.test_case(title, `Quick, fn);

let assert_string = (left, right) =>
  Alcotest.check(Alcotest.string, "should be equal", right, left);

module Text = {
  module Tag = {
    type t =
      | H1;

    let unwrap =
      fun
      | H1 => "h1";
  };

  [@react.component]
  let make = (~tagType, ~children: React.element) => {
    ReactDOM.createDOMElementVariadic(
      tagType |> Tag.unwrap,
      ReactDOM.domProps(
        ~className="foo",
        ~style=ReactDOM.Style.make(~display="none", ()),
        (),
      ),
      React.Children.toArray(children),
    );
  };
};

let create_element_variadic = () => {
  let component = <Text tagType=Text.Tag.H1> {React.string("Hello")} </Text>;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    "<h1 style=\"display: none\" class=\"foo\">Hello</h1>",
  );
};

let _ =
  Alcotest.run(
    "server-reason-react-ppx",
    [
      (
        "renderToStaticMarkup",
        [
          case("div", tag),
          case("div_empty_attr", empty_attribute),
          case("div_bool_attr", bool_attribute),
          case("input_bool_attrs", bool_attributes),
          case("p_inner_html", innerhtml),
          case("div_int_attr", int_attribute),
          case("svg", svg),
          case("style_attr", style_attribute),
          case("div_ref_attr", ref_attribute),
          case("link_as_attr", link_as_attribute),
          case("inner_html_attr", innerhtml_attribute),
          case("p_inner_html", innerhtml_attribute_complex),
          case("int_opt_attr_some", int_opt_attribute_some),
          case("int_opt_attr_none", int_opt_attribute_none),
          case("string_opt_attr_some", string_opt_attribute_some),
          case("string_opt_attr_none", string_opt_attribute_none),
          case("bool_opt_attr_some", bool_opt_attribute_some),
          case("bool_opt_attr_none", bool_opt_attribute_none),
          case("style_opt_attr_some", style_opt_attribute_some),
          case("style_opt_attr_none", style_opt_attribute_none),
          case("ref_opt_attr_some", ref_opt_attribute_some),
          case("ref_opt_attr_none", ref_opt_attribute_none),
          case("test_fragment", fragment),
          case("test_children_uppercase", children_uppercase),
          case("test_children_lowercase", children_lowercase),
          case("event_onClick", onClick_empty),
          case("event_onclick_inline_string", onclick_inline_string),
          case(
            "children_flattening_one_element",
            children_flattening_one_element,
          ),
          case(
            "children_flattening_multiple_elements",
            children_flattening_multiple_elements,
          ),
          case("createElementVariadic", create_element_variadic),
        ],
      ),
    ],
  );
