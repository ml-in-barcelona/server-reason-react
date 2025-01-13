open Ppx_deriving_json_runtime.Primitives;

[@deriving json]
type lola = {name: string};

module Prop_with_many_annotation = {
  [@react.client.component]
  let make =
      (
        ~initial: int,
        ~lola: lola,
        ~children: React.element,
        ~maybe_children: option(React.element),
        ~promise: Js.Promise.t(string),
      ) => {
    let value = React.Experimental.use(promise);
    <div>
      {React.string(lola.name)}
      {React.int(initial)}
      children
      {switch (maybe_children) {
       | Some(children) => children
       | None => React.null
       }}
      {React.string(value)}
    </div>;
  };
};
