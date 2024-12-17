
  $ ../ppx.sh --output re input.re
  module Sequence = {
    let props_to_json = (~lola: int, ()) => [
      ("lola", React.Json(`Int(lola))),
    ];
    let make = (~key as _: option(string)=?, ~lola: int, ()) =>
      React.Client_component({
        import_module: __MODULE__,
        import_name: "",
        props: props_to_json(~lola, ()),
        client: {
          let (state, setState) = React.useState(lola);
          React.useEffect(() => {
            setState(lola);
            None;
          });
          React.createElement("div", [], [React.string(state)]);
        },
      });
  };
