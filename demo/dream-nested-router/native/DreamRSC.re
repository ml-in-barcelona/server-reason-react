let debug = Sys.getenv_opt("DEMO_ENV") === Some("development");

let stream_model_value = (~location, app) =>
  Dream.stream(
    ~headers=[
      ("Content-Type", "application/react.component"),
      ("X-Content-Type-Options", "nosniff"),
      ("X-Location", location),
    ],
    stream => {
      let%lwt () =
        ReactServerDOM.render_model_value(
          ~debug,
          ~subscribe=
            chunk => {
              if (debug) {
                Dream.log("Chunk");
                Dream.log("%s", chunk);
              };
              let%lwt () = Dream.write(stream, chunk);
              Dream.flush(stream);
            },
          app,
        );

      Dream.flush(stream);
    },
  );

let stream_html =
    (
      ~skipRoot=false,
      ~bootstrapScriptContent=?,
      ~bootstrapScripts=[],
      ~bootstrapModules=[],
      app,
    ) => {
  Dream.stream(
    ~headers=[("Content-Type", "text/html")],
    stream => {
      let%lwt (html, subscribe) =
        ReactServerDOM.render_html(
          ~skipRoot,
          ~bootstrapScriptContent?,
          ~bootstrapScripts,
          ~bootstrapModules,
          ~debug,
          app,
        );

      let%lwt () = Dream.write(stream, html);
      let%lwt () = Dream.flush(stream);
      let%lwt () =
        subscribe(chunk => {
          if (debug) {
            Dream.log("Chunk");
            Dream.log("%s", chunk);
          };
          let%lwt () = Dream.write(stream, chunk);
          Dream.flush(stream);
        });
      Dream.flush(stream);
    },
  );
};
