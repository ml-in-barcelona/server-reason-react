let is_react_component_header = str =>
  String.equal(str, "application/react.component");

let render_html =
    (~bootstrapScriptContent, ~bootstrapScripts, ~bootstrapModules, app) => {
  Dream.stream(~headers=[("Content-Type", "text/html")], stream => {
    switch%lwt (
      ReactServerDOM.render_html(
        ~bootstrapScriptContent,
        ~bootstrapScripts,
        ~bootstrapModules,
        app,
      )
    ) {
    | ReactServerDOM.Async({
        everything,
        head: _head_children,
        shell: _body,
        subscribe,
      }) =>
      let%lwt () = Dream.write(stream, "<!DOCTYPE html>");
      let%lwt () = Dream.write(stream, everything);
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
