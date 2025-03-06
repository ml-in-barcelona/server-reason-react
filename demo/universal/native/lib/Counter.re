open Ppx_deriving_json_runtime.Primitives;

[@react.server.action]
let onClickServerAction =
    (~foo as a: string, ~bar: int): Js.Promise.t(string) => {
  Js.Promise.resolve(a ++ string_of_int(bar));
};

[@react.client.component]
let make = (~initial: int) => {
  let (state, setCount) = RR.useStateValue(initial);

  let onClick = _event => {
    onClickServerAction(~foo="foo", ~bar=1)
    |> Js.Promise.then_(result => {
         Js.log("############" ++ result);
         Js.Promise.resolve();
       })
    |> ignore;
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
