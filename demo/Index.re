module App = {
  let context = React.createContext("default");
  module Provider = {
    include React.Context;
    let make = React.Context.provider(context);
  };

  module Dummy = {
    [@react.component]
    let make = (~lola) => {
      let ctx_value = React.useContext(context);

      <section>
        <h1> {React.int(Shared_native.MelRaw.x)} </h1>
        <span> {React.string(lola)} </span>
        <span> {React.string(ctx_value)} </span>
      </section>;
    };
  };

  [@react.component]
  let make = () =>
    <Provider value="maybe no"> <Dummy lola="flores" /> </Provider>;
};

let app = ReactDOM.renderToStaticMarkup(<App />);

Js.Console.log("\n");
Js.Console.log("Demo output: --------------------------------- \n");
Js.Console.log(app);
Js.Console.log("");
Js.Console.log("---------------------------------------------- \n");
