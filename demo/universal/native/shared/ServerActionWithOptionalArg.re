[@react.client.component]
let make = () => {
  let (message, setMessage) = RR.useStateValue("");
  let (isLoading, setIsLoading) = RR.useStateValue(false);

  <div className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
    <Stack gap=2 justify=`start>
      <div className="flex gap-2">
        <button
          className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
          onClick={_ => {
            setIsLoading(true);
            ServerFunctions.withOptionalGreeting.call(~name="Lola", ())
            |> Js.Promise.then_(response => {
                 setIsLoading(false);
                 setMessage(response);
                 Js.Promise.resolve();
               })
            |> ignore;
          }}>
          {React.string("Without greeting (uses default)")}
        </button>
        <button
          className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
          onClick={_ => {
            setIsLoading(true);
            ServerFunctions.withOptionalGreeting.call(
              ~greeting="Hola",
              ~name="Lola",
              (),
            )
            |> Js.Promise.then_(response => {
                 setIsLoading(false);
                 setMessage(response);
                 Js.Promise.resolve();
               })
            |> ignore;
          }}>
          {React.string("With greeting \"Hola\"")}
        </button>
      </div>
      <div> <Text> {isLoading ? "Loading..." : message} </Text> </div>
    </Stack>
  </div>;
};
