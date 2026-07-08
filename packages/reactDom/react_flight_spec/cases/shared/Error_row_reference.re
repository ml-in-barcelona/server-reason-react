/* A throwing component in an element position BELOW the root: the position
   is replaced by a lazy error reference "$L<id>" (not "$Z<id>" — per
   ReactFlightServer's renderModel, thrown React nodes serialize as
   "$L" + errorId) and the row <id>:E{"digest":...} carries the error. */
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
