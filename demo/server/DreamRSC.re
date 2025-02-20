let is_react_component_header = str =>
  String.equal(str, "application/react.component");

let stream_rsc = (request, fn) => {
  Dream.stream(
    ~headers=[
      ("Content-Type", "application/react.component"),
      ("X-Content-Type-Options", "nosniff"),
      ("X-Location", Dream.target(request)),
    ],
    stream => {
      let%lwt () = fn(stream);
      Lwt.return();
    },
  );
};

let render_html =
    (~bootstrapScriptContent, ~bootstrapScripts, ~bootstrapModules, app) => {
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
  let htmlBootstrapScriptContent =
    if (bootstrapScriptContent == "") {
      Html.null;
    } else {
      Html.node("script", [], [Html.raw(bootstrapScriptContent)]);
    };
  let htmlBootstrapScripts =
    bootstrapScripts
    |> List.map(script =>
         Html.node(
           "script",
           [Html.attribute("src", script), Html.attribute("async", "true")],
           [],
         )
       )
    |> Html.list;
  let htmlBootstrapModules =
    bootstrapModules
    |> List.map(script =>
         Html.node(
           "script",
           [
             Html.attribute("src", script),
             Html.attribute("async", "true"),
             Html.attribute("type", "module"),
           ],
           [],
         )
       )
    |> Html.list;
  Dream.stream(~headers=[("Content-Type", "text/html")], stream => {
    switch%lwt (ReactServerDOM.render_html(app)) {
    | ReactServerDOM.Done({app, head: head_children, body, end_script}) =>
      let%lwt () = Dream.write(stream, app);
      Dream.flush(stream);
    | ReactServerDOM.Async({head: head_children, shell: body, subscribe}) =>
      let%lwt () = Dream.write(stream, Html.to_string(doctype));
      let%lwt () =
        Dream.write(
          stream,
          Html.to_string(
            head([htmlBootstrapScripts, htmlBootstrapModules, head_children]),
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

let createFromRequest =
    (
      ~bootstrapModules=[],
      ~bootstrapScripts=[],
      ~bootstrapScriptContent="",
      app,
      request,
    ) => {
  switch (Dream.header(request, "Accept")) {
  | Some(accept) when is_react_component_header(accept) =>
    stream_rsc(
      request,
      stream => {
        let%lwt _stream =
          ReactServerDOM.render_model(
            app,
            ~subscribe=chunk => {
              Dream.log("Chunk");
              Dream.log("%s", chunk);
              let%lwt () = Dream.write(stream, chunk);
              Dream.flush(stream);
            },
          );

        Dream.flush(stream);
      },
    )
  | _ =>
    render_html(
      ~bootstrapScriptContent,
      ~bootstrapScripts,
      ~bootstrapModules,
      app,
    )
  };
};
