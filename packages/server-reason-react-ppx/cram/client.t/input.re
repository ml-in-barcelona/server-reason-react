module Sequence = {
  let props_to_json = (~lola: int, ()) => [
    ("lola", React.Json(`Int(lola))),
  ];

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
