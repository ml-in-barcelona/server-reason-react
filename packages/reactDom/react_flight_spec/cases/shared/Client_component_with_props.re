let app = () =>
  Spec.client_component(
    ~importModule="spec/Card.js",
    ~importName="Card",
    ~props=[
      Spec.string("title", "Hello"),
      Spec.int("count", 42),
      Spec.float("ratio", 1.5),
      Spec.bool("active", true),
      Spec.json_null("nothing"),
      Spec.element("icon", <span> {React.string("*")} </span>),
    ],
    (),
  );
