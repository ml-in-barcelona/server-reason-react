let root =
  Webapi.Dom.document
  |> Webapi.Dom.Document.querySelector("#root")
  |> Option.get;

let root = ReactDOM.Client.createRoot(root);
let headers =
  Fetch.HeadersInit.make({"Accept": "application/react.component"});
let fetch =
  Fetch.fetchWithInit(
    Router.demoCreateFromFetch,
    Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
  );
let app = ReactServerDOMEsbuild.createFromFetch(fetch);
ReactDOM.Client.render(root, app);
