let renderToString =
  Dream.get(Router.renderToString, _request =>
    Dream.html(
      ReactDOM.renderToString(
        <Document script="/static/demo/client/app.js"> <App /> </Document>,
      ),
    )
  );

let renderToStaticMarkup =
  Dream.get(Router.renderToStaticMarkup, _request =>
    Dream.html(
      ReactDOM.renderToStaticMarkup(
        <Document script="/static/demo/client/app.js"> <App /> </Document>,
      ),
    )
  );

let renderToStream =
  Dream.get(Router.renderToStream, _request =>
    Dream.stream(
      ~headers=[("Content-Type", "text/html")],
      response_stream => {
        let%lwt (stream, _abort) =
          ReactDOM.renderToStream(<Document> <Comments /> </Document>);

        Lwt_stream.iter_s(
          data => {
            let%lwt () = Dream.write(response_stream, data);
            Dream.flush(response_stream);
          },
          stream,
        );
      },
    )
  );

let serverComponentsWithoutClient =
  Dream.get(
    Router.serverComponentsWithoutClient,
    request => {
      let isRSCheader =
        Dream.header(request, "Accept") == Some("text/x-component");

      let app =
        <Layout background=Theme.Color.black>
          <div
            className="flex flex-col items-center justify-center h-full gap-4">
            <span className="text-gray-400 text-center">
              {React.string(
                 "Return, from the server, the current time (in seconds) since",
               )}
              <br />
              {React.string("00:00:00 GMT, Jan. 1, 1970")}
            </span>
            <h1 className="text-white font-bold text-4xl">
              {React.string(string_of_float(Unix.gettimeofday()))}
            </h1>
          </div>
        </Layout>;

      if (isRSCheader) {
        Dream.stream(response_stream => {
          let%lwt initial =
            ReactServerDOM.to_model(
              ~subscribe=data => Dream.write(response_stream, data),
              app,
            );
          let%lwt () =
            Lwt_stream.iter_s(
              data => Dream.write(response_stream, data),
              initial,
            );
          Lwt.return();
        });
      } else {
        Dream.html(
          ReactDOM.renderToString(
            <Document script="/static/demo/client/rsc-without-client.js">
              React.null
            </Document>,
          ),
        );
      };
    },
  );

let serverComponents =
  Dream.get(
    Router.serverComponents,
    request => {
      let isRSCheader =
        Dream.header(request, "Accept") == Some("text/x-component");

      if (isRSCheader) {
        Dream.stream(response_stream => {
          let%lwt initial =
            ReactServerDOM.to_model(
              ~subscribe=data => Dream.write(response_stream, data),
              <Noter />,
            );
          let%lwt () =
            Lwt_stream.iter_s(
              data => Dream.write(response_stream, data),
              initial,
            );
          Lwt.return();
        });
      } else {
        Dream.html(
          ReactDOM.renderToString(
            <Document script="/static/demo/client/rsc-with-client.js">
              <Noter />
            </Document>,
          ),
        );
      };
    },
  );

let router = [
  Dream.get("/", Home.handler),
  Dream.get("/static/**", Dream.static("./_build/default/demo/client/app")),
  renderToString,
  renderToStaticMarkup,
  renderToStream,
  serverComponentsWithoutClient,
  serverComponents,
];

let () = {
  Dream.run(
    ~adjust_terminal=true,
    ~port=8080,
    ~interface={
      switch (Sys.getenv_opt("SERVER_INTERFACE")) {
      | Some(env) => env
      | None => "localhost"
      };
    },
    ~error_handler=Error.handler,
    Dream.livereload(Dream.logger(Dream.router(router))),
  );
};
