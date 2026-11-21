module App = {
  [@react.component]
  let make = () => {
    Spec.preconnect(~href="https://example.com");
    <div> {React.string("connected")} </div>;
  };
};

let app = () => <App />;
