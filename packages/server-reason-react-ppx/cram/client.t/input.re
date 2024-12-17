module Sequence = {
  [@react.component]
  [@react.client.component]
  let make = (~lola: int) => {
    let (state, setState) = React.useState(lola);

    React.useEffect(() => {
      setState(lola);
      None;
    });

    <div> {React.string(state)} </div>;
  };
};
