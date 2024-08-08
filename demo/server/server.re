module Home = {
  [@react.component]
  let make = () => {
    <div className={Cx.make(["py-16", "px-12"])}>
      <Spacer bottom=8>
        <h1
          className={Cx.make([
            "font-bold text-4xl",
            Theme.text(Theme.Color.white),
          ])}>
          {React.string("Home of the demos")}
        </h1>
      </Spacer>
      <ul className="flex flex-col gap-4">
        <li>
          <Link.WithArrow href=Router.renderToStaticMarkup>
            Router.renderToStaticMarkup
          </Link.WithArrow>
        </li>
        <li>
          <Link.WithArrow href=Router.renderToString>
            Router.renderToString
          </Link.WithArrow>
        </li>
        <li>
          <Link.WithArrow href=Router.renderToLwtStream>
            Router.renderToLwtStream
          </Link.WithArrow>
        </li>
      </ul>
    </div>;
  };
};

module Error = {
  [@react.component]
  let make = (~error, ~debugInfo, ~suggestedResponse) => {
    let status = Dream.status(suggestedResponse);
    let code = Dream.status_to_int(status);
    let reason = Dream.status_to_string(status);
    <div className="py-16 px-12">
      <main>
        <Spacer bottom=8>
          <h1
            className={Cx.make([
              "font-bold text-5xl",
              Theme.text(Theme.Color.white),
            ])}>
            {React.string(reason)}
          </h1>
        </Spacer>
        <pre className="overflow-scroll">
          <code
            className="w-full text-sm sm:text-base inline-flex text-left items-center space-x-4 bg-orange-900 font-bold text-white rounded-lg p-4 pl-6">
            {React.string(debugInfo)}
          </code>
        </pre>
      </main>
    </div>;
  };
};

let handler =
  Dream.router([
    Dream.get("/", _request =>
      Dream.html(
        ReactDOM.renderToStaticMarkup(<Document> <Home /> </Document>),
      )
    ),
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
          let%lwt (stream, _abort) =
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
      "/static/**",
      Dream.static("./_build/default/demo/client/app"),
    ),
  ]);

let interface =
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };

Esbuild.build(
  ~entry_point="demo/client/index.js",
  ~outfile="demo/client/bundle.js",
  (),
);

Dream.run(
  ~port=8080,
  ~interface,
  ~error_handler={
    Dream.error_template((error, info, suggested) =>
      Dream.html(
        ReactDOM.renderToStaticMarkup(
          <Document>
            <Error error debugInfo=info suggestedResponse=suggested />
          </Document>,
        ),
      )
    );
  },
  Dream.livereload(handler),
);
