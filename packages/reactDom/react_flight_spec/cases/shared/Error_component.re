/* A regular function component that throws synchronously at the ROOT of the
   model. React prod replaces the root row itself with an error row
   (0:E{"digest":...}, digest = onError's return value, "" by default) and
   emits nothing else. */
module Boom = {
  [@react.component]
  let make = () => raise(Failure("boom"));
};

let app = () => <Boom />;
