let props_to_json = (~initial, ()) => {
  switch%platform (Runtime.platform) {
  | Server => [("initial", React.Json(`Int(initial)))]
  | Client =>
    Js.log(initial);
    [];
  };
};

[@react.component]
[@react.client.component]
let make = (~initial: int) => {
  let (state, setCount) = RR.useStateValue(initial);

  let onClick = _event => {
    setCount(state + 1);
  };

  <div className={Theme.text(Theme.Color.white)}>
    <Spacer bottom=0>
      <div
        className={Cx.make([
          "flex",
          "justify-items-end",
          "items-center",
          "gap-4",
        ])}>
        <p className={Cx.make(["m-0", "text-3xl", "font-bold"])}>
          {React.string("Counter")}
        </p>
        <button
          onClick
          className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200">
          {React.string(Int.to_string(state))}
        </button>
      </div>
    </Spacer>
  </div>;
};
