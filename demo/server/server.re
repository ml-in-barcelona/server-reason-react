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

let serverComponentsHandler = request => {
  let app = <Static_small />;
  /* let app = <div id="root"> <Noter /> </div>; */
  switch (Dream.header(request, "Accept")) {
  | Some(accept) when is_react_component_header(accept) =>
    stream_rsc(stream => {
      let%lwt initial =
        ReactServerDOM.render_to_model(
          app,
          ~subscribe=chunk => {
            Dream.log("Chunk");
            Dream.log("%s", chunk);
            let length_header =
              Printf.sprintf("%x\r\n", String.length(chunk));
            let%lwt () = Dream.write(stream, length_header);
            let%lwt () = Dream.write(stream, chunk);
            let%lwt () = Dream.write(stream, "\r\n");
            Dream.flush(stream);
          },
        );

      Dream.flush(stream);
    })
  | _ =>
    let async_scripts = ["/static/demo/client/rsc-with-client.js"];
    let scripts = ["https://cdn.tailwindcss.com"];
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
    let headers = [("Content-Type", "text/html")];
    Dream.stream(~headers, stream => {
      switch%lwt (ReactServerDOM.render_to_html(app)) {
      | ReactServerDOM.Done({head_scripts: scripts, body:root, end_script}) =>
        Dream.log("Done: %s", Html.to_string(root));
        let%lwt () =
          Dream.write(
            stream,
            "<!DOCTYPE html><head><meta charset=\"utf-8\"/><title>React Server DOM</title>",
          );
        let%lwt () = Dream.write(stream, htmlScripts);
        let%lwt () = Dream.write(stream, htmlAsyncScripts);
        let%lwt () = Dream.write(stream, Html.to_string(scripts));
        let%lwt () = Dream.write(stream, "</head><body><div id=\"root\">");
        let%lwt () = Dream.write(stream, Html.to_string(root));
        let%lwt () = Dream.write(stream, "</div>");
        let%lwt () = Dream.write(stream, Html.to_string(end_script));
        let%lwt () = Dream.write(stream, "</body></html>");
        Dream.flush(stream);
      | ReactServerDOM.Async({shell, subscribe}) =>
        let%lwt () = Dream.write(stream, Html.to_string(shell));
        Dream.log("Async: %s", Html.to_string(shell));
        subscribe(chunk => {
          Dream.log("Chunk");
          Dream.log("%s", Html.to_string(chunk));
          let%lwt () = Dream.write(stream, Html.to_string(chunk));
          Dream.flush(stream);
        });
      }
    });
  };
};

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
    Dream.logger(Dream.router(router)),
  );
};
