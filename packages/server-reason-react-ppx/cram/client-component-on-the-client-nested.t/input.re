open Melange_json.Primitives;

[@deriving json]
type lola = {name: string};

[@react.client.component]
let make = (~initial: int, ~lola: lola, ~children: React.element) => {
  <section>
    <h1> {React.string(lola.name)} </h1>
    <p> {React.int(initial)} </p>
    <div> children </div>
  </section>;
};

// to avoid unused error on "make"
let _ = make;

module Inner = {
  [@deriving json]
  type lola = {name: string};

  [@react.client.component]
  let make = (~initial: int, ~lola: lola, ~children: React.element) => {
    <section>
      <h1> {React.string(lola.name)} </h1>
      <p> {React.int(initial)} </p>
      <div> children </div>
    </section>;
  };

  // to avoid unused error on "make"
  let _ = make;

  module Very_nested = {
    [@deriving json]
    type lola = {name: string};

    [@react.client.component]
    let make = (~initial: int, ~lola: lola, ~children: React.element) => {
      <section>
        <h1> {React.string(lola.name)} </h1>
        <p> {React.int(initial)} </p>
        <div> children </div>
      </section>;
    };

    // to avoid unused error on "make"
    let _ = make;
  };
};
