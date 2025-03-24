// QUESTION: How should we create this manifest automatically?
let actionsManifest = (id: string) => {
  switch (id) {
  | id when Router.demoActionCreateNote == id => Actions.Notes.create
  | id when Router.demoActionEditNote == id => Actions.Notes.edit
  | id when Router.demoActionDeleteNote == id => Actions.Notes.delete
  | id when Router.demoActionSimpleResponse == id => Actions.Samples.simpleResponse
  | _ => failwith("No action")
  };
};

// QUESTION: How should we create this manifest automatically?
let formDataManifest = (id: string) => {
  switch (id) {
  | id when Router.demoActionFormDataSample == id => Actions.Samples.formData
  | _ => failwith("No action")
  };
};

let actionsRoute = request => {
  let body = Dream.header(request, "Content-Type");

  switch (body) {
  | Some(contentType)
      when String.starts_with(contentType, ~prefix="multipart/form-data") =>
    // Getting the actionId from the formData as next.js does
    switch%lwt (Dream.multipart(request, ~csrf=false)) {
    // react-server-dom-webpack encode formData and put the first value as model reference E.g.:["@K1"], 1 is the id
    // QUESTION: Why is it like this? Is there a change to it be other than "@K"? Is there a way to get more ids?
    | `Ok([(_, [(_, modelId)]), (key, [(_, actionId)]), ...formData])
        when String.ends_with(key, ~suffix="$ACTION_ID") =>
      let chunkId = Yojson.Basic.from_string(modelId);
      let chunkId =
        chunkId
        |> Yojson.Basic.Util.to_list
        |> List.hd
        |> Yojson.Basic.Util.to_string;
      let chunkId = chunkId->String.sub(2, String.length(chunkId) - 2);
      let formData =
        List.map(
          ((name, value)) => {
            // react-server-dom-webpack prefix the name with the id E.g.: ["1_name", "1_value"]
            let form_prefix = chunkId ++ "_";
            let key =
              String.sub(
                name,
                String.length(form_prefix),
                String.length(name) - String.length(form_prefix),
              );
            (key, value);
          },
          formData,
        );
      // Passing the formData as a hashtable to make it easier to handle as Dream don't
      // have a better way to handle it
      let formData = formData |> List.to_seq |> Hashtbl.of_seq;
      let action = formDataManifest(actionId);
      let%lwt response = action(formData);

      ActionsRSC.createFromRequest(request, response);
    // without JS enabled or hydration
    | `Ok([(key, [(_, actionId)]), ...formData])
        when String.ends_with(key, ~suffix="$ACTION_ID") =>
      let formData = formData |> List.to_seq |> Hashtbl.of_seq;
      let action = formDataManifest(actionId);
      let%lwt response = action(formData);
      ActionsRSC.createFromRequest(request, response);
    | `Ok(formData) =>
      List.iter(
        ((key, value)) => {
          List.iter(
            ((_, value)) => {Dream.log("Key: %s, Value: %s", key, value)},
            value,
          )
        },
        formData,
      );
      failwith("Something went wrong but ok");
    | _ => failwith("Something went wrong")
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
