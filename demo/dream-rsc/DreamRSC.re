module RequestContext = {
  type pending_cookie = {
    name: string,
    value: string,
    expires: option(float),
    max_age: option(float),
    domain: option(string),
    path: option(string),
    secure: option(bool),
    http_only: option(bool),
    same_site:
      option(
        [
          | `Strict
          | `Lax
          | `None
        ],
      ),
  };

  type phase =
    | Render
    | Action(ref(list(pending_cookie)));

  let request_key: Lwt.key(Dream.request) = Lwt.new_key();
  let phase_key: Lwt.key(phase) = Lwt.new_key();

  let get_request = () =>
    switch (Lwt.get(request_key)) {
    | Some(request) => request
    | None =>
      failwith(
        "RequestContext.get_request: no request context. "
        ++ "This function must be called inside a server component or server function.",
      )
    };

  let get_header = name => Dream.header(get_request(), name);

  let get_cookie = (~decrypt=false, name) =>
    Dream.cookie(~decrypt, get_request(), name);

  let set_cookie =
      (
        ~expires=?,
        ~max_age=?,
        ~domain=?,
        ~path=?,
        ~secure=?,
        ~http_only=?,
        ~same_site=?,
        name,
        value,
      ) =>
    switch (Lwt.get(phase_key)) {
    | Some(Action(pending)) =>
      pending :=
        [
          {
            name,
            value,
            expires,
            max_age,
            domain,
            path,
            secure,
            http_only,
            same_site,
          },
          ...pending^,
        ]
    | Some(Render) =>
      failwith(
        "RequestContext.set_cookie: cookies can only be modified in a server function (action), not during render.",
      )
    | None =>
      failwith(
        "RequestContext.set_cookie: no request context. "
        ++ "This function must be called inside a server function.",
      )
    };
};

let with_render_context = (request, f) =>
  Lwt.with_value(RequestContext.request_key, Some(request), () =>
    Lwt.with_value(RequestContext.phase_key, Some(RequestContext.Render), f)
  );

let with_action_context = (request, f) => {
  let pending = ref([]);
  let run = () =>
    Lwt.with_value(RequestContext.request_key, Some(request), () =>
      Lwt.with_value(
        RequestContext.phase_key,
        Some(RequestContext.Action(pending)),
        f,
      )
    );
  (pending, run);
};

let serialize_pending_cookies = pending =>
  pending
  |> List.rev
  |> List.map((cookie: RequestContext.pending_cookie) => {
       let header_value =
         Dream.to_set_cookie(
           ~expires=?cookie.expires,
           ~max_age=?cookie.max_age,
           ~domain=?cookie.domain,
           ~path=?cookie.path,
           ~secure=?cookie.secure,
           ~http_only=?cookie.http_only,
           ~same_site=?cookie.same_site,
           cookie.name,
           cookie.value,
         );
       ("Set-Cookie", header_value);
     });

let require_action_id = actionId =>
  switch (actionId) {
  | Some(id) => Ok(id)
  | None =>
    Error(
      "Missing ACTION_ID header, this request was not created by server-reason-react",
    )
  };

let dispatch_handler = (~lookup, actionId, dispatch) =>
  switch (require_action_id(actionId)) {
  | Error(msg) => Lwt.fail_with(msg)
  | Ok(actionId) =>
    switch (lookup(actionId)) {
    | None => Lwt.fail_with("Action " ++ actionId ++ " is not registered")
    | Some(handler) => dispatch(actionId, handler)
    }
  };

let handleFormRequest = (~lookup, actionId, formData) => {
  let formDataJs = Js.FormData.make();
  formData
  |> List.iter(((name, value)) => {
       let (_filename, value) = value |> List.hd;
       Js.FormData.append(formDataJs, name, `String(value));
     });

  switch (ReactServerDOM.decodeFormDataReply(formDataJs)) {
  | Error(msg) => Lwt.fail_with(msg)
  | Ok((args, formData)) =>
    dispatch_handler(~lookup, actionId, (actionId, handler) =>
      switch (handler) {
      | ReactServerDOM.FormData(handler) => handler(args, formData)
      | ReactServerDOM.Body(_) =>
        Lwt.fail_with(
          "Action "
          ++ actionId
          ++ " is registered as Body handler but received FormData request",
        )
      }
    )
  };
};

