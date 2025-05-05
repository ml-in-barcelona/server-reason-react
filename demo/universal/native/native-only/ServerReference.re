type serverFunction = list(Yojson.Basic.t) => Lwt.t(React.client_value);

// [TODO] Create the parser on ReactServerDOM
let decodeReply = body => {
  switch (Yojson.Basic.from_string(body)) {
  // When there is no args, the react will send a list with a single string "$undefined"
  | `List([`String("$undefined")]) => []
  | `List(args) => args
  | _ =>
    failwith(
      "Invalid args, this request was not created by server-reason-react",
    )
  };
};
let serverFunctions: Hashtbl.t(string, serverFunction) = Hashtbl.create(10);

let register = (id, serverFunction) => {
  Hashtbl.add(serverFunctions, id, serverFunction);
};

let get = id => {
  Hashtbl.find(serverFunctions, id);
};

let handler = (actionId, content) => {
  let action = get(actionId);
  action(decodeReply(content));
};
