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
  // react encodes formData and put the first value as model reference E.g.:["$K1"], 1 is the id, $K is the formData reference prefix
  let modelId =
    FormData.get(formData, "0")
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

  let action = get(actionId);
  switch (action) {
  | FormData(action) => action(formData)
  | _ =>
    failwith(
      "Expected a FormData server function, this request was not created by server-reason-react.",
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
