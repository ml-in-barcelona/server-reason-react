let app = () =>
  <React.Suspense fallback={<span> {React.string("waiting")} </span>}>
    {Spec.async_component(~name="Rejecting", () =>
       Spec.delay(~ms=10)
       |> Js.Promise.then_(() => Js.Promise.reject(Failure("async boom")))
     )}
  </React.Suspense>;
