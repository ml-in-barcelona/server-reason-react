[@react.component]
let make = (~initial) => {
  let (count, setCount) = RR.useStateValue(initial);

  switch%platform (Runtime.platform) {
  | Server => print_endline("This prints to the terminal")
  | Client => print_endline("This prints to the console")
  };

  let onClick = () => {
    // For sample purposes take a look on this comment and the one on line 36
    // This Js.log(1); should throw an error
    // because we have no browser%only or switch%platform
    // uncomment the line below and see the error
    // Js.log(1);
    setCount(
      count + 1,
    );
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
          onClick={_ => {
            // For sample purposes take a look on this comment and the one on line 11
            // This Js.log(1); should throw an error
            // but as all event callbacks are not called on native.
            // uncomment the line below and see that it doesn't throw any error
            // Js.log(1);
            onClick()
          }}>
          {React.string(Int.to_string(count))}
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
