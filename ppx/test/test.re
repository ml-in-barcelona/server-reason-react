open! Alcotest;

let assert_string = (left, right) =>
  (check(string))("should be equal", right, left);

let test_tag = () => {
  assert_string(ReactDOM.renderToStaticMarkup(<div />), "<div></div>");
};

let test_empty_attribute = () => {
  let div = <div className="" />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div class=\"\"></div>",
  );
};

let test_bool_attribute = () => {
  let div = <div hidden=true />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div hidden></div>");
};

let test_bool_attributes = () => {
  let input =
    <input type_="checkbox" name="cheese" checked=true disabled=false />;
  assert_string(
    ReactDOM.renderToStaticMarkup(input),
    "<input type=\"checkbox\" name=\"cheese\" checked />",
  );
};

let test_innerhtml = () => {
  let p = <p> {React.string("text")} </p>;
  assert_string(ReactDOM.renderToStaticMarkup(p), "<p>text</p>");
};

let test_int_attribute = () => {
  let div = <div tabIndex=1 />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div tabIndex=\"1\"></div>",
  );
};

let test_style_attribute = () => {
  let div =
    <div style={ReactDOM.Style.make(~backgroundColor="gainsboro", ())} />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div style=\"background-color: gainsboro\"></div>",
  );
};

let test_ref_attribute = () => {
  let divRef = React.useRef(Js.Nullable.null);

  let div = <div ref={React.Ref.domRef(divRef)} />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let test_innerhtml_attribute = () => {
  let text = "foo";
  let div = <div dangerouslySetInnerHTML={"__html": text} />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div>foo</div>");
};

let test_int_opt_attribute_some = () => {
  let tabIndex = Some(1);
  let div = <div ?tabIndex />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div tabIndex=\"1\"></div>",
  );
};

let test_int_opt_attribute_none = () => {
  let tabIndex = None;
  let div = <div ?tabIndex />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let test_fragment = () => {
  let div = <> <div className="md:w-1/3" /> <div className="md:w-2/3" /> </>;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div class=\"md:w-1/3\"></div><div class=\"md:w-2/3\"></div>",
  );
};

module Container = {
  [@react.component]
  let make = (~children) => {
    <div> children </div>;
  };
};

let test_children_fragment = () => {
  let component = <Container> <span /> </Container>;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    "<div><span></span></div>",
  );
};

let test_string_opt_attribute_some = () => {
  let className = Some("foo");
  let div = <div ?className />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div class=\"foo\"></div>",
  );
};

let test_string_opt_attribute_none = () => {
  let className = None;
  let div = <div ?className />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let test_bool_opt_attribute_some = () => {
  let hidden = Some(true);
  let div = <div ?hidden />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div hidden></div>");
};

let test_bool_opt_attribute_none = () => {
  let hidden = None;
  let div = <div ?hidden />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let test_style_opt_attribute_some = () => {
  let style = Some(ReactDOM.Style.make(~backgroundColor="gainsboro", ()));
  let div = <div ?style />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div style=\"background-color: gainsboro\"></div>",
  );
};

let test_style_opt_attribute_none = () => {
  let style = None;
  let div = <div ?style />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let test_ref_opt_attribute_some = () => {
  let divRef = React.useRef(Js.Nullable.null);
  let ref = Some(React.Ref.domRef(divRef));
  let div = <div ?ref />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let test_ref_opt_attribute_none = () => {
  let ref = None;
  let div = <div ?ref />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let test_onclick = () => {
  let onClick = Some(_ => print_endline("clicked"));
  let div = <div ?onClick />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let _ =
  run(
    "Tests",
    [
      (
        "renderToStaticMarkup",
        [
          test_case("div", `Quick, test_tag),
          test_case("div_empty_attr", `Quick, test_empty_attribute),
          test_case("div_bool_attr", `Quick, test_bool_attribute),
          test_case("input_bool_attrs", `Quick, test_bool_attributes),
          test_case("p_inner_html", `Quick, test_innerhtml),
          test_case("div_int_attr", `Quick, test_int_attribute),
          test_case("style_attr", `Quick, test_style_attribute),
          test_case("div_ref_attr", `Quick, test_ref_attribute),
          test_case("inner_html_attr", `Quick, test_innerhtml_attribute),
          test_case("int_opt_attr_some", `Quick, test_int_opt_attribute_some),
          test_case("int_opt_attr_none", `Quick, test_int_opt_attribute_none),
          test_case(
            "string_opt_attr_some",
            `Quick,
            test_string_opt_attribute_some,
          ),
          test_case(
            "string_opt_attr_none",
            `Quick,
            test_string_opt_attribute_none,
          ),
          test_case(
            "bool_opt_attr_some",
            `Quick,
            test_bool_opt_attribute_some,
          ),
          test_case(
            "bool_opt_attr_none",
            `Quick,
            test_bool_opt_attribute_none,
          ),
          test_case(
            "style_opt_attr_some",
            `Quick,
            test_style_opt_attribute_some,
          ),
          test_case(
            "style_opt_attr_none",
            `Quick,
            test_style_opt_attribute_none,
          ),
          test_case("ref_opt_attr_some", `Quick, test_ref_opt_attribute_some),
          test_case("ref_opt_attr_none", `Quick, test_ref_opt_attribute_none),
          test_case("test_fragment", `Quick, test_fragment),
          test_case("test_children_fragment", `Quick, test_children_fragment),
          test_case("event_onClick", `Quick, test_onclick),
        ],
      ),
    ],
  );
