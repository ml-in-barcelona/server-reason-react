let app = () =>
  Spec.client_component(
    ~importModule="spec/Await.js",
    ~importName="Await",
    ~props=[
      Spec.promise_string("data", Js.Promise.resolve("immediate value")),
    ],
    (),
  );
