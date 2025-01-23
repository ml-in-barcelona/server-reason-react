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

let createFromRequest = (app, script, request) => {
  switch (Dream.header(request, "Accept")) {
  | Some(accept) when String.equal("application/react.component", accept) =>
    stream_rsc(stream => {
      let%lwt _stream =
        ReactServerDOM.render_model(
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
