let debug = false;

let is_react_component_header = str =>
  String.equal(str, "application/react.component");

let stream_model = (~location, app) =>
  Dream.stream(
    ~headers=[
      ("Content-Type", "application/react.component"),
      ("X-Content-Type-Options", "nosniff"),
      ("X-Location", location),
    ],
    stream => {
      let%lwt _stream: Lwt.t(Lwt_stream.t(string)) =
        ReactServerDOM.render_model(
          ~debug,
          ~subscribe=
            chunk => {
              Dream.log("Chunk");
              Dream.log("%s", chunk);
              let%lwt () = Dream.write(stream, chunk);
              Dream.flush(stream);
            },
          app,
        );

      Dream.flush(stream);
    },
  );

let stream_html =
    (~bootstrapScriptContent, ~bootstrapScripts, ~bootstrapModules, app) => {
  Dream.stream(
    ~headers=[("Content-Type", "text/html")],
    stream => {
      let%lwt () = Dream.write(stream, "<!DOCTYPE html>");
      let%lwt (html, subscribe) =
        ReactServerDOM.render_html(
          ~bootstrapScriptContent,
          ~bootstrapScripts,
          ~bootstrapModules,
          ~debug,
          app,
        );
      let%lwt () = Dream.write(stream, "<body>" ++ html ++ "</body>");
      let%lwt () = Dream.flush(stream);
      let%lwt () =
        subscribe(chunk => {
          Dream.log("Chunk");
          Dream.log("%s", chunk);
          let%lwt () = Dream.write(stream, chunk);
          Dream.flush(stream);
        });
      Dream.flush(stream);
    },
  );
};

let stream_server_action = (request, fn) => {
  Dream.stream(
    ~headers=[
      ("Content-Type", "application/react.action"),
      ("X-Location", Dream.target(request)),
    ],
    stream => {
      let%lwt () = fn(stream);
      Lwt.return();
    },
  );
};

let createActionFromRequest = (request, values) => {
  stream_server_action(
    request,
    stream => {
      let%lwt _stream =
        ReactServerDOM.create_action_response(
          ~subscribe=
            chunk => {
              Dream.log("Action response");
              Dream.log("%s", chunk);
              let%lwt () = Dream.write(stream, chunk);
              Dream.flush(stream);
            },
          values,
        );

      Dream.flush(stream);
    },
  );
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
    stream_model(~location=Dream.target(request), app)
  | _ =>
    stream_html(
      ~bootstrapScriptContent,
      ~bootstrapScripts,
      ~bootstrapModules,
      app,
    )
  };
};
