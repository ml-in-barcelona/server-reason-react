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
      <Router.Menu />
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

/* module Chunked = {
     open Lwt.Infix;
     open Lwt.Syntax;
     type stream = {
       s: Dream.stream,
       is_len_encoded: bool,
     };

     let first = (~flush=false, stream, data) => {
       let* _ = Dream.write(stream, data);
       if (flush) {
         Dream.flush(stream);
       } else {
         Lwt.return_unit;
       };
     };

     let write = (~flush=false, stream, data) =>
       {
         let len = String.length(data);
         let len = Printf.sprintf("%x\r\n", len);
         Dream.write(stream, len)
         >>= (
           () =>
             Dream.write(stream, data) >>= (() => Dream.write(stream, "\r\n"))
         );
       }
       >>= (
         () =>
           if (flush) {
             Dream.flush(stream);
           } else {
             Lwt.return_unit;
           }
       );

     let finish = ({s, is_len_encoded}) =>
       (
         if (is_len_encoded) {
           Dream.write(s, "0\r\n\r\n");
         } else {
           Lwt.return();
         }
       )
       >>= (() => Dream.flush(s));

     let stream = (~headers=?, ~is_len_encoded, f) =>
       Dream.stream(
         ~headers?,
         s => {
           let s = {s, is_len_encoded};
           f(s) >>= (() => finish(s));
         },
       );
   }; */

let () = {
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
        Router.serverComponents,
        request => {
          let app =
            <Document script="/static/demo/client/rsc.js">
              <div
                className="flex flex-col items-center justify-center h-full">
                <h1 className="text-white font-bold text-4xl">
                  {React.string(Unix.gethostname())}
                </h1>
              </div>
            </Document>;

          switch (Dream.header(request, "accept")) {
          | Some(header) when String.equal(header, "text/x-component") =>
            let headers = [("X-Content-Type-Options", "nosniff")];
            Dream.stream(
              ~headers,
              response_stream => {
                open Lwt.Syntax;
                let* (stream, _abort) = ReactServerDOM.render(app);

                stream
                |> Lwt_stream.map(Yojson.Safe.to_string)
                |> Lwt_stream.iter_s(data => {
                     let* () = Dream.write(response_stream, data);
                     Dream.flush(response_stream);
                   });
              },
            );
          | _ =>
            let html = ReactDOM.renderToStaticMarkup(app);
            Dream.html(html);
          };
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
    Dream.livereload(Dream.logger(handler)),
  );
};
