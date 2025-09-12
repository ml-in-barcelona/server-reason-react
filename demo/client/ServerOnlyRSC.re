let root =
  Webapi.Dom.document
  |> Webapi.Dom.Document.querySelector("#root")
  |> Option.get;

let root = ReactDOM.Client.createRoot(root);
let headers =
  Fetch.HeadersInit.make({"Accept": "application/react.component"});
let fetch =
  Fetch.fetchWithInit(
    Routes.serverOnlyRSC,
    Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
  );

ReactServerDOMEsbuild.createFromFetch(fetch)
|> Js.Promise.then_(app => {
     ReactDOM.Client.render(root, app);
     Js.Promise.resolve();
   })
|> ignore;
