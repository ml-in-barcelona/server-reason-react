let buttonClass = "font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800";

[@react.client.component]
let make = () => {
  let (sessionUser, setSessionUser) = RR.useStateValue("");
  let (userAgent, setUserAgent) = RR.useStateValue("");
  let (cookieResult, setCookieResult) = RR.useStateValue("");
  let (nameInput, setNameInput) = RR.useStateValue("Lola");
  let (isLoading, setIsLoading) = RR.useStateValue(false);

  <div className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
    <Stack gap=4 justify=`start>
      <Stack gap=2 justify=`start>
        <h3 className="text-lg font-semibold">
          {React.string("Read cookies & headers")}
        </h3>
        <button
          className=buttonClass
          onClick={_ => {
            setIsLoading(true);
            ServerFunctions.getSessionUser.call()
            |> Js.Promise.then_(response => {
                 setSessionUser(response);
                 ServerFunctions.getUserAgent.call()
                 |> Js.Promise.then_(response => {
                      setIsLoading(false);
                      setUserAgent(response);
                      Js.Promise.resolve();
                    });
               })
            |> ignore;
          }}>
          {React.string("Read request context")}
        </button>
        <div> <Text> {isLoading ? "Loading..." : sessionUser} </Text> </div>
        {userAgent != ""
           ? <div>
               <Text size=Small color=Theme.Color.Gray10>
                 {"User-Agent: " ++ userAgent}
               </Text>
             </div>
           : React.null}
      </Stack>
      <Stack gap=2 justify=`start>
        <h3 className="text-lg font-semibold">
          {React.string("Set a cookie")}
        </h3>
        <Row gap=2>
          <input
            type_="text"
            value=nameInput
            onChange={e => {
              let value = React.Event.Form.target(e)##value;
              setNameInput(value);
            }}
            className="font-mono border-2 py-1 px-2 rounded-lg bg-gray-900 border-gray-700 text-gray-200"
            placeholder="Enter a name"
          />
          <button
            className=buttonClass
            onClick={_ => {
              ServerFunctions.setSessionUser.call(~name=nameInput)
              |> Js.Promise.then_(response => {
                   setCookieResult(response);
                   Js.Promise.resolve();
                 })
              |> ignore
            }}>
            {React.string("Set demo_user cookie")}
          </button>
        </Row>
        {cookieResult != ""
           ? <div> <Text color=Theme.Color.Gray10> cookieResult </Text> </div>
           : React.null}
        {cookieResult != ""
           ? <div>
               <Text size=Small color=Theme.Color.Gray10>
                 "Click 'Read request context' again to see the updated cookie value."
               </Text>
             </div>
           : React.null}
      </Stack>
    </Stack>
  </div>;
};
