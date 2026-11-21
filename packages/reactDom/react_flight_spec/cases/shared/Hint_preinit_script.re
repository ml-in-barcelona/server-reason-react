module App = {
  [@react.component]
  let make = () => {
    Spec.preinit_script(~href="/main.js");
    <div> {React.string("initialized")} </div>;
  };
};

let app = () => <App />;
