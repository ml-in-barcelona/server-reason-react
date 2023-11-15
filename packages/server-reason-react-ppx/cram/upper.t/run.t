
  $ ../ppx.sh --output re input.re
  let upper = React.Upper_case_component(() => Upper.make());
  let upper_prop = React.Upper_case_component(() => Upper.make(~count, ()));
  let upper_children_single = foo =>
    React.Upper_case_component(() => Upper.make(~children=foo, ()));
  let upper_children_multiple = (foo, bar) =>
    React.Upper_case_component(
      () => Upper.make(~children=React.list([foo, bar]), ()),
    );
  let upper_children =
    React.Upper_case_component(
      () =>
        Page.make(
          ~children=React.createElement("h1", [], [React.string("Yep")]),
          ~moreProps="hgalo",
          (),
        ),
    );
  let upper_nested_module =
    React.Upper_case_component(() => Foo.Bar.make(~a=1, ~b="1", ()));
  let upper_child_expr =
    React.Upper_case_component(() => Div.make(~children=React.int(1), ()));
  let upper_child_ident =
    React.Upper_case_component(() => Div.make(~children=lola, ()));
  let upper_all_kinds_of_props =
    React.Upper_case_component(
      () =>
        MyComponent.make(
          ~children=React.createElement("div", [], [Jsx.text("hello")]),
          ~booleanAttribute=true,
          ~stringAttribute="string",
          ~intAttribute=1,
          ~forcedOptional=?Some("hello"),
          ~onClick=send(handleClick),
          (),
        ),
    );
  let upper_ref_with_children =
    React.Upper_case_component(
      () =>
        FancyButton.make(
          ~children=React.createElement("div", [], []),
          ~ref=buttonRef,
          (),
        ),
    );
