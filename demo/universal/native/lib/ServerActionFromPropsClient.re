[@react.client.component]
let make =
    (
      ~actionOnClick:
         Runtime.server_function(
           (. ~name: string, ~age: int) => Js.Promise.t(string),
         ),
    ) => {
  let (isLoading, setIsLoading) = RR.useStateValue(false);
  let (message, setMessage) = RR.useStateValue("");
  <div>
    <button
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
      onClick={_ => {
        setIsLoading(true);
        actionOnClick.call(. ~name="Lola", ~age=20)
        |> Js.Promise.then_(response => {
             setIsLoading(false);
             Js.log(response);
             setMessage(response);
             Js.Promise.resolve();
           })
        |> ignore;
      }}>
      {React.string("Click me to get a message from the server")}
    </button>
    <div className="mb-4" />
    <div> <Text> {isLoading ? "Loading..." : message} </Text> </div>
  </div>;
};
