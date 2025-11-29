module DOM = Webapi.Dom;
module Location = DOM.Location;
module History = DOM.History;
module ReadableStream = Webapi.ReadableStream;

[@mel.scope "window"] [@mel.set]
external setNavigate: (Webapi.Dom.Window.t, string => unit) => unit =
  "__navigate";

external readable_stream: ReadableStream.t =
  "window.srr_stream.readable_stream";

let fetchApp = url => {
  let headers =
    Fetch.HeadersInit.make({ "Accept": "application/react.component" });
  Fetch.fetchWithInit(
    url,
    Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
  );
};

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

module App = {
  let initialRSCModel =
    ReactServerDOMEsbuild.createFromReadableStream(
      ~callServer,
      readable_stream,
    );

  [@react.component]
  let make = () => {
    let initialElement = React.Experimental.usePromise(initialRSCModel);
    let (layout, setLayout) = React.useState(() => initialElement);

    let navigate = search => {
      let location = DOM.window->DOM.Window.location;
      let origin = Location.origin(location);
      let pathname = Location.pathname(location);

      let currentSearch = Location.search(location);
      let currentParams = URL.SearchParams.makeExn(currentSearch);

      let newSearchParams = Js.Dict.empty();

      URL.SearchParams.forEach(currentParams, (value, key) => {
        Js.Dict.set(newSearchParams, key, value)
      });

      let newParams = URL.SearchParams.makeExn(search);
      URL.SearchParams.forEach(newParams, (value, key) => {
        Js.Dict.set(newSearchParams, key, value)
      });

      let finalSearch =
        newSearchParams
        |> Js.Dict.entries
        |> URL.SearchParams.makeWithArray
        |> URL.SearchParams.toString;

      if (currentSearch == "?" ++ finalSearch) {
        ();
      } else {
        let finalURL =
          URL.makeExn(origin ++ pathname)
          ->URL.setSearchAsString(finalSearch);
        let response = fetchApp(URL.toString(finalURL));
        ReactServerDOMEsbuild.createFromFetch(response)
        |> Js.Promise.then_(element => {
             History.pushState(
               History.state(DOM.history),
               "",
               URL.toString(finalURL),
               DOM.history,
             );
             setLayout(_ => element);
             Js.Promise.resolve();
           })
        |> ignore;
        ();
      };
    };

    /* Publish navigate fn into window.__navigate */
    setNavigate(Webapi.Dom.window, navigate);

    <ReasonReactErrorBoundary
      fallback={error => {
        Js.log(error);
        <h1> {React.string("Something went wrong")} </h1>;
      }}>
      layout
    </ReasonReactErrorBoundary>;
  };
};

let document: option(Webapi.Dom.Element.t) = [%mel.raw "window.document"];

let body =
  Webapi.Dom.document
  ->Webapi.Dom.Document.asHtmlDocument
  ->Option.bind(Webapi.Dom.HtmlDocument.body);

switch (document) {
| Some(element) =>
  React.startTransition(() => {
    let _ = ReactDOM.Client.hydrateRoot(element, <App />);
    ();
  })
| None => Js.log("Root element not found")
};
