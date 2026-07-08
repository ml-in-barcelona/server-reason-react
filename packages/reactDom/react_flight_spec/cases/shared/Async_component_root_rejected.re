/* An async component at the ROOT rejecting after a delay: the retried root
   task fails, so React errors the root row itself — the whole stream is a
   single 0:E{...} row. */
let app = () =>
  Spec.async_component(~name="RootRejecting", () =>
    Spec.delay(~ms=5)
    |> Js.Promise.then_(() => Js.Promise.reject(Failure("root boom")))
  );
