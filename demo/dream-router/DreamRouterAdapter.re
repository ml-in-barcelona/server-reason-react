module Accept = {
  let quality = parameters =>
    parameters
    |> List.find_map(parameter => {
         let parameter = String.trim(parameter);
         switch (String.split_on_char('=', parameter)) {
         | [name, value]
             when
               String.equal(String.lowercase_ascii(String.trim(name)), "q") =>
           float_of_string_opt(String.trim(value))
         | _ => None
         };
       })
    |> Option.value(~default=1.0);

  let acceptsRsc = value =>
    value
    |> String.split_on_char(',')
    |> List.exists(item => {
         switch (String.split_on_char(';', item)) {
         | [] => false
         | [mediaType, ...parameters] =>
           String.equal(
             String.lowercase_ascii(String.trim(mediaType)),
             "application/react.component",
           )
           && quality(parameters) > 0.0
         }
       });
};

let handler =
    (
      ~registry,
      ~basePath,
      ~fallback,
      ~applicationStatus,
      ~diagnosticId,
      ~revision,
      ~protocolVersion,
      ~bootstrapModules=[],
      ~document,
      ~rscModel,
      ~rscPatch,
      ~rscRedirect,
      request,
    ) =>
  DreamRSC.withRequestContext(
    request,
    () => {
      let (pathname, query) = Dream.target(request) |> Dream.split_target;
      let search = String.equal(query, "") ? "" : "?" ++ query;
      let kind =
        switch (Dream.header(request, "Accept")) {
        | Some(accept) when Accept.acceptsRsc(accept) => RouterServer.ServerEngine.Rsc
        | Some(_)
        | None => RouterServer.ServerEngine.Document
        };
      let navigation =
        switch (kind) {
        | RouterServer.ServerEngine.Document => None
        | RouterServer.ServerEngine.Rsc =>
          Some({
            RouterServer.ServerEngine.from:
              Dream.header(request, "SRR-Navigation-From"),
            registry: Dream.header(request, "SRR-Registry"),
            base_revision: Dream.header(request, "SRR-Base-Revision"),
          })
        };
      let outcome =
        RouterServer.ServerEngine.run(
          ~registry,
          ~basePath,
          ~fallback,
          ~applicationStatus,
          ~diagnosticId,
          ~revision,
          ~protocolVersion,
          {
            RouterServer.ServerEngine.pathname,
            search,
            hash: "",
            kind,
            navigation,
          },
        );
      Lwt.bind(outcome, outcome =>
        switch (outcome) {
        | RouterServer.ServerEngine.Redirect(destination) =>
          switch (kind) {
          | RouterServer.ServerEngine.Document =>
            Dream.redirect(request, RouterRuntime.href(destination))
          | RouterServer.ServerEngine.Rsc =>
            DreamRSC.stream_model_value(
              ~code=200,
              ~headers=[("Vary", "Accept"), ("SRR-Response", "redirect")],
              ~location=Dream.target(request),
              rscRedirect(destination),
            )
          }
        | RouterServer.ServerEngine.ReloadRequired =>
          Dream.respond(
            ~code=409,
            ~headers=[
              ("Vary", "Accept"),
              ("SRR-Response", "reload-required"),
              ("Cache-Control", "private, no-store"),
            ],
            "",
          )
        | RouterServer.ServerEngine.Patch(response) =>
          let code = response.resolved.status |> RouterRuntime.Status.toInt;
          let headers =
            response.resolved.headers |> RouterRuntime.Headers.toList;
          DreamRSC.stream_model_value(
            ~code,
            ~headers,
            ~location=response.canonical_url,
            rscPatch(response),
          );
        | RouterServer.ServerEngine.Full(response) =>
          let code = response.resolved.status |> RouterRuntime.Status.toInt;
          let headers =
            response.resolved.headers |> RouterRuntime.Headers.toList;
          switch (response.kind) {
          | RouterServer.ServerEngine.Document =>
            DreamRSC.stream_html(
              ~code,
              ~headers,
              ~bootstrapModules,
              document(response),
            )
          | RouterServer.ServerEngine.Rsc =>
            DreamRSC.stream_model_value(
              ~code,
              ~headers,
              ~location=response.canonical_url,
              rscModel(response),
            )
          };
        }
      );
    },
  );

let routes = (~basePath, ~actionHandler, handler) => [
  Dream.get(basePath, handler),
  Dream.get(basePath ++ "/**", handler),
  Dream.post(basePath, actionHandler),
  Dream.post(basePath ++ "/**", actionHandler),
];
