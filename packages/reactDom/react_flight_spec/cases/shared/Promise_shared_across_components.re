/* The SAME promise passed to two DIFFERENT client components: React's
   writtenObjects map is request-scoped, so the dedup ("$@<id>" referenced
   from both prop objects, one resolution row) crosses component boundaries. */
let app = () => {
  let shared =
    Spec.delay(~ms=5)
    |> Js.Promise.then_(() => Js.Promise.resolve("shared everywhere"));
  <div>
    {Spec.client_component(
       ~importModule="spec/Await.js",
       ~importName="Await",
       ~props=[Spec.promise_string("data", shared)],
       (),
     )}
    {Spec.client_component(
       ~importModule="spec/Other.js",
       ~importName="Other",
       ~props=[Spec.promise_string("data", shared)],
       (),
     )}
  </div>;
};
