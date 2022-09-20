module Dummy = {
  [@react.component]
  let make = (~lola) => <div> {React.string(lola)} </div>;
};

[@react.component]
let make = () => <Dummy lola="flores" />;
