/* Within one flush React writes import (I) rows before hint (H) rows
   regardless of call order: a preload issued before the client reference is
   encountered still streams after the I row (imports, then hints, then
   regular rows). */
module App = {
  [@react.component]
  let make = () => {
    Spec.preload(~href="/before-ref.css", ~as_="style", ());
    <div>
      {Spec.client_component(
         ~importModule="spec/Button.js",
         ~importName="default",
         (),
       )}
    </div>;
  };
};

let app = () => <App />;
