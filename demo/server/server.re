let globalStyles = {js|
  html, body, #root {
    margin: 0;
    padding: 0;
    width: 100vw;
    height: 100vh;
  }

  * {
    font-family: -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    box-sizing: border-box;
  }

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }
|js};

module Page = {
  [@react.component]
  let _make = (~children, ~scripts=[]) => {
    <html>
      <head>
        <meta charSet="UTF-8" />
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1.0"
        />
        <title> {React.string("Server Reason React demo")} </title>
        <link
          rel="shortcut icon"
          href="https://reasonml.github.io/img/icon_50.png"
        />
        <style
          type_="text/css"
          dangerouslySetInnerHTML={"__html": globalStyles}
        />
        <script src="https://cdn.tailwindcss.com" />
      </head>
      <body>
        <div id="root"> children </div>
        {scripts |> List.map(src => <script src />) |> React.list}
      </body>
    </html>;
  };
};

/* let handler =
     Dream.router([
       Dream.get("/", _request =>
         Dream.html(
           ReactDOM.renderToString(
             <Page scripts=["/static/app.js"]> <Shared_native.App /> </Page>,
           ),
         )
       ),
       Dream.get("/header", _request =>
         Dream.html(
           ReactDOM.renderToString(
             <Page scripts=["/static/header.js"]>
               <Shared_native.Ahrefs />
             </Page>,
           ),
         )
       ),
       Dream.get("/stream", _request =>
         Dream.stream(
           ~headers=[("Content-Type", "text/html")],
           response_stream => {
             let (stream, _) =
               ReactDOM.renderToLwtStream(<Page> <Comments.App /> </Page>);

             Lwt_stream.iter_s(
               data => {
                 let%lwt () = Dream.write(response_stream, data);
                 Dream.flush(response_stream);
               },
               stream,
             );
           },
         )
       ),
       Dream.get("/static/**", Dream.static("./static")),
     ]);

   let interface =
     switch (Sys.getenv_opt("SERVER_INTERFACE")) {
     | Some(env) => env
     | None => "localhost"
     };

   Dream.run(~port=8080, ~interface, handler);
    */
