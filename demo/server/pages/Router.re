open Supersonic;

// Layout will be handled by the navigation not by the render_html
module Layout = {
  [@react.component]
  let make = (~children) => {
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <link rel="stylesheet" href="/output.css" />
      </head>
      <body>
        <DemoLayout>
          <Navigation />
          <Router> <RouteDefinitions /> children </Router>
        </DemoLayout>
      </body>
    </html>;
  };
  /* <Route
       path="/app"
       loader={() => {
         fetchApp("/app")
         |> Js.Promise.then_(response => {
              let body = Fetch.Response.body(response);
              ReactServerDOMEsbuild.createFromReadableStream(body);
            })
       }}
     /> */
};

let handler = (~element, request) => {
  let ssr =
    Dream.query(request, "ssr")
    |> Option.map(v => v == "false")
    |> Option.value(~default=true);

  /* let sleep =
     Dream.query(request, "sleep")
     ->Option.bind(Float.of_string_opt)
     ->Option.bind(value =>
         if (value < 0.) {
           None;
         } else {
           Some(value);
         }
       ); */

  DreamRSC.createFromRequest(
    ~disableSSR=!ssr,
    ~bootstrapModules=["/static/demo/Router.re.js"],
    React.Model.Element(element),
    request,
  );
};
