let app = () =>
  Spec.client_component(
    ~importModule="spec/Nullable.js",
    ~importName="default",
    ~props=[
      Spec.json_null("nothing"),
      Spec.list("items", [Spec.model_null, Spec.model_string("present")]),
      Spec.object_("meta", [("missing", Spec.model_null)]),
    ],
    (),
  );
