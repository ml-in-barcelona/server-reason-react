let make = (~initial, ~onClick as [@browser_only] onClick) => {
  let (count, [@browser_only] setCount) = RR.useStateValue(initial);

  [@browser_only]
  let onClick = e => {
    setCount(count + 1);
    Js.log2("Printing count", count);

    onClick(e);
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
          className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200"
          onClick={[@browser_only] e => onClick(e)}>
          {React.string(Int.to_string(count))}
        </button>
      </div>
    </Spacer>
    <p className="text-lg">
      {React.string(
         "The HTML comes from the server"
         ++ " then is updated by the client after React runs. Via render or hydration (when using ReactDOM.hydrateRoot).",
       )}
    </p>
  </div>;
};

[@react.component]
let make = (~initial, ~onClick as [@browser_only] onClick) =>
  switch%platform (Runtime.platform) {
  | Server =>
    React.Client_component({
      import_module: "Counter",
      import_name: "",
      props: [("initial", React.Json(`Int(initial)))],
      client: make(~initial, ~onClick=_ => ()),
    })
  | Client => make(~initial, ~onClick)
  };

let default = make;

/* switch%platform (Runtime.platform) {
   | Server => ()
   | Client =>
     Components.register("Counter", (props: Js.t({..})) => {
       React.jsx(make, makeProps(~initial=props##initial, ()))
     })
   };
    */
