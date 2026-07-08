/* A sync throw two components DOWN the root chain: function components at the
   task root render destructively (renderFunctionComponent recurses without a
   catching boundary), so the throw still errors the root task itself — a
   single 0:E{...} row, exactly like error_component. */
module Boom = {
  [@react.component]
  let make = () => raise(Failure("chained boom"));
};

module App = {
  [@react.component]
  let make = () => <Boom />;
};

let app = () => <App />;
