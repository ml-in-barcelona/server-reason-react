let app = () =>
  <React.Suspense fallback={<span> {React.string("waiting")} </span>}>
    {Spec.async_component(~name="Delayed", () =>
       Spec.delay(~ms=10)
       |> Js.Promise.then_(() =>
            Js.Promise.resolve(<div> {React.string("late")} </div>)
          )
     )}
  </React.Suspense>;
