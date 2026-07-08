/* An async component rejecting after a delay under a Suspense boundary: the
   children serialize as a pending "$L<id>" reference and the later row
   arrives as <id>:E{"digest":...} instead of a model row. */
let app = () =>
  <React.Suspense fallback={<span> {React.string("waiting")} </span>}>
    {Spec.async_component(~name="Rejecting", () =>
       Spec.delay(~ms=10)
       |> Js.Promise.then_(() => Js.Promise.reject(Failure("async boom")))
     )}
  </React.Suspense>;
