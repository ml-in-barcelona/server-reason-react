open Ppx_deriving_json_runtime.Primitives;

[@react.client.component]
let make = (~initial: int) => {
  let (state, setCount) = RR.useStateValue(initial);

  let onClick = _event => {
    setCount(state + 1);
  };

  <Row align=`center gap=2>
    <Text color=Theme.Color.Gray11> "A classic counter" </Text>
    <button
      onClick
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800">
      {React.string(Int.to_string(state))}
    </button>
  </Row>;
};
