let inner = () =>
  Spec.async_component(~name="InnerAsync", () =>
    Spec.delay(~ms=5)
    |> Js.Promise.then_(() =>
         Js.Promise.resolve(<p> {React.string("inner done")} </p>)
       )
  );

let app = () =>
  Spec.async_component(~name="OuterAsync", () =>
    Spec.delay(~ms=5)
    |> Js.Promise.then_(() =>
         Js.Promise.resolve(
           <div> <span> {React.string("outer done")} </span> {inner()} </div>,
         )
       )
  );
