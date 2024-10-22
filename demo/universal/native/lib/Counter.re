[@react.component]
let make = (~initial) => {
  let (count, setCount) = RR.useStateValue(initial);

  switch%platform (Runtime.platform) {
  | Server => ()
  | Client => print_endline("This prints to the console")
  };

  let onClick = _event => {
    Js.log2("CLICKED!", Int.to_string(count));
    setCount(count + 1);
  };

  React.useEffect0(() => {
    Js.log2("Use effect, count is", Int.to_string(count));
    None;
  });

  React.useEffect(() => {
    Js.log2("count is", Int.to_string(count));
    None;
  });

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
