let _ = MelRaw.initWebsocket();

module Counter = {
  [@react.component]
  let make = () => {
    let (count, setCount) = RR.useStateValue(0);

    <div>
      <p>
        {React.string(
           "Wat" ++ " clicked " ++ Int.to_string(count) ++ " times",
         )}
      </p>
      <button onClick={_ => setCount(count + 1)}>
        {React.string("Click me")}
      </button>
    </div>;
  };
};

switch (ReactDOM.querySelector("#root")) {
| Some(el) =>
  let _root = ReactDOM.Client.hydrateRoot(el, <App />);
  ();
| None => ()
};
