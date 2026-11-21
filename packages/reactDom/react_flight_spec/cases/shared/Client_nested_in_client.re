let app = () =>
  Spec.client_component(
    ~importModule="spec/Outer.js",
    ~importName="default",
    ~props=[
      Spec.element(
        "children",
        Spec.client_component(
          ~importModule="spec/Inner.js",
          ~importName="default",
          ~props=[Spec.string("label", "nested")],
          (),
        ),
      ),
    ],
    (),
  );
