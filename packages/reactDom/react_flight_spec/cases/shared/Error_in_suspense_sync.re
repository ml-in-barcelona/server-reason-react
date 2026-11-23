module Boom = {
  [@react.component]
  let make = () => raise(Failure("boom"));
};

let app = () =>
  <React.Suspense fallback={<span> {React.string("will not help")} </span>}>
    <Boom />
  </React.Suspense>;
