// QUESTION: How should we create this manifest automatically?
let actionsManifest = (id: string) => {
  switch (id) {
  | id when Router.demoActionCreateNote == id => Actions.Notes.createRouteHandler
  | id when Router.demoActionEditNote == id => Actions.Notes.editRouteHandler
  | id when Router.demoActionDeleteNote == id => Actions.Notes.deleteRouteHandler
  | id when Router.demoActionSimpleResponse == id => Actions.Samples.simpleResponseRouteHandler
  | _ => failwith("No action")
  };
};

// QUESTION: How should we create this manifest automatically?
let formDataManifest = (id: string) => {
  switch (id) {
  | id when Router.demoActionFormDataSample == id => Actions.Samples.formDataRouteHandler
  | id when Router.demoActionFormDataServerOnly == id => Actions.Samples.formDataServerOnlyRouteHandler
  | _ => failwith("No action")
  };
};

// This handler is agnostic to the server framework
let actionsHandler = (contentType, actionId) => {
  switch (contentType, actionId) {
  | (contentType, actionId)
      when String.starts_with(contentType, ~prefix="multipart/form-data") =>
    `FormData(
      formData => {
        // Getting the actionId from the formData as next.js does
        switch (formData, actionId) {
        // react-server-dom-webpack encode formData and put the first value as model reference E.g.:["$K1"], 1 is the id
        // QUESTION: Why is it like this? Is there a change to it be other than "$K"? Is there a way to get more ids?
        | ([(_, [(_, modelId)]), ...formData], Some(actionId)) =>
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
      },
    )
  | (_, Some(actionId)) =>
    `Body(
      body => {
        let action = actionsManifest(actionId);
        action(body);
      },
    )
  | _ =>
    failwith(
      "Missing $ACTION_ID, this formData was not created by server-reason-react",
    )
  };
};
