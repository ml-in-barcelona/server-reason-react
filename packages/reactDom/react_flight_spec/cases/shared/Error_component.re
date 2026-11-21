module Boom = {
  [@react.component]
  let make = () => raise(Failure("boom"));
};

let app = () => <Boom />;
