[@react.client.component]
let make =
    (
      ~actionOnClick:
         Runtime.server_function(
           (~name: string, ~age: int) => Js.Promise.t(string),
         ),
      ~optionalAction:
         option(Runtime.server_function(unit => Js.Promise.t(string)))=?,
    ) => {
  let (isLoading, setIsLoading) = RR.useStateValue(false);
  let (message, setMessage) = RR.useStateValue("");
  <div>
    <button
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
      onClick={_ => {
        setIsLoading(true);
        actionOnClick.call(~name="Lola", ~age=20)
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
    {switch (optionalAction) {
     | Some(action) =>
       <button
         className="font-mono border-2 py-1 px-2 rounded-lg bg-green-950 border-green-700 text-green-200 hover:bg-green-800 ml-2"
         onClick={_ => {
           action.call()
           |> Js.Promise.then_(response => {
                Js.log(response);
                Js.Promise.resolve();
              })
           |> ignore
         }}>
         {React.string("Optional action")}
       </button>
     | None => React.null
     }}
    <div className="mb-4" />
    <div> <Text> {isLoading ? "Loading..." : message} </Text> </div>
  </div>;
};
