type callServer = ReactServerDOMEsbuild.callServer;
type decodeNavigation =
  (RouterRuntime.NavigationResponse.kind, RSC.t) =>
  RouterRuntime.NavigationResponse.t(React.element);

type value = {
  callServer,
  decodeNavigation,
};

let context: React.Context.t(option(value)) = React.createContext(None);
let provider = React.Context.provider(context);

module Provider = {
  [@react.component]
  let make = (~callServer, ~decodeNavigation, ~children) =>
    React.createElement(
      provider,
      {
        "value":
          Some({
            callServer,
            decodeNavigation,
          }),
        "children": children,
      },
    );
};

let useCallServer = () =>
  switch (React.useContext(context)) {
  | Some(value) => value.callServer
  | None =>
    raise(
      Invalid_argument(
        "RouterReact.Provider requires an ancestor FlightProvider.Provider",
      ),
    )
  };

let useNavigationDecoder = () =>
  switch (React.useContext(context)) {
  | Some(value) => value.decodeNavigation
  | None =>
    raise(
      Invalid_argument(
        "RouterReact.Provider requires an ancestor FlightProvider.Provider",
      ),
    )
  };

let decode = (~callServer, stream) =>
  ReactServerDOMEsbuild.createFromReadableStream(~callServer, stream);
