/* An ALREADY-RESOLVED promise passed as a prop: React still outlines it as
   its own task and retries it after the current row (pingedTasks), so the
   resolution row streams AFTER the row that references it ("$@" first,
   value row second). */
let app = () =>
  Spec.client_component(
    ~importModule="spec/Await.js",
    ~importName="Await",
    ~props=[
      Spec.promise_string("data", Js.Promise.resolve("immediate value")),
    ],
    (),
  );
