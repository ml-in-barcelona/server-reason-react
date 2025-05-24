type serverFunction =
  | FormData(FormData.t => Lwt.t(React.client_value))
  | Body(list(Yojson.Basic.t) => Lwt.t(React.client_value));

let serverFunctions: Hashtbl.t(string, serverFunction) = Hashtbl.create(10);
let register = (id, serverFunction) => {
  Hashtbl.add(serverFunctions, id, Body(serverFunction));
};
let registerForm = (id, serverFunction) => {
  Hashtbl.add(serverFunctions, id, FormData(serverFunction));
};
let get = id => {
  Hashtbl.find(serverFunctions, id);
};

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

let formDataHandler = (formData, actionId) => {
  let modelId =
    FormData.get_opt(formData, "0")
    |> Option.fold(~none=None, ~some=value => {
         switch (value) {
         | `String(modelId) =>
           let modelId =
             Yojson.Basic.from_string(modelId)
             |> (
               fun
               | `List([`String(referenceId)]) => referenceId
               | _ => failwith("Invalid referenceId")
             );
           Some(modelId);
         }
       });

  let formData =
    Hashtbl.fold(
      (key, value, acc) =>
        if (key == "0") {
          formData;
        } else {
          switch (modelId) {
          | Some(modelId) =>
            // react prefix the name with the id E.g.: ["1_name", "1_value"]
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
    // react-server-dom-webpack encode formData and put the first value as model reference E.g.:["$K1"], 1 is the id, $K is the formData reference prefix
    | Some(actionId) => actionId
    // without JS enabled or hydration
    | None =>
      try({
        let actionId =
          FormData.get_opt(formData, "$ACTION_ID")
          |> (
            fun
            | Some(`String(actionId)) => actionId
            | _ => failwith("Invalid actionId")
          );
        actionId;
      }) {
      | _ =>
        failwith(
          "Missing $ACTION_ID, this formData was not created by server-reason-react",
        )
      }
    };

  let action = get(actionId);
  switch (action) {
  | FormData(action) => action(formData)
  | _ =>
    failwith(
      "Expected a FormData server function, this request was not created by server-reason-react",
    )
  };
};

let bodyHandler = (body, actionId) => {
  let body = decodeReply(body);
  let action = get(actionId);
  switch (action) {
  | Body(action) => action(body)
  | _ =>
    failwith(
      "Expected a Body server function, this request was not created by server-reason-react",
    )
  };
};
