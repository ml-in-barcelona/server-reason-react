/* An ALREADY-REJECTED promise passed as a prop: the position serializes as a
   "$@<id>" reference and the row arrives as <id>:E{...}. Like every error
   chunk, it flushes AFTER the model rows of the same flush (completedErrorChunks). */
let app = () =>
  Spec.client_component(
    ~importModule="spec/Await.js",
    ~importName="Await",
    ~props=[
      Spec.promise_string("data", Js.Promise.reject(Failure("rejected"))),
    ],
    (),
  );
