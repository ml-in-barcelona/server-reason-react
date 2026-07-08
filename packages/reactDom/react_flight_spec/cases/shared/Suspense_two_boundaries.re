let app = () =>
  <>
    <React.Suspense fallback={<span> {React.string("first waiting")} </span>}>
      {Spec.async_component(~name="FirstDelayed", () =>
         Spec.delay(~ms=5)
         |> Js.Promise.then_(() =>
              Js.Promise.resolve(<div> {React.string("first late")} </div>)
            )
       )}
    </React.Suspense>
    <React.Suspense
      fallback={<span> {React.string("second waiting")} </span>}>
      {Spec.async_component(~name="SecondDelayed", () =>
         Spec.delay(~ms=15)
         |> Js.Promise.then_(() =>
              Js.Promise.resolve(<div> {React.string("second late")} </div>)
            )
       )}
    </React.Suspense>
  </>;
