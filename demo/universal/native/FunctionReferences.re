include ReactServerDOM.FunctionReferencesMake({
  type t = Hashtbl.t(string, ReactServerDOM.server_function);

  let registry = Hashtbl.create(10);
  let register = Hashtbl.add(registry);
  let get = Hashtbl.find_opt(registry);
});

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

  let formData = ReactServerDOM.decodeFormDataReply(formData);

  let actionId =
    switch (actionId) {
    | Some(actionId) => actionId
    | None => failwith("We don't support progressive enhancement yet.")
    };

  let handler =
    switch (get(actionId)) {
    | Some(FormData(handler)) => handler
    | _ => assert(false)
    };
  handler(formData);
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
    switch (get(actionId)) {
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
