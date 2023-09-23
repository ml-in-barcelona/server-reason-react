  $ ../ppx.sh --output re input.re
  let fragment = foo => [@bla] React.fragment(~children=React.list([foo]), ());
  let poly_children_fragment = (foo, bar) =>
    React.fragment(~children=React.list([foo, bar]), ());
  let nested_fragment = (foo, bar, baz) =>
    React.fragment(
      ~children=
        React.list([
          foo,
          React.fragment(~children=React.list([bar, baz]), ()),
        ]),
      (),
    );
  let nested_fragment_with_lower = foo =>
    React.fragment(
      ~children=
        React.list([
          React.createElement(
            "div",
            [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
            [foo],
          ),
        ]),
      (),
    );