let handleRequestBody = (~lookup, request, actionId) => {
  let%lwt body = Dream.body(request);
  switch (ReactServerDOM.decodeReply(body)) {
  | Error(msg) => Lwt.fail_with(msg)
  | Ok(args) =>
    dispatch_handler(~lookup, actionId, (actionId, handler) =>
      switch (handler) {
      | ReactServerDOM.Body(handler) => handler(args)
      | ReactServerDOM.FormData(_) =>
        Lwt.fail_with(
          "Action "
          ++ actionId
          ++ " is registered as FormData handler but received JSON body request",
        )
      }
    )
  };
};

let handleRequest = (~lookup, request) => {
  let actionId = Dream.header(request, "ACTION_ID");
  let contentType = Dream.header(request, "Content-Type");

  switch (contentType) {
  | Some(contentType)
      when String.starts_with(contentType, ~prefix="multipart/form-data") =>
    switch%lwt (Dream.multipart(request, ~csrf=false)) {
    | `Ok(formData) => handleFormRequest(~lookup, actionId, formData)
    | _ =>
      Lwt.fail_with(
        "Missing form data, this request was not created by server-reason-react",
      )
    }
  | _ => handleRequestBody(~lookup, request, actionId)
  };
};

let streamFunctionResponse = (~debug=false, ~lookup, request) => {
  let (pending, run) =
    with_action_context(request, () => handleRequest(~lookup, request));

  /* Run the action. On success we keep pending cookies; on failure we discard them.
     Either way we capture the outcome as a promise for create_action_response,
     which serializes both successes and failures into the RSC stream
     (rather than letting failures become HTTP 500s). */
  let%lwt (action_promise, cookie_headers) =
    Lwt.catch(
      () => {
        let%lwt result = run();
        let cookies = serialize_pending_cookies(pending^);
        Lwt.return((Lwt.return(result), cookies));
      },
      exn => {
        pending := [];
        Lwt.return((Lwt.fail(exn), []));
      },
    );

  Dream.stream(
    ~headers=[
      ("Content-Type", "application/react.action"),
      ...cookie_headers,
    ],
    stream => {
      let%lwt () =
        ReactServerDOM.create_action_response(
          ~debug,
          ~subscribe=
            chunk => {
              if (debug) {
                Dream.log("Action response");
                Dream.log("%s", chunk);
              };
              let%lwt () = Dream.write(stream, chunk);
              Dream.flush(stream);
            },
          action_promise,
        );

      Dream.flush(stream);
    },
  );
};

let is_react_component_header = str =>
  String.equal(str, "application/react.component");

let stream_model_value = (~debug=false, ~location, app) =>
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

let stream_model = (~debug=false, ~location, app) =>
  stream_model_value(~debug, ~location, React.Model.Element(app));

let stream_html =
    (
      ~debug=false,
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
      ~debug=false,
      ~disableSSR=false,
      ~layout=children => children,
      ~bootstrapModules=[],
      ~bootstrapScripts=[],
      ~bootstrapScriptContent="",
      element,
      request,
    ) =>
  with_render_context(request, () =>
    switch (Dream.header(request, "Accept")) {
    | Some(accept) when is_react_component_header(accept) =>
      stream_model(~debug, ~location=Dream.target(request), element)
    | _ =>
      stream_html(
        ~debug,
        ~skipRoot=disableSSR,
        ~bootstrapScriptContent,
        ~bootstrapScripts,
        ~bootstrapModules,
        layout(element),
      )
    }
  );
