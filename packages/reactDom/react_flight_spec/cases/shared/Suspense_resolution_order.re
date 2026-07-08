/* Two sibling boundaries where the SECOND resolves FIRST (delays inverted
   relative to suspense_two_boundaries): row emission must follow resolution
   order, so row 3 (second boundary) streams before row 2 (first boundary). */
let app = () =>
  <>
    <React.Suspense fallback={<span> {React.string("first waiting")} </span>}>
      {Spec.async_component(~name="SlowFirst", () =>
         Spec.delay(~ms=15)
         |> Js.Promise.then_(() =>
              Js.Promise.resolve(<div> {React.string("first late")} </div>)
            )
       )}
    </React.Suspense>
    <React.Suspense
      fallback={<span> {React.string("second waiting")} </span>}>
      {Spec.async_component(~name="FastSecond", () =>
         Spec.delay(~ms=5)
         |> Js.Promise.then_(() =>
              Js.Promise.resolve(<div> {React.string("second late")} </div>)
            )
       )}
    </React.Suspense>
  </>;
