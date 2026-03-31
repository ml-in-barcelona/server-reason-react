
  $ ../ppx.sh --output re input.re
  let upper = Upper.make(Upper.makeProps());
  let upper_prop = Upper.make(Upper.makeProps(~count, ()));
  let upper_children_single = foo =>
    Upper.make(Upper.makeProps(~children=foo, ()));
  let upper_children_multiple = (foo, bar) =>
    Upper.make(Upper.makeProps(~children=React.list([foo, bar]), ()));
  let upper_children =
    Page.make(
      Page.makeProps(
        ~children=
          React.Static({
            prerendered: "<h1>Yep</h1>",
            original: React.createElement("h1", [], [React.string("Yep")]),
          }),
        ~moreProps="hgalo",
        (),
      ),
    );
  let upper_nested_module = Foo.Bar.make(Foo.Bar.makeProps(~a=1, ~b="1", ()));
  let upper_child_expr = Div.make(Div.makeProps(~children=React.int(1), ()));
  let upper_child_ident = Div.make(Div.makeProps(~children=lola, ()));
  let upper_all_kinds_of_props =
    MyComponent.make(
      MyComponent.makeProps(
        ~children=
          React.Static({
            prerendered: "<div>hello</div>",
            original: React.createElement("div", [], ["hello"]),
          }),
        ~booleanAttribute=true,
        ~stringAttribute="string",
        ~intAttribute=1,
        ~forcedOptional=?Some("hello"),
        ~onClick=send(handleClick),
        (),
      ),
    );
  let upper_ref_with_children =
    FancyButton.make(
      FancyButton.makeProps(
        ~children=
          React.Static({
            prerendered: "<div></div>",
            original: React.createElement("div", [], []),
          }),
        ~ref=buttonRef,
        (),
      ),
    );
