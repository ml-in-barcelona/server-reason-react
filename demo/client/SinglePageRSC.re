module App = {
  [@react.component]
  let make = (~promise) => {
    React.Experimental.use(promise);
  };
};

external readable_stream: Webapi.ReadableStream.t =
  "window.srr_stream.readable_stream";

[@mel.module "react"]
external startTransition: (unit => unit) => unit = "startTransition";

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

try({
  let promise =
    ReactServerDOMEsbuild.createFromReadableStream(
      ~callServer,
      readable_stream,
    );

  let document: option(Webapi.Dom.Element.t) = [%mel.raw "window.document"];

  switch (document) {
  | Some(elem) =>
    startTransition(() => {
      let app = <App promise />;
      let _ = ReactDOM.Client.hydrateRoot(elem, app);
      ();
    })
  | None => Js.log("No root element found")
  };
}) {
| exn =>
  switch (Js.Exn.asJsExn(exn)) {
  | Some(error) =>
    Js.log2("Error type:", Js.Exn.name(error));
    Js.log2("Stack:", Js.Exn.stack(error));
    Js.log2("Full error:", error);
  | None =>
    Js.log("No JavaScript exception, got:");
    Js.log(exn);
  }
};
