let app = () =>
  Spec.client_component(
    ~importModule="spec/Await.js",
    ~importName="Await",
    ~props=[
      Spec.promise_string(
        "fast",
        Spec.delay(~ms=5)
        |> Js.Promise.then_(() => Js.Promise.resolve("fast value")),
      ),
      Spec.promise_string(
        "slow",
        Spec.delay(~ms=15)
        |> Js.Promise.then_(() => Js.Promise.resolve("slow value")),
      ),
    ],
    (),
  );
