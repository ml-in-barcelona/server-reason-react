let renderToStreamHandler = _ =>
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
  );

let serverComponentsWithoutClientHandler = request => {
  let isRSCheader =
    Dream.header(request, "Accept") == Some("text/x-component");

  let app =
    <Layout background=Theme.Color.black>
      <div className="flex flex-col items-center justify-center h-full gap-4">
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
        ReactServerDOM.render_to_model(
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
};

let is_react_component_header = str =>
  String.equal(str, "application/react.component");

let stream_rsc = fn => {
  Dream.stream(
    ~headers=[
      ("Content-Type", "application/react.component"),
      ("X-Content-Type-Options", "nosniff"),
    ],
    stream => {
      let%lwt () = fn(stream);
      let%lwt () = Dream.write(stream, "0\r\n\r\n");
      Lwt.return();
    },
  );
};

let stream_html = (~async_scripts, ~scripts, fn) => {
  let htmlPrelude = "<!DOCTYPE html><meta charset=\"utf-8\">";
  let htmlScripts =
    String.concat(
      "\n",
      List.map(Printf.sprintf({|<script src="%s"></script>|}), scripts),
    );
  let htmlAsyncScripts =
    String.concat(
      "\n",
      List.map(
        Printf.sprintf({|<script src="%s" async></script>|}),
        async_scripts,
      ),
    );

  Dream.stream(
    ~headers=[("Content-Type", "text/html")],
    stream => {
      let%lwt () = Dream.write(stream, htmlPrelude);
      let%lwt () = Dream.write(stream, htmlScripts);
      let%lwt () = Dream.write(stream, htmlAsyncScripts);
      let%lwt () = fn(stream);
      Lwt.return();
    },
  );
};

let serverComponentsHandler = request => {
  let app = <div id="root"> <Noter /> </div>;
  switch (Dream.header(request, "Accept")) {
  | Some(accept) when is_react_component_header(accept) =>
    stream_rsc(stream => {
      let%lwt initial =
        ReactServerDOM.render_to_model(
          app,
          ~subscribe=chunk => {
            let length_header =
              Printf.sprintf("%x\r\n", String.length(chunk));
            let%lwt () = Dream.write(stream, length_header);
            let%lwt () = Dream.write(stream, chunk);
            let%lwt () = Dream.write(stream, "\r\n");
            Lwt.return();
          },
        );

      Lwt.return();
    })
  | _ =>
    stream_html(
      ~async_scripts=["/static/demo/client/rsc-with-client.js"],
      ~scripts=["https://cdn.tailwindcss.com"],
      stream => {
      switch%lwt (ReactServerDOM.render_to_html(app)) {
      | ReactServerDOM.Done(html) =>
        Dream.log("Done");
        Dream.log("%s", Html.to_string(html));
        Dream.write(stream, Html.to_string(html));
      | ReactServerDOM.Async({shell, subscribe}) =>
        let%lwt () = Dream.write(stream, Html.to_string(shell));
        Dream.log("Async");
        Dream.log("%s", Html.to_string(shell));
        subscribe(chunk => {
          Dream.log("Chunk");
          Dream.log("%s", Html.to_string(chunk));
          let%lwt () = Dream.write(stream, Html.to_string(chunk));
          Lwt.return();
        });
      }
    })
  };
};

/* request => {
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
       /* let header =
          Htmlgen.(splice [html_prelude; html_shell; html_scripts]); */
       switch%lwt (
         ReactServerDOM.to_html(
           <Document script="/static/demo/client/rsc-with-client.js">
             <Noter />
           </Document>,
         )
       ) {
       | ReactServerDOM.Html.Finish(html) => Dream.html(html)
       | ReactServerDOM.Html.Streaming({shell, values}) =>
         let header = Html.to_string(shell);
         /* Dream.html(header); */
         Dream.stream(response_stream => {
           let%lwt () = Dream.write(response_stream, header);
           Lwt.return();
         });
       };
     };
   }, */

let router = [
  Dream.get("/", Home.handler),
  Dream.get("/static/**", Dream.static("./_build/default/demo/client/app")),
  Dream.get(Router.renderToString, _request =>
    Dream.html(
      ReactDOM.renderToString(
        <Document script="/static/demo/client/app.js"> <App /> </Document>,
      ),
    )
  ),
  Dream.get(Router.renderToStaticMarkup, _request =>
    Dream.html(
      ReactDOM.renderToStaticMarkup(
        <Document script="/static/demo/client/app.js"> <App /> </Document>,
      ),
    )
  ),
  Dream.get(Router.renderToStream, renderToStreamHandler),
  Dream.get(
    Router.serverComponentsWithoutClient,
    serverComponentsWithoutClientHandler,
  ),
  Dream.get(Router.serverComponents, serverComponentsHandler),
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
