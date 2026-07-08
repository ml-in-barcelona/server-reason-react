let app = () =>
  Spec.client_component(
    ~importModule="spec/Await.js",
    ~importName="Await",
    ~props=[
      Spec.promise_string(
        "data",
        Spec.delay(~ms=5)
        |> Js.Promise.then_(() => Js.Promise.resolve("resolved value")),
      ),
    ],
    (),
  );
