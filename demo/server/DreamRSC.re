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

let render_shell = (app, script) => {
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
        Html.attribute("src", script),
        Html.attribute("async", "true"),
        Html.attribute("type", "module"),
      ],
      [],
    );
  let headers = [("Content-Type", "text/html")];
  Dream.stream(~headers, stream => {
    switch%lwt (ReactServerDOM.render_html(app)) {
    | ReactServerDOM.Done({head: head_children, body, end_script}) =>
      Dream.log("Done: %s", Html.to_string(body));
      let%lwt () = Dream.write(stream, Html.to_string(doctype));
      let%lwt () =
        Dream.write(
          stream,
          Html.to_string(head([sync_scripts, async_scripts, head_children])),
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
          Html.to_string(head([sync_scripts, async_scripts, head_children])),
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

let createFromRequest = (app, script, request) => {
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
  | _ => render_shell(app, script)
  };
};
