/* Two promise props resolving in a controlled order: row ids are assigned in
   prop-serialization order ($@2 then $@3), and the resolution rows stream in
   resolution order (2 first, then 3). */
let app = () =>
  Spec.client_component(
    ~importModule="spec/Await.js",
    ~importName="Await",
    ~props=[
      Spec.promise_string(
        "fast",
        Spec.delay(~ms=5)
        |> Js.Promise.then_(() => Js.Promise.resolve("fast value")),
      ),
      Spec.promise_string(
        "slow",
        Spec.delay(~ms=15)
        |> Js.Promise.then_(() => Js.Promise.resolve("slow value")),
      ),
    ],
    (),
  );
