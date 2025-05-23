[@warning "-32"];

open Melange_json.Primitives;

[@deriving json]
type lola = {name: string};

[@react.client.component]
let make =
    (
      ~initial: int,
      ~lola: lola,
      ~children: React.element,
      ~maybe_children: option(React.element),
    ) => {
  <section>
    <h1> {React.string(lola.name)} </h1>
    <p> {React.int(initial)} </p>
    <div> children </div>
    {switch (maybe_children) {
     | Some(children) => children
     | None => React.null
     }}
  </section>;
};
