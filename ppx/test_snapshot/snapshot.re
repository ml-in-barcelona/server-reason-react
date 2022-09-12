open Alcotest;
module React = Main.React;
module ReactDOM = Main.ReactDOMServer;

let assert_string = (left, right) =>
  (check(string))("should be equal", right, left);

let test_tag = () => {
  assert_string(ReactDOM.renderToStaticMarkup(<div />), "<div></div>");
};

run(
  "Tests",
  [("renderToStaticMarkup", [test_case("div", `Quick, test_tag)])],
);
