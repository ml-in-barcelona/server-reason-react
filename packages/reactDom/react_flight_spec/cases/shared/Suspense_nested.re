let app = () =>
  <React.Suspense fallback={<span> {React.string("outer waiting")} </span>}>
    {Spec.async_component(~name="Outer", () =>
       Spec.delay(~ms=5)
       |> Js.Promise.then_(() =>
            Js.Promise.resolve(
              <div>
                {React.string("outer late")}
                <React.Suspense
                  fallback={<span> {React.string("inner waiting")} </span>}>
                  {Spec.async_component(~name="Inner", () =>
                     Spec.delay(~ms=10)
                     |> Js.Promise.then_(() =>
                          Js.Promise.resolve(
                            <p> {React.string("inner late")} </p>,
                          )
                        )
                   )}
                </React.Suspense>
              </div>,
            )
          )
     )}
  </React.Suspense>;
