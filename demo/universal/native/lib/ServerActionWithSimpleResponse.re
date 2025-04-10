[@warning "-26-27-32"];
[@react.client.component]
let make = () => {
  let (isLoading, setIsLoading) = RR.useStateValue(false);
  let (message, setMessage) = RR.useStateValue("");

  <div className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
    <button
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
      onClick=[%browser_only
        _ => {
          setIsLoading(true);
          Actions.Samples.simpleResponse()
          |> Js.Promise.then_(response => {
               setIsLoading(false);
               setMessage(response);
               Js.Promise.resolve();
             })
          |> ignore;
        }
      ]>
      {React.string("Click me to see a message from the server")}
    </button>
    <Spacer bottom=4 />
    <Text> message </Text>
  </div>;
};
