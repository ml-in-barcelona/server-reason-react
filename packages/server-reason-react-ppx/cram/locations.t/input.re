[@warning "-32"];

[@react.component]
let make = (~lola) => {
  <div> {React.string(lola)} </div>;
};

[@react.component]
let make = (~initialValue=0, ()) => {
  let (value, setValue) = React.useState(() => initialValue);

  <button onClick={_ => setValue(value => value + 1)}>
    value->React.int
  </button>;
};

module Uppercase = {
  [@react.component]
  let make = (~children as upperCaseChildren) => {
    <div> upperCaseChildren </div>;
  };
};

let a = <Uppercase> <div /> </Uppercase>;
