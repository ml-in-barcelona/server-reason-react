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

      <div>
        <span> {React.string(lola)} </span>
        <span> {React.string(ctx_value)} </span>
      </div>;
    };
  };

  [@react.component]
  let make = () =>
    <Provider value="maybe no"> <Dummy lola="flores" /> </Provider>;
};

let app = ReactDOM.renderToStaticMarkup(<App />);
Js.Console.log(app);
