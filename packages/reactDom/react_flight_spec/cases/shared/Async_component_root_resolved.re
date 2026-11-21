let app = () =>
  Spec.async_component(~name="RootAsync", () =>
    Spec.delay(~ms=5)
    |> Js.Promise.then_(() =>
         Js.Promise.resolve(<div> {React.string("root done")} </div>)
       )
  );
