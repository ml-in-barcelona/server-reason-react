module Greeting: {
  [@react.component]
  let make: (~mockup: string=?) => React.element;
} = {
  [@react.component]
  let make = (~mockup: option(string)=?) => {
    <button> {React.string("Hello!")} </button>;
  };
};

module MyPropIsOptionOptionBoolLetWithValSig: {
  [@react.component]
  let make: (~myProp: option(bool)=?) => React.element;
} = {
  [@react.component]
  let make = (~myProp: option(option(bool))=?) => React.null;
};
