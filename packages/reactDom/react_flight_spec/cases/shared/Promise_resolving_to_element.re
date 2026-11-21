let app = () =>
  Spec.client_component(
    ~importModule="spec/Await.js",
    ~importName="Await",
    ~props=[
      Spec.promise_element(
        "content",
        Spec.delay(~ms=5)
        |> Js.Promise.then_(() =>
             Js.Promise.resolve(
               <div> {React.string("from a promise")} </div>,
             )
           ),
      ),
    ],
    (),
  );
