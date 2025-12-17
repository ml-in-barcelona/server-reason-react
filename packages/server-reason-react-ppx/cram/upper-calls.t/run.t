
  $ ../ppx.sh --output re input.re
  let upper = Upper.make();
  let upper_prop = Upper.make(~count, ());
  let upper_children_single = foo => Upper.make(~children=foo, ());
  let upper_children_multiple = (foo, bar) =>
    Upper.make(~children=React.list([foo, bar]), ());
  let upper_children =
    Page.make(
      ~children=React.DangerouslyInnerHtml("<h1>Yep</h1>"),
      ~moreProps="hgalo",
      (),
    );
  let upper_nested_module = Foo.Bar.make(~a=1, ~b="1", ());
  let upper_child_expr = Div.make(~children=React.int(1), ());
  let upper_child_ident = Div.make(~children=lola, ());
  let upper_all_kinds_of_props =
    MyComponent.make(
      ~children=React.DangerouslyInnerHtml("<div>hello</div>"),
      ~booleanAttribute=true,
      ~stringAttribute="string",
      ~intAttribute=1,
      ~forcedOptional=?Some("hello"),
      ~onClick=send(handleClick),
      (),
    );
  let upper_ref_with_children =
    FancyButton.make(
      ~children=React.DangerouslyInnerHtml("<div></div>"),
      ~ref=buttonRef,
      (),
    );
