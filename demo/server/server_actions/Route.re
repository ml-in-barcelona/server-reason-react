// QUESTION: How should we create this manifest automatically?
let actionsManifest = (id: string) => {
  switch (id) {
  | id when Actions.Notes.createId == id => Actions.Notes.createRouteHandler
  | id when Actions.Notes.editId == id => Actions.Notes.editRouteHandler
  | id when Actions.Notes.deleteId == id => Actions.Notes.deleteRouteHandler
  | id when Actions.Samples.simpleResponseId == id => Actions.Samples.simpleResponseRouteHandler
  | _ => failwith("No action")
  };
};

// QUESTION: How should we create this manifest automatically?
let formDataManifest = (id: string) => {
  switch (id) {
  | id when Actions.Samples.formDataId == id => Actions.Samples.formDataRouteHandler
  | _ => failwith("No action")
  };
};

/*
   Due to the issues that you can see at Actions.create (line 71), Actions.edit (line 136) and Actions.delete (line 192) functions we will have the args always as a list of a single list of args.
   To parse it we need to get this first item that will indeed be the args and pass it further
 */
[@platform native]
let getArgs = body => {
  switch (Yojson.Basic.from_string(body)) {
  // When there is no args, the react will send a list with a single string "$undefined"
  // TODO: Create a Helper to "parse" special values like "$undefined"
  | `List([`String("$undefined")]) => []
  | `List(args) => args
  | _ =>
    failwith(
      "Invalid args, this request was not created by server-reason-react",
    )
  };
};

type actionContent =
  | FormData(list((string, list((option(string), string)))))
  | Body(string);

// The user of the code passes the content defined by the type actionContent and the actionId
let actionsHandler = (content, actionId) => {
  switch (content, actionId) {
  | (FormData(formData), actionId) =>
    switch (formData, actionId) {
    // react-server-dom-webpack encode formData and put the first value as model reference E.g.:["$K1"], 1 is the id
    // QUESTION: Why is it like this? Is there a change to it be other than "$K"? Is there a way to get more ids?
    | ([(_, [(_, modelId)]), ...formData], Some(actionId)) =>
      let chunkId = Yojson.Basic.from_string(modelId);
      let chunkId =
        switch (chunkId) {
        | `List([`String(chunkId)]) => chunkId
        | _ => failwith("Invalid chunkId")
        };
      let formData =
        List.map(
          ((name, value)) => {
            // react-server-dom-webpack prefix the name with the id E.g.: ["1_name", "1_value"]
            let form_prefix =
              String.sub(chunkId, 2, String.length(chunkId) - 2) ++ "_";
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
      action(formData);
    // without JS enabled or hydration
    | ([(_, [(_, actionId)]), ...formData], None)
        when actionId == "$ACTION_ID" =>
      let formData = formData |> List.to_seq |> Hashtbl.of_seq;
      let action = formDataManifest(actionId);
      action(formData);
    | _ =>
      failwith(
        "Missing $ACTION_ID, this formData was not created by server-reason-react",
      )
    }

  | (Body(body), Some(actionId)) =>
    let action = actionsManifest(actionId);
    action(getArgs(body));
  | _ =>
    failwith(
      "Missing ACTION_ID, this request was not created by server-reason-react",
    )
  };
};
