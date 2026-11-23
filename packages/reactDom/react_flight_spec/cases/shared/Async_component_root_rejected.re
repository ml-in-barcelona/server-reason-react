let app = () =>
  Spec.async_component(~name="RootRejecting", () =>
    Spec.delay(~ms=5)
    |> Js.Promise.then_(() => Js.Promise.reject(Failure("root boom")))
  );
