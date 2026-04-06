[@deriving rsc]
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
    [@deriving rsc]
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

  [@deriving rsc]
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
  [@deriving rsc]
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
    [@deriving rsc]
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
