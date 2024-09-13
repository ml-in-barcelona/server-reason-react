let () = {
  let handler =
    Dream.router([
      Dream.get("/", Home.handler),
      Dream.get(Router.renderToString, _request =>
        Dream.html(
          ReactDOM.renderToString(
            <Document script="/static/demo/client/bundle.js">
              <App />
            </Document>,
          ),
        )
      ),
      Dream.get(Router.renderToStaticMarkup, _request =>
        Dream.html(
          ReactDOM.renderToStaticMarkup(
            <Document script="/static/demo/client/bundle.js">
              <App />
            </Document>,
          ),
        )
      ),
      Dream.get(Router.renderToLwtStream, _request =>
        Dream.stream(
          ~headers=[("Content-Type", "text/html")],
          response_stream => {
            open Lwt.Syntax;
            let* (stream, _abort) =
              ReactDOM.renderToLwtStream(<Document> <Comments /> </Document>);

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
      Dream.get(
        Router.serverComponentsWithoutClient,
        request => {
          let app =
            <Document script="/static/demo/client/rsc.js">
              <div
                className="flex flex-col items-center justify-center h-full">
                <h1 className="text-white font-bold text-4xl">
                  {React.string(string_of_float(Unix.gettimeofday()))}
                </h1>
              </div>
            </Document>;

          Dream.stream(response_stream => {
            let%lwt (stream, _abort) = ReactServerDOM.render(app);

            /* TODO: Maybe we could make this iter inside ReactServerDOM */
            stream
            |> Lwt_stream.iter_s(data => {Dream.write(response_stream, data)});
          });
        },
      ),
      Dream.get(
        "/static/**",
        Dream.static("./_build/default/demo/client/app"),
      ),
    ]);

  Dream.run(
    ~port=8080,
    ~interface={
      switch (Sys.getenv_opt("SERVER_INTERFACE")) {
      | Some(env) => env
      | None => "localhost"
      };
    },
    ~error_handler=Error.handler,
    Dream.livereload(Dream.logger(handler)),
  );
};
