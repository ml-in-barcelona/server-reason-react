let renderToStreamHandler = _ =>
  Dream.stream(
    ~headers=[("Content-Type", "text/html")],
    response_stream => {
      let pipe = data => {
        let%lwt () = Dream.write(response_stream, data);
        Dream.flush(response_stream);
      };
      let%lwt (stream, _abort) =
        ReactDOM.renderToStream(~pipe, <Document> <Comments /> </Document>);
      Lwt.return();
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
        <Document script="/static/demo/client/create-from-fetch.js">
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

module Page = {
  [@react.async.component]
  let make = () => {
    let%lwt () = Lwt_unix.sleep(1.0);
    Lwt.return(
      <Layout background=Theme.Color.black>
        <Stack gap=8 justify=`start>
          <p
            className={Cx.make([
              "text-3xl",
              "font-bold",
              Theme.text(Theme.Color.white),
            ])}>
            {React.string("This is a small form")}
          </p>
          <Hr />
          <div className="text-white">
            <Counter
              string="Title"
              int=1
              float=1.1
              bool_true=true
              bool_false=false
              string_array=[|"Item 1", "Item 2"|]
              string_list=["Item 1", "Item 2"]
              object_={
                        `Assoc([
                          ("name", `String("John")),
                          ("age", `Int(30)),
                        ])
                      }
            />
          </div>
          <Hr />
        </Stack>
      </Layout>,
    );
  };
};

let serverComponentsHandler = request => {
  let app = <Page />;
  switch (Dream.header(request, "Accept")) {
  | Some(accept) when is_react_component_header(accept) =>
    stream_rsc(stream => {
      let%lwt _initial =
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
    let doctype = Html.raw("<!DOCTYPE html>");
    let head = children => {
      Html.node(
        "head",
        [],
        [
          Html.node("meta", [Html.attribute("charset", "utf-8")], []),
          Html.node("title", [], [Html.string("React Server DOM")]),
          ...children,
        ],
      );
    };
    let sync_scripts =
      Html.node(
        "script",
        [Html.attribute("src", "https://cdn.tailwindcss.com")],
        [],
      );
    let async_scripts =
      Html.node(
        "script",
        [
          Html.attribute("src", "/static/demo/client/runtime-with-client.js"),
          Html.attribute("async", "true"),
          Html.attribute("type", "module"),
        ],
        [],
      );
    let headers = [("Content-Type", "text/html")];
    Dream.stream(~headers, stream => {
      switch%lwt (ReactServerDOM.render_to_html(app)) {
      | ReactServerDOM.Done({head: head_children, body, end_script}) =>
        Dream.log("Done: %s", Html.to_string(body));
        let%lwt () = Dream.write(stream, Html.to_string(doctype));
        let%lwt () =
          Dream.write(
            stream,
            Html.to_string(
              head([sync_scripts, async_scripts, head_children]),
            ),
          );
        let%lwt () = Dream.write(stream, "<body><div id=\"root\">");
        let%lwt () = Dream.write(stream, Html.to_string(body));
        let%lwt () = Dream.write(stream, "</div>");
        let%lwt () = Dream.write(stream, Html.to_string(end_script));
        let%lwt () = Dream.write(stream, "</body></html>");
        Dream.flush(stream);
      | ReactServerDOM.Async({head: head_children, shell: body, subscribe}) =>
        let%lwt () = Dream.write(stream, Html.to_string(doctype));
        let%lwt () =
          Dream.write(
            stream,
            Html.to_string(
              head([sync_scripts, async_scripts, head_children]),
            ),
          );
        let%lwt () = Dream.write(stream, "<body><div id=\"root\">");
        let%lwt () = Dream.write(stream, Html.to_string(body));
        let%lwt () = Dream.write(stream, "</div>");
        let%lwt () = Dream.flush(stream);
        let%lwt () =
          subscribe(chunk => {
            Dream.log("Chunk");
            Dream.log("%s", Html.to_string(chunk));
            let%lwt () = Dream.write(stream, Html.to_string(chunk));
            Dream.flush(stream);
          });
        let%lwt () = Dream.write(stream, "</body></html>");
        Dream.flush(stream);
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
