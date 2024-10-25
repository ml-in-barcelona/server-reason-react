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

type response = {
  write: string => Lwt.t(unit),
  flush: unit => Lwt.t(unit),
};

let writeChunk = (stream, data) => {
  let len = String.length(data);
  let lenHeader = Printf.sprintf("%x\r\n", len);
  let%lwt () = Dream.write(stream, lenHeader);
  let%lwt () = Dream.write(stream, data);
  Dream.write(stream, "\r\n");
};

let stream_rsc = fn => {
  Dream.stream(
    ~headers=[
      ("Content-Type", "application/react.component"),
      ("X-Content-Type-Options", "nosniff"),
    ],
    stream => {
      let response = {
        write: data => writeChunk(stream, data),
        flush: () => Dream.flush(stream),
      };

      let%lwt () = fn(response);
      let%lwt () = Dream.write(stream, "0\r\n\r\n");
      Dream.flush(stream);
    },
  );
};

let stream_html = (~scripts, ~styles, fn) => {
  Dream.log("stream_html");
  let style_links =
    List.map(
      href => Printf.sprintf({|<link href="%s" rel="stylesheet">|}, href),
      styles,
    )
    |> String.concat("\n");
  let htmlPrelude = "<!DOCTYPE html><meta charset=\"utf-8\">";
  let htmlScripts =
    List.map(
      src => Printf.sprintf({|<script src="%s" async></script>|}, src),
      scripts,
    )
    |> String.concat("\n");

  Dream.stream(
    ~headers=[("Content-Type", "text/html")],
    stream => {
      Dream.log("calling fn from stream_html");
      let response = {
        write: data => Dream.write(stream, data),
        flush: () => Dream.flush(stream),
      };

      let%lwt () = response.write(htmlPrelude);
      Dream.log("write %s to response", htmlPrelude);
      let%lwt () = fn(response);
      Dream.log("write %s to response", htmlScripts);
      let%lwt () = response.write(htmlScripts);
      Dream.flush(stream);
    },
  );
};

let serverComponentsHandler = request => {
  let app = <div id="root"> <Noter /> </div>;
  switch (Dream.header(request, "Accept")) {
  | Some(accept) when is_react_component_header(accept) =>
    stream_rsc(response => {
      let%lwt initial =
        ReactServerDOM.render_to_model(
          app,
          ~subscribe=chunk => {
            let%lwt () = response.write(chunk);
            Lwt.return();
          },
        );

      Lwt.return();
    })
  | _ =>
    stream_html(
      ~scripts=[
        "/static/demo/client/rsc-with-client.js",
        "https://cdn.tailwindcss.com",
      ],
      ~styles=[],
      response => {
      switch%lwt (ReactServerDOM.render_to_html(app)) {
      | ReactServerDOM.Html.Done(html) =>
        response.write(Html.to_string(html))
      | ReactServerDOM.Html.Async({shell, subscribe}) =>
        Dream.log("async bitx");
        let%lwt () = response.write(Html.to_string(shell));
        subscribe(chunk => {
          let%lwt () = response.write(Html.to_string(chunk));
          response.flush();
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
