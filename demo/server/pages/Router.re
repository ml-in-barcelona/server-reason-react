module Layout = {
  [@react.component]
  let make = (~children) => {
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <link rel="stylesheet" href="/output.css" />
      </head>
      <body> <DemoLayout> children </DemoLayout> </body>
    </html>;
  };
};

let handler = (~element, request) => {
  let ssr =
    Dream.query(request, "ssr")
    |> Option.map(v => v == "false")
    |> Option.value(~default=true);

  DreamRSC.createFromRequest(
    ~disableSSR=!ssr,
    ~bootstrapModules=["/static/demo/Router.re.js"],
    ~layout=children => <Layout> children </Layout>,
    element,
    request,
  );
};
