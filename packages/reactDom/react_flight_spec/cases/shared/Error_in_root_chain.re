module Boom = {
  [@react.component]
  let make = () => raise(Failure("chained boom"));
};

module App = {
  [@react.component]
  let make = () => <Boom />;
};

let app = () => <App />;
