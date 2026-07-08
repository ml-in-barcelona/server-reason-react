/* The SAME promise value passed as two different props. React dedups on the
   thenable identity (writtenObjects): one $@ row, referenced twice. */
let app = () => {
  let shared =
    Spec.delay(~ms=5)
    |> Js.Promise.then_(() => Js.Promise.resolve("shared value"));
  Spec.client_component(
    ~importModule="spec/Await.js",
    ~importName="Await",
    ~props=[
      Spec.promise_string("left", shared),
      Spec.promise_string("right", shared),
    ],
    (),
  );
};
