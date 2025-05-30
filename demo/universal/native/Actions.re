let stream_server_action = fn => {
  Dream.stream(
    ~headers=[("Content-Type", "application/react.action")],
    stream => {
      let%lwt () = fn(stream);
      Lwt.return();
    },
  );
};

let streamResponse = values => {
  stream_server_action(stream => {
    let%lwt () =
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
  });
};

let server_funtions_registry:
  Hashtbl.t(string, ReactServerDOM.server_function) =
  Hashtbl.create(10);

let getFunction = (id, content) => {
  let action = Hashtbl.find(server_funtions_registry, id);
  action(ReactServerDOM.decodeReply(content));
};

let register = (id, handler) => {
  Dream.log("register action: %s", id);
  Hashtbl.add(server_funtions_registry, id, handler);
};

let handleRequest = (request, request) => {
  let actionId = Dream.header(request, "ACTION_ID");
  let contentType = Dream.header(request, "Content-Type");

  switch (contentType) {
  | Some(contentType)
      when String.starts_with(contentType, ~prefix="multipart/form-data") =>
    switch%lwt (Dream.multipart(request, ~csrf=false)) {
    | `Ok(formData) =>
      // For now we're using hashtbl for FormData as we still cannot support the Js.FormData.t.
      let formData =
        formData
        |> List.fold_left(
             (acc, (name, value)) => {
               // For now we're only supporting strings.
               let (_filename, value) = value |> List.hd;
               FormData.append(acc, name, `String(value));
               acc;
             },
             FormData.make(),
           );
      let response = ServerReference.formDataHandler(formData, actionId);
      streamResponse(response);
    | _ =>
      failwith(
        "Missing form data, this request was not created by server-reason-react",
      )
    }
  | _ =>
    let%lwt body = Dream.body(request);
    let actionId =
      switch (actionId) {
      | Some(actionId) => actionId
      | None =>
        failwith(
          "Missing action ID, this request was not created by server-reason-react",
        )
      };
    let response = ServerReference.bodyHandler(body, actionId);
    streamResponse(response);
  };
};
