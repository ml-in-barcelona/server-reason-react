  $ ../ppx.sh --output re input.re
  let fragment = foo => [@bla] React.fragment(React.list([foo]));
  let poly_children_fragment = (foo, bar) =>
    React.fragment(React.list([foo, bar]));
  let nested_fragment = (foo, bar, baz) =>
    React.fragment(
      React.list([foo, React.fragment(React.list([bar, baz]))]),
    );
  let nested_fragment_with_lower = foo =>
    React.fragment(React.list([React.createElement("div", [], [foo])]));
  module Fragment = {
    let make = (~key as _: option(string)=?) =>
      [@warning "-16"]
      (
        (~name="", ()) =>
          React.fragment(
            React.list([
              React.createElement(
                "div",
                [],
                [React.string("First " ++ name)],
              ),
              React.Upper_case_component(
                () =>
                  Hello.make(
                    ~children=React.string("2nd " ++ name),
                    ~one="1",
                    (),
                  ),
              ),
            ]),
          )
      );
  };
