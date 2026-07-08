/* A synchronous throw inside a Suspense boundary: the Flight layer does not
   render the fallback; the boundary's children position becomes a lazy error
   reference "$L<id>" and the error row streams as <id>:E{"digest":...}.
   (Fallback handling is the client's job — the wire format only carries the
   errored reference.) */
module Boom = {
  [@react.component]
  let make = () => raise(Failure("boom"));
};

let app = () =>
  <React.Suspense fallback={<span> {React.string("will not help")} </span>}>
    <Boom />
  </React.Suspense>;
