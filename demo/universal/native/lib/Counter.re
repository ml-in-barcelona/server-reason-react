[@warning "-27"];

let make = (~initial) => {
  let (state, setCount) = RR.useStateValue(initial);

  let onClick = _event => {
    setCount(state + 1);
  };

  <div className={Theme.text(Theme.Color.white)}>
    <Spacer bottom=3>
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
    <p className="text-lg">
      {React.string(
         "The HTML (including counter value) comes first from the server"
         ++ " then is updated by React after render or hydration (depending if you are running ReactDOM.render or ReactDOM.hydrate on the client).",
       )}
    </p>
  </div>;
};

[@react.component]
let make = (~initial) =>
  switch%platform (Runtime.platform) {
  | Server =>
    React.Client_component({
      import_module: "Counter",
      import_name: "",
      props: [("initial", React.Json(`Int(initial)))],
      client: make(~initial),
    })
  | Client => make(~initial)
  };

/* switch%platform (Runtime.platform) {
   | Server => ()
   | Client =>
     Components.register("Counter", (props: Js.t({..})) => {
       React.jsx(make, makeProps(~initial=props##initial, ()))
     })
   };
    */
