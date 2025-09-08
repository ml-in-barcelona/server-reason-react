open Melange_json.Primitives;

[@deriving json]
type lola = {name: string};

[@react.client.component]
let make =
    (
      ~initial: int,
      ~lola: lola,
      ~default: int=23,
      ~children: React.element,
      ~promise: Js.Promise.t(string),
    ) => {
  let value = React.Experimental.usePromise(promise);
  <div>
    {React.string(lola.name)}
    {React.int(initial)}
    {React.int(default)}
    children
    {React.string(value)}
  </div>;
};
