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
  | (FormData(_), _) =>
    failwith("We don't support form data in server actions yet")
  | (Body(body), Some(actionId)) =>
    let action = actionsManifest(actionId);
    action(getArgs(body));
  | _ =>
    failwith(
      "Missing ACTION_ID, this request was not created by server-reason-react",
    )
  };
};
