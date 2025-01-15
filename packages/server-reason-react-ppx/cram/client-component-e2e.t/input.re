open Ppx_deriving_json_runtime.Primitives;

[@deriving json]
type lola = {name: string};

[@react.client.component]
let make =
    (
      ~initial: int,
      ~lola: lola,
      ~children: React.element,
      ~promise: Js.Promise.t(string),
    ) => {
  let value = React.Experimental.use(promise);
  <div>
    {React.string(lola.name)}
    {React.int(initial)}
    children
    {React.string(value)}
  </div>;
};

// to avoid unused error on "make"
let _ = make;
