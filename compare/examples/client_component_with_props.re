module Component = {
  [@react.client.component]
  let make = () => {
    <div> {React.string("Hello from client")} </div>;
  };
};

[@react.component]
let make = () => {
  <Component />;
};
