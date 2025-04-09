[@react.client.component]
let make =
    (~actionOnClick: [@react.server.action] (unit => Js.Promise.t(string))) => {
  let (isLoading, setIsLoading) = RR.useStateValue(false);
  let (message, setMessage) = RR.useStateValue("aasa");
  <div>
    <button
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
      type_="submit"
      onClick=[%browser_only
        _ => {
          setIsLoading(true);
          actionOnClick()
          |> Js.Promise.then_(response => {
               setIsLoading(false);
               Js.log(response);
               setMessage(response);
               Js.Promise.resolve();
             })
          |> ignore;
        }
      ]>
      {React.string("Click me to get a message from the server")}
    </button>
    <Spacer bottom=4 />
    <div> <Text> {isLoading ? "Loading..." : message} </Text> </div>
  </div>;
};
