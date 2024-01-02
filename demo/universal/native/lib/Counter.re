[@react.component]
let make = () => {
  let (count, setCount) = React.useState(() => 23);

  switch%platform (Runtime.platform) {
  | Server => print_endline("This prints to the terminal")
  | Client => print_endline("This prints to the console ")
  };

  let%browser_only onClick = event => {
    let target = React.Event.Mouse.target(event);
    let currentValue = target##value;
    setCount(_ => currentValue + 1);
  };

  <div className="text-yellow-600">
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
        <button onClick> {React.string(Int.to_string(count))} </button>
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
