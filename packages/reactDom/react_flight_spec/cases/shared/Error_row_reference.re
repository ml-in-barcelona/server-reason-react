module Boom = {
  [@react.component]
  let make = () => raise(Failure("boom"));
};

let app = () =>
  <div>
    <p> {React.string("before")} </p>
    <Boom />
    <p> {React.string("after")} </p>
  </div>;
