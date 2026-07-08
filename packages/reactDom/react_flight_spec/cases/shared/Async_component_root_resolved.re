/* An async component at the ROOT resolving after a delay to a fully sync
   tree: React retries the suspended root task in place, so the resolved tree
   renders into row 0 itself — no "$L" indirection, a single row. */
let app = () =>
  Spec.async_component(~name="RootAsync", () =>
    Spec.delay(~ms=5)
    |> Js.Promise.then_(() =>
         Js.Promise.resolve(<div> {React.string("root done")} </div>)
       )
  );
