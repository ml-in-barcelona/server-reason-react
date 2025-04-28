[@react.client.component]
let make = () => {
  let (message, setMessage) = RR.useStateValue("");

  <div className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
    <button
      className="cursor-pointer font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
      onClick=[%browser_only
        _ => {
          ServerFunctions.Samples.simpleResponse()
          |> Js.Promise.then_(response => {
               setMessage(response);
               Js.Promise.resolve();
             })
          |> ignore;
        }
      ]>
      {React.string("Action with simple response")}
    </button>
    <div> <Text> message </Text> </div>
  </div>;
};
