[@react.client.component]
let make = () => {
  let (message, setMessage) = RR.useStateValue("");
  let (isLoading, setIsLoading) = RR.useStateValue(false);

  <div className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
    <button
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
      onClick={_ => {
        setIsLoading(true);
        ServerFunctions.Samples.simpleResponse.call(. ~name="Lola", ~age=20)
        |> Js.Promise.then_(response => {
             setIsLoading(false);
             setMessage(response);
             Js.Promise.resolve();
           })
        |> ignore;
      }}>
      {React.string("Click to get the server response")}
    </button>
    <div> <Text> {isLoading ? "Loading..." : message} </Text> </div>
  </div>;
};
