/* preconnect(href) without crossOrigin emits `:HC"<href>"` (the payload is a
   bare JSON string; the [href, crossOrigin] tuple form only appears when
   crossOrigin is a string). */
module App = {
  [@react.component]
  let make = () => {
    Spec.preconnect(~href="https://example.com");
    <div> {React.string("connected")} </div>;
  };
};

let app = () => <App />;
