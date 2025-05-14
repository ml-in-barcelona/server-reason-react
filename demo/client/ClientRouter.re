module DOM = Webapi.Dom;
module Location = DOM.Location;
module History = DOM.History;
module ReadableStream = Webapi.ReadableStream;

[@mel.scope "window"] [@mel.set]
external setNavigate: (Webapi.Dom.Window.t, string => unit) => unit =
  "__navigate";

[@mel.module "react"]
external startTransition: (unit => unit) => unit = "startTransition";
external readable_stream: ReadableStream.t =
  "window.srr_stream.readable_stream";

let fetchApp = url => {
  let headers =
    Fetch.HeadersInit.make({"Accept": "application/react.component"});
  Fetch.fetchWithInit(
    url,
    Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
  );
};

module App = {
  let initialData =
    ReactServerDOMEsbuild.createFromReadableStream(readable_stream);

  [@react.component]
  let make = () => {
    let initialElement = React.Experimental.use(initialData);
    let (data, setData) = React.Uncurried.useState(() => initialElement);

    let navigate = search => {
      let location = DOM.window->DOM.Window.location;
      let currentSearch = Location.search(location);
      if (currentSearch == "?" ++ search) {
        ();
      } else {
        let origin = Location.origin(location);
        let pathname = Location.pathname(location);
        let currentURL = origin ++ pathname;
        let url = URL.makeExn(currentURL)->URL.setSearchAsString(search);
        let app = fetchApp(URL.toString(url));
        let element = ReactServerDOMEsbuild.createFromFetch(app);
        startTransition(() => {
          setData(. _ => element);
          History.pushState(
            History.state(DOM.history),
            "",
            URL.toString(url),
            DOM.history,
          );
        });
        ();
      };
    };

    /* Publish navigate fn into window.__navigate */
    setNavigate(Webapi.Dom.window, navigate);

    <ReasonReactErrorBoundary
      fallback={_error => <h1> {React.string("Something went wrong")} </h1>}>
      data
    </ReasonReactErrorBoundary>;
  };
};

let body =
  Webapi.Dom.document
  ->Webapi.Dom.Document.asHtmlDocument
  ->Option.bind(Webapi.Dom.HtmlDocument.body);

[@mel.module "react-dom/client"]
external hydrateRoot:
  (Dom.element, React.element, Js.t({..})) => ReactDOM.Client.root =
  "hydrateRoot";

switch (body) {
| Some(element) =>
  startTransition(() => {
    let onRecoverableError = (error, errorInfo) => {
      Js.log2(error, errorInfo);
    };
    let _ =
      hydrateRoot(
        element,
        <App />,
        {"onRecoverableError": onRecoverableError},
      );
    ();
  })
| None => Js.log("Root element not found")
};
