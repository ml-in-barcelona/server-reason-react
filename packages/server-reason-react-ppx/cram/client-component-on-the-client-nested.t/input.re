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

module InnerAfterNested = {
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
  };

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
};

module InnerBeforeNested = {
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
  };
};
