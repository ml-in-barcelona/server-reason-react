[@warning "-27"];

module Await = {
  [@react.component]
  let make = (~promise: Js.Promise.t(string)) => {
    let value = React.Experimental.use(promise);
    <div> {React.string("Promise resolved: " ++ value)} </div>;
  };
};

let make = (~promise: Js.Promise.t(string)) =>
  <div>
    <div> {React.string("Waiting for promise to resolve:")} </div>
    <React.Suspense fallback={<div> {React.string("Loading...")} </div>}>
      <Await promise />
    </React.Suspense>
  </div>;

[@react.component]
let make = (~promise) =>
  switch%platform (Runtime.platform) {
  | Server =>
    Js.log("Server");
    React.Client_component({
      import_module: "Promise_renderer",
      import_name: "",
      props: [("promise", React.Promise(promise, v => `String(v)))],
      client: make(~promise),
    });
  | Client => make(~promise)
  };
