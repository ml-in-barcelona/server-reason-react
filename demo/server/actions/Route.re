let actionsManifest = (id: string) => {
  switch (id) {
  | id when Router.demoActionCreateNote == id => Notes.create
  | id when Router.demoActionEditNote == id => Notes.edit
  | id when Router.demoActionDeleteNote == id => Notes.delete
  | id when Router.demoActionComplexResponse == id => Samples.complexResponse
  | id when Router.demoActionSimpleResponse == id => Samples.simpleResponse
  | _ => failwith("No action")
  };
};

let formDataManifest = (id: string) => {
  switch (id) {
  | id when Router.demoActionFormDataSample == id => Samples.formData
  | _ => failwith("No action")
  };
};

let actionsRoute = request => {
  let body = Dream.header(request, "content-type");

  switch (body) {
  | Some(contentType)
      when String.starts_with(contentType, ~prefix="multipart/form-data") =>
    // Getting the actionId from the formData as next.js does
    switch%lwt (Dream.multipart(request, ~csrf=false)) {
    // Need to check how would we handle csrf with dream and RSC
    | `Ok([("ACTION_ID", actionId), ...formData]) =>
      let formData = formData |> List.to_seq |> Hashtbl.of_seq;
      let (_, actionId) = List.hd(actionId);
      let action = formDataManifest(actionId);
      let%lwt response = action(formData);
      ActionsRSC.createFromRequest(request, response);
    | _ => Dream.empty(`Bad_Request)
    }
  | _ =>
    let actionId = Dream.header(request, "ACTION_ID");
    let actionId = Option.get(actionId);
    let%lwt body = Dream.body(request);
    let action = actionsManifest(actionId);
    let%lwt response = action(body);
    ActionsRSC.createFromRequest(request, response);
  };
};
