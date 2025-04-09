[@warning "-26-27-32"];
[@react.client.component]
let make =
    (~logOnServer: [@react.server.action] (string => Js.Promise.t(string))) => {
  <button
    className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
    onClick=[%browser_only
      _ => {
        logOnServer("Hello server") |> ignore;
      }
    ]>
    {React.string("Click to log on server")}
  </button>;
};
