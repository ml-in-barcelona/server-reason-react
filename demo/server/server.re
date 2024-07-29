module Link = {
  [@react.component]
  let make = (~href, ~children) => {
    let (state, setState) = React.useState(() => false);

    React.useEffect0(() => {
      setState(_prev => !state);
      None;
    });

    <a
      onClick={_e => print_endline("clicked")}
      className={Cx.make([
        "font-medium",
        "flex",
        "items-center",
        Theme.text(Theme.Color.yellow),
        Theme.hover(["underline", Theme.text(Theme.Color.darkYellow)]),
      ])}
      href>
      {React.string(children)}
      <svg
        className="w-3 h-3 ms-2 rtl:rotate-180"
        ariaHidden=true
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 14 10">
        <path
          stroke="currentColor"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          d="M1 5h12m0 0L9 1m4 4L9 9"
        />
      </svg>
    </a>;
  };
};

module Home = {
  [@react.component]
  let make = () => {
    <div
      className={Cx.make(["py-16", "px-12", Theme.text(Theme.Color.yellow)])}>
      <h1 className="font-bold text-4xl">
        {React.string("Home page of the demos")}
      </h1>
      <br />
      <ul className="gap-1 flex flex-col">
        <li>
          <Link href="/markup"> "Tiny app with renderToStaticMarkup" </Link>
        </li>
        <li> <Link href="/string"> "Tiny app with renderToString" </Link> </li>
        <li>
          <Link href="/stream"> "Tiny app with renderToLwtStream" </Link>
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
    <div className="p-12">
      <main>
        <Spacer bottom=4>
          <h1 className="font-bold text-5xl text-slate-300">
            {React.string(reason)}
          </h1>
        </Spacer>
        <pre className="overflow-scroll">
          <code
            className="w-full text-sm sm:text-base inline-flex text-left items-center space-x-4 bg-stone-700 text-white rounded-lg p-4 pl-6">
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
      Dream.html(ReactDOM.renderToStaticMarkup(<Page> <Home /> </Page>))
    ),
    Dream.get("/string", _request =>
      Dream.html(
        ReactDOM.renderToString(
          <Page script="/static/demo/client/bundle.js"> <App /> </Page>,
        ),
      )
    ),
    Dream.get("/markup", _request =>
      Dream.html(
        ReactDOM.renderToStaticMarkup(
          <Page script="/static/demo/client/bundle.js"> <App /> </Page>,
        ),
      )
    ),
    Dream.get("/stream", _request =>
      Dream.stream(
        ~headers=[("Content-Type", "text/html")],
        response_stream => {
          let (stream, _) =
            ReactDOM.renderToLwtStream(<Page> <Comments /> </Page>);

          /* Lwt.async(() => {}); */

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
    Dream.error_template((error, debug_info, suggested_response) =>
      Dream.html(
        ReactDOM.renderToStaticMarkup(
          <Page>
            <Error
              error
              debugInfo=debug_info
              suggestedResponse=suggested_response
            />
          </Page>,
        ),
      )
    );
  },
  handler,
);
