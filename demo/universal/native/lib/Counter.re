open Ppx_deriving_json_runtime.Primitives;

[@react.client.component]
let make = (~initial: int) => {
  let (state, [@browser_only] setCount) = RR.useStateValue(initial);

  [@browser_only]
  let onClick = _ => {
    setCount(state + 1);
    Js.log2("Printing count", state);
  };

  <Row align=`center gap=2>
    <Text color=Theme.Color.white> "A classic counter" </Text>
    <button
      onClick={[@browser_only] e => onClick(e)}
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800">
      {React.string(Int.to_string(state))}
    </button>
  </Row>;
};
