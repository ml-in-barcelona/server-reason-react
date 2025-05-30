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

let server_functions_registry:
  Hashtbl.t(string, ReactServerDOM.server_function) =
  Hashtbl.create(10);

let register =
    (id, function_: list(Yojson.Basic.t) => Lwt.t(React.client_value)) => {
  Dream.log("register action: %s", id);
  Hashtbl.add(server_functions_registry, id, ReactServerDOM.Body(function_));
};

let registerForm = (id, function_) => {
  Dream.log("register action: %s", id);
  Hashtbl.add(
    server_functions_registry,
    id,
    ReactServerDOM.FormData(function_),
  );
};

let get_function = (id: string) => {
  let action = Hashtbl.find(server_functions_registry, id);
  switch ((action: ReactServerDOM.server_function)) {
  | Body(handler) => handler
  | _ => assert(false)
  };
};

let get_function_form_data = (id: string) => {
  let action = Hashtbl.find(server_functions_registry, id);
  switch ((action: ReactServerDOM.server_function)) {
  | FormData(handler) => handler
  | _ => assert(false)
  };
};

let handleFormRequest = (request, actionId, formData) => {
  // For now we're using hashtbl for FormData as we still cannot support the Js.FormData.t.
  let formData =
    formData
    |> List.fold_left(
         (acc, (name, value)) => {
           // For now we're only supporting strings.
           let (_filename, value) = value |> List.hd;
           Js.FormData.append(acc, name, `String(value));
           acc;
         },
         Js.FormData.make(),
       );
  /* let response = formDataHandler(formData, actionId); */

  // react encodes formData and put the first value as model reference E.g.:["$K1"], 1 is the id, $K is the formData reference prefix
  let modelId =
    Js.FormData.get(formData, "0")
    |> (
      fun
      | `String(modelId) => {
          let modelId =
            Yojson.Basic.from_string(modelId)
            |> (
              fun
              | `List([`String(referenceId)]) => referenceId
              | _ => failwith("Invalid referenceId")
            );
          Some(modelId);
        }
    );

  let formData =
    Hashtbl.fold(
      (key, value, acc) =>
        if (key == "0") {
          formData;
        } else {
          switch (modelId) {
          | Some(modelId) =>
            // react prefixes the input names with the id E.g.: ["1_name", "1_value"]
            let form_prefix =
              String.sub(modelId, 2, String.length(modelId) - 2) ++ "_";
            let key =
              String.sub(
                key,
                String.length(form_prefix),
                String.length(key) - String.length(form_prefix),
              );
            Hashtbl.add(formData, key, value);
            formData;
          | None =>
            Hashtbl.add(formData, key, value);
            formData;
          };
        },
      formData,
      Hashtbl.create(10),
    );

  let actionId =
    switch (actionId) {
    | Some(actionId) => actionId
    | None => failwith("We don't support progressive enhancement yet.")
    };

  let handler = get_function_form_data(actionId);
  let response = handler(formData);
  streamResponse(response);
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
  let handler = get_function(actionId);
  let response = handler(ReactServerDOM.decodeReply(body));
  streamResponse(response);
};

let handleRequest = request => {
  let actionId = Dream.header(request, "ACTION_ID");
  let contentType = Dream.header(request, "Content-Type");

  switch (contentType) {
  | Some(contentType)
      when String.starts_with(contentType, ~prefix="multipart/form-data") =>
    switch%lwt (Dream.multipart(request, ~csrf=false)) {
    | `Ok(formData) => handleFormRequest(request, actionId, formData)
    | _ =>
      failwith(
        "Missing form data, this request was not created by server-reason-react",
      )
    }
  | _ => handleRequestBody(request, actionId)
  };
};
