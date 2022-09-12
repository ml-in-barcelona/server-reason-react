open Alcotest;
module React = Main.React;
module ReactDOM = Main.ReactDOMServer;
open React.Bridge;

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

// let test_style_attribute = () => {
//   let div = <div hidden=true />;
//   assert_string(ReactDOM.renderToStaticMarkup(div), "<div hidden></div>");
// };

let test_ref_attribute = () => {
  let divRef = React.useRef(Js.Nullable.null);

  let div = <div ref={React.Ref.domRef(divRef)} />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div></div>");
};

let test_innerhtml_attribute = () => {
  let div = <div hidden=true />;
  assert_string(ReactDOM.renderToStaticMarkup(div), "<div hidden></div>");
};

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
        test_case("div_ref_attr", `Quick, test_ref_attribute),
      ],
    ),
  ],
);
