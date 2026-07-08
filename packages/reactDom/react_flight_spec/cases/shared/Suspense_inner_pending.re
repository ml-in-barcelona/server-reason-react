/* Nested boundaries where only the INNER one suspends: the outer boundary's
   children are fully sync (so they inline into the root row), and only the
   inner boundary emits a lazy reference resolved by a later row. */
let app = () =>
  <React.Suspense fallback={<span> {React.string("outer waiting")} </span>}>
    <div>
      {React.string("outer ready")}
      <React.Suspense
        fallback={<span> {React.string("inner waiting")} </span>}>
        {Spec.async_component(~name="InnerOnly", () =>
           Spec.delay(~ms=10)
           |> Js.Promise.then_(() =>
                Js.Promise.resolve(<p> {React.string("inner late")} </p>)
              )
         )}
      </React.Suspense>
    </div>
  </React.Suspense>;
