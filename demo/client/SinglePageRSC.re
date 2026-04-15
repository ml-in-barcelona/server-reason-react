let callServer = (path: string, args) => {
  let headers =
    Fetch.HeadersInit.make({
      "Accept": "application/react.action",
      "ACTION_ID": path,
    });
  ReactServerDOMEsbuild.encodeReply(args)
  |> Js.Promise.then_(body => {
       let body = Fetch.BodyInit.make(body);
       Fetch.fetchWithInit(
         "/",
         Fetch.RequestInit.make(~method_=Fetch.Post, ~headers, ~body, ()),
       )
       |> Js.Promise.then_(result => {
            let body = Fetch.Response.body(result);
            ReactServerDOMEsbuild.createFromReadableStream(body);
          });
     });
};

let root =
  Webapi.Dom.document
  |> Webapi.Dom.Document.querySelector("#root")
  |> Option.get;

let root = ReactDOM.Client.createRoot(root);
let headers =
  Fetch.HeadersInit.make({ "Accept": "application/react.component" });
let fetch =
  Fetch.fetchWithInit(
    Routes.singlePageRSC,
    Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
  );

ReactServerDOMEsbuild.createFromFetch(~callServer, fetch)
|> Js.Promise.then_(app => {
     ReactDOM.Client.render(root, app);
     Js.Promise.resolve();
   })
|> ignore;
