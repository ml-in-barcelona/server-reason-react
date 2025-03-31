[@warning "-33"];

open Melange_json.Primitives;

module Reader = {
  [@react.component]
  let make = (~promise: Js.Promise.t(string)) => {
    let value = React.Experimental.use(promise);
    let%browser_only onMouseOver = _ev => {
      Js.log("Over the promise!");
    };
    <div className="cursor-pointer" onMouseOver> <Text> value </Text> </div>;
  };
};

[@react.client.component]
let make = (~promise: Js.Promise.t(string)) => {
  <div className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
    <React.Suspense fallback={<div> {React.string("Loading...")} </div>}>
      <Reader promise />
    </React.Suspense>
  </div>;
};
