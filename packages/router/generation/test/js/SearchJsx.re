let recordHref =
  Router.Inspector.href(
    ~search={
      target: "x",
      error: Some("e"),
      input: "all",
      hash: ["a"],
      value: None,
      pattern: None,
    },
    (),
  );

let constructorHref =
  Router.Inspector.href(
    ~search=Router.Inspector.search(~target="a b", ~input="x", ()),
    (),
  );

let elements = [
  <Router.Inspector
    target="_blank"
    search={
      target: "x",
      error: None,
      input: "all",
      hash: [],
      value: None,
      pattern: None,
    }>
    {React.string("record")}
  </Router.Inspector>,
  <Router.Inspector
    target="_blank" search={Router.Inspector.search(~target="x", ())}>
    {React.string("constructor")}
  </Router.Inspector>,
];
