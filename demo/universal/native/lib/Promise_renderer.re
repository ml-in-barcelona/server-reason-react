[@warning "-33"];

open Ppx_deriving_json_runtime.Primitives;

module Reader = {
  [@react.component]
  let make = (~promise: Js.Promise.t(string)) => {
    let value = React.Experimental.use(promise);
    let%browser_only onMouseOver = _ev => {
      Js.log("Over the promise!");
    };
    <div className="cursor-pointer" onMouseOver> {React.string(value)} </div>;
  };
};

[@react.client.component]
let make = (~promise: Js.Promise.t(string)) => {
  <div className="text-white">
    <React.Suspense fallback={<div> {React.string("Loading...")} </div>}>
      <Reader promise />
    </React.Suspense>
  </div>;
};
