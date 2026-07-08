let app = () =>
  Spec.client_component(
    ~importModule="spec/Button.js",
    ~importName="default",
    (),
  );
