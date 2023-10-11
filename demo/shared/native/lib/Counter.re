[@react.component]
let make = () => {
  let (count, setCount) = React.useState(() => 23);

  let onClick = event => {
    let _target = ReactEvent.Mouse.target(event);
    print_endline("Console works too! " /* ++ target##value */);
    setCount(_ => count + 1);
  };

  <div className="text-yellow-600">
    <div
      className={Cx.make([
        "flex",
        "justify-items-end",
        "items-center",
        "gap-4",
      ])}>
      <p className={Cx.make(["margin-0", "text-3xl", "font-bold"])}>
        {React.string("Counter")}
      </p>
      <button onClick> {React.string(Int.to_string(count))} </button>
    </div>
    <p className="text-lg">
      {React.string(
         "The HTML (including counter value) comes first from the server"
         ++ " then is updated by React after render or hydration (depending if you are running ReactDOM.render or ReactDOM.hydrate on the client).",
       )}
    </p>
  </div>;
};
