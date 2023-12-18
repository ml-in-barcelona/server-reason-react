module App = {
  let context = React.createContext("default");
  module Provider = {
    include React.Context;
    let make = React.Context.provider(context);
  };

  module Aware = {
    [@react.component]
    let make = (~name) => {
      let value = React.useContext(context);

      <section>
        <span> {React.string(name)} </span>
        <span> {React.string(value)} </span>
      </section>;
    };
  };

  [@react.component]
  let make = () =>
    <Provider value="maybe no"> <Aware name="flores" /> </Provider>;
};

let app = ReactDOM.renderToStaticMarkup(<App />);

Js.Console.log("\n");
Js.Console.log("Demo output: --------------------------------- \n");
Js.Console.log(app);
Js.Console.log("");
Js.Console.log("---------------------------------------------- \n");
