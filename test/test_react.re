let assert_string = (left, right) =>
  Alcotest.check(Alcotest.string, "should be equal", right, left);

module Text = {
  module Tag = {
    type t =
      | H1
      | H2
      | H3
      | H4
      | P
      | Span
      | Div;

    let unwrap =
      fun
      | H1 => "h1"
      | H2 => "h2"
      | H3 => "h3"
      | H4 => "h4"
      | P => "p"
      | Span => "span"
      | Div => "div";
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

let full_case = () => {
  let component = <Text tagType=Text.Tag.H1> {React.string("Hello")} </Text>;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    "<h1 style=\"display: none\" class=\"foo\">Hello</h1>",
  );
};

let case = (title, fn) => Alcotest.test_case(title, `Quick, fn);

let tests = ("React", [case("createElementVariadic", full_case)]);
