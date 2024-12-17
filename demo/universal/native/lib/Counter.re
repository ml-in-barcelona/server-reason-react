[@warning "-27"];

[@react.component]
let make = (~initial: int) =>
  switch%platform (Runtime.platform) {
  | Server =>
    React.Client_component({
      import_module: "Counter",
      import_name: "",
      props: [("initial", React.Json(`Int(initial)))],
      client: {
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
      },
    })
  | Client =>
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
