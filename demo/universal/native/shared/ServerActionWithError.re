[@react.client.component]
let make = () => {
  <div className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
    <button
      className="cursor-pointer font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
      onClick=[%browser_only
        _ => {
          ServerFunctions.Samples.error.call() |> ignore;
        }
      ]>
      {React.string("Click to trigger error, see it on the console")}
    </button>
  </div>;
};
