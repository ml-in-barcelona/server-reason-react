open Alcotest;
module React = Main.React;
module ReactDOM = Main.ReactDOMServer;

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

let test_int_attribute = () => {
  let div = <div tabIndex=1 />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    "<div tabIndex=\"1\"></div>",
  );
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
        test_case("div_int_attr", `Quick, test_int_attribute),
      ],
    ),
  ],
);
