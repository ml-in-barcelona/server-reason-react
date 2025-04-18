open Melange_json.Primitives;

[@react.client.component]
let make = (~initial: int) => {
  let (state, [@browser_only] setCount) = RR.useStateValue(initial);

  let onClick = _ => {
    switch%platform () {
    | Client => setCount(state + 1)
    | Server => ()
    };
  };

  <Row align=`center gap=2>
    <Text color=Theme.Color.Gray11> "A classic counter" </Text>
    <Button noteId=None> {React.string("Click me")} </Button>
    <button
      onClick={e => onClick(e)}
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800">
      {React.string(Int.to_string(state))}
    </button>
  </Row>;
};
