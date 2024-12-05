[@warning "-27"];

module Await = {
  [@react.component]
  let make = (~promise: Js.Promise.t(string)) => {
    let value = React.Experimental.use(promise);
    React.string("[RESOLVED] " ++ value);
  };
};

let make = (~value: Js.Promise.t(string)) =>
  <span> {React.string("Promise: ")} <Await promise=value /> </span>;

[@react.component]
let make = (~value) =>
  switch%platform (Runtime.platform) {
  | Server =>
    React.Client_component({
      import_module: "Promise_renderer",
      import_name: "",
      props: [("value", React.Promise(value, v => `String(v)))],
      client: make(~value),
    })
  | Client => make(~value)
  };

let default = make;
