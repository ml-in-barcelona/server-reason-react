module Prop_with_many_annotation = {
  [@react.client.component]
  let make = (~initial: int, ~lola: lola) => {
    <div> {React.string(lola.name)} {React.int(initial)} </div>;
  };
};
