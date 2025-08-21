module App = {
  [@react.async.component]
  let make = () => {
    Lwt.return(
      <DemoLayout background=Theme.Color.Gray2 mode=FullScreen>
        <div className="flex flex-row gap-8" />
      </DemoLayout>,
    );
  };
};

let handler = request => {
  DreamRSC.createFromRequest(
    ~bootstrapModules=["/static/demo/RouterRSC.re.js"],
    ~layout=
      children =>
        <html lang="en">
          <head>
            <meta charSet="utf-8" />
            <link rel="stylesheet" href="/output.css" />
          </head>
          <body> children </body>
        </html>,
    <App />,
    request,
  );
};
