let debug = Sys.getenv_opt("DEMO_ENV") == Some("development");

let handleFormRequest = (actionId, formData) => {
  let formData = {
    let formDataJs = Js.FormData.make();
    formData
    |> List.iter(((name, value)) => {
         // For now we're only supporting strings.
         let (_filename, value) = value |> List.hd;
         Js.FormData.append(formDataJs, name, `String(value));
       });
    formDataJs;
  };

  let (args, formData) = ReactServerDOM.decodeFormDataReply(formData);

  let actionId =
    switch (actionId) {
    | Some(actionId) => actionId
    | None => failwith("We don't support progressive enhancement yet.")
    };

  let handler =
    switch (FunctionReferences.get(actionId)) {
    | Some(FormData(handler)) => handler
    | _ => assert(false)
    };
  handler(args, formData);
};

let handleRequestBody = (request, actionId) => {
  let%lwt body = Dream.body(request);
  let actionId =
    switch (actionId) {
    | Some(actionId) => actionId
    | None =>
      failwith(
        "Missing action ID, this request was not created by server-reason-react",
      )
    };
  let handler =
    switch (FunctionReferences.get(actionId)) {
    | Some(Body(handler)) => handler
    | _ => assert(false)
    };

  handler(ReactServerDOM.decodeReply(body));
};

let handleRequest = request => {
  let actionId = Dream.header(request, "ACTION_ID");
  let contentType = Dream.header(request, "Content-Type");

  switch (contentType) {
  | Some(contentType)
      when String.starts_with(contentType, ~prefix="multipart/form-data") =>
    switch%lwt (Dream.multipart(request, ~csrf=false)) {
    | `Ok(formData) => handleFormRequest(actionId, formData)
    | _ =>
      failwith(
        "Missing form data, this request was not created by server-reason-react",
      )
    }
  | _ => handleRequestBody(request, actionId)
  };
};

let streamFunctionResponse = request => {
  Dream.stream(
    ~headers=[("Content-Type", "application/react.action")],
    stream => {
      let%lwt () =
        ReactServerDOM.create_action_response(
          ~subscribe=
            chunk => {
              Dream.log("Action response");
              Dream.log("%s", chunk);
              let%lwt () = Dream.write(stream, chunk);
              Dream.flush(stream);
            },
          handleRequest(request),
        );

      Dream.flush(stream);
    },
  );
};

let is_react_component_header = str =>
  String.equal(str, "application/react.component");

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

let stream_model = (~location, app) =>
  stream_model_value(~location, React.Model.Element(app));

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

let createFromRequest =
    (
      ~disableSSR=false,
      ~layout=children => children,
      ~bootstrapModules=[],
      ~bootstrapScripts=[],
      ~bootstrapScriptContent="",
      element,
      request,
    ) => {
  switch (Dream.header(request, "Accept")) {
  | Some(accept) when is_react_component_header(accept) =>
    stream_model(~location=Dream.target(request), element)
  | _ =>
    stream_html(
      ~skipRoot=disableSSR,
      ~bootstrapScriptContent,
      ~bootstrapScripts,
      ~bootstrapModules,
      layout(element),
    )
  };
};
