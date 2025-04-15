module Notes = {
  [@platform native]
  let createNoteResponse = note => {
    Note.(
      `Assoc([
        ("id", `Int(note.id)),
        ("title", `String(note.title)),
        ("content", `String(note.content)),
        ("updated_at", `Float(note.updated_at)),
      ])
    );
  };

  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let createHandler = (~title, ~content) => {
      let note = DB.addNote(~title, ~content);
      let%lwt response =
        switch%lwt (note) {
        | Ok(note) => Lwt.return(createNoteResponse(note))
        | Error(e) => failwith(e)
        };
      Lwt.return(response);
    };
   */
  // It's going to be on top to this that we are going to generate the codes bellow
  let createId = "id/notes/create";

  [@platform native]
  let createHandler = (~title, ~content) => {
    let note = DB.addNote(~title, ~content);
    let%lwt response =
      switch%lwt (note) {
      | Ok(note) => Lwt.return(createNoteResponse(note))
      | Error(e) => failwith(e)
      };
    Lwt.return(response);
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let createRouteHandler = args => {
    // Parse the body to get the args
    let (title, content) =
      switch (args) {
      | [title, content] => (
          // It would be handle by a title_of_json/content_of_json in the future provided by the end-user and the ppx
          title |> Yojson.Basic.Util.to_string,
          content |> Yojson.Basic.Util.to_string,
        )
      | _ =>
        failwith(
          Printf.sprintf(
            "Invalid arguments %s",
            args
            |> List.map(Yojson.Basic.Util.to_string)
            |> String.concat(","),
          ),
        )
      };

    createHandler(~title, ~content);
  };

  // This is the action generated to be used under the hood for the server and client
  let create =
    switch%platform () {
    | Server => createHandler
    | Client => (
        (~title, ~content) => {
          // Register the action for the client
          let action =
            ReactServerDOMWebpack.createServerReference(
              createId,
              Some("create"),
            );
          action(. title, content);
        }
      )
    };

  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let editHandler = (~id, ~title, ~content) => {
      let note = DB.editNote(~id, ~title, ~content);
      let%lwt response =
        switch%lwt (note) {
        | Ok(note) => Lwt.return(createNoteResponse(note))
        | Error(e) => failwith(e)
        };
      Lwt.return(response);
    };
  */
  // It's going to be on top to this that we are going to generate the codes bellow
  let editId = "id/notes/edit";

  [@platform native]
  let editHandler = (~id, ~title, ~content) => {
    let note = DB.editNote(~id, ~title, ~content);
    let%lwt response =
      switch%lwt (note) {
      | Ok(note) => Lwt.return(createNoteResponse(note))
      | Error(e) => failwith(e)
      };

    Lwt.return(response);
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let editRouteHandler = args => {
    // Parse the body to get the args
    // This will be generated by some ppx
    let (id, title, content) =
      switch (args) {
      | [id, title, content] => (
          // It would be handle by a id_of_json/title_of_json/content_of_json in the future provided by the end-user and the ppx
          id |> Yojson.Basic.Util.to_int,
          title |> Yojson.Basic.Util.to_string,
          content |> Yojson.Basic.Util.to_string,
        )
      | _ =>
        failwith(
          Printf.sprintf(
            "Invalid arguments %s",
            args
            |> List.map(Yojson.Basic.Util.to_string)
            |> String.concat(","),
          ),
        )
      };

    editHandler(~id, ~title, ~content);
  };

  // This is the action generated to be used under the hood for the server and client
  let edit =
    switch%platform () {
    | Server => editHandler
    | Client => (
        (~id, ~title, ~content) => {
          let action =
            ReactServerDOMWebpack.createServerReference(
              editId,
              Some("edit"),
            );

          action(. id, title, content);
        }
      )
    };

  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let deleteHandler = (~id) => {
      let _ = DB.deleteNote(id);
      let response = `String("Note deleted");
      Lwt.return(response);
    };
  */
  // It's going to be on top to this that we are going to generate the codes bellow
  let deleteId = "id/notes/delete";

  [@platform native]
  let deleteHandler = (~id) => {
    let _ = DB.deleteNote(id);
    let response = `String("Note deleted");
    Lwt.return(response);
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let deleteRouteHandler = args => {
    // Parse the body to get the args
    // This will be generated by some ppx
    let id =
      // It would be handle by a id_of_json in the future provided by the end-user and the ppx
      switch (args) {
      | [id] => id |> Yojson.Basic.Util.to_int
      | _ =>
        failwith(
          Printf.sprintf(
            "Invalid arguments %s",
            args
            |> List.map(Yojson.Basic.Util.to_string)
            |> String.concat(","),
          ),
        )
      };

    deleteHandler(~id);
  };

  // This is the action generated to be used under the hood for the server and client
  let delete =
    switch%platform () {
    | Server => deleteHandler
    | Client => (
        (~id) => {
          let action =
            ReactServerDOMWebpack.createServerReference(
              deleteId,
              Some("delete"),
            );

          action(. [|id|]);
        }
      )
    };
};

module Samples = {
  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let formDataHandler = formData => {
      let (_, name) = Hashtbl.find(formData, "name") |> List.hd;
      let (_, lastName) = Hashtbl.find(formData, "lastName") |> List.hd;
      let (_, age) = Hashtbl.find(formData, "age") |> List.hd;

      Dream.log("Hello %s %s, you are %s years old", name, lastName, age);

      Lwt.return(
        (`String("Hello from server with form data action")),
      );
    };
  */
  // It's going to be on top to this that we are going to generate the codes bellow
  let formDataId = "id/samples/form-data";

  [@platform native]
  let formDataHandler = formData => {
    // For now, we are handling it by calling the value from Hashtbl
    // We already have an issue to create FormData at Js.
    let (_, name) = Hashtbl.find(formData, "name") |> List.hd;
    let (_, lastName) = Hashtbl.find(formData, "lastName") |> List.hd;
    let (_, age) = Hashtbl.find(formData, "age") |> List.hd;

    Dream.log("Hello %s %s, you are %s years old", name, lastName, age);

    Lwt.return(`String("Hello from server with form data action"));
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let formDataRouteHandler = formData => {
    formDataHandler(formData);
  };

  let formData =
    switch%platform () {
    | Server => formDataHandler
    | Client => (
        formData => {
          let action =
            ReactServerDOMWebpack.createServerReference(
              formDataId,
              Some("formData"),
            );
          action(. formData);
        }
      )
    };

  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let simpleResponse = () => {
      Lwt.return(
        (`String("Hello from server with simple response action")),
      );
    };
  */
  // It's going to be on top to this that we are going to generate the codes bellow
  let simpleResponseId = "id/samples/simpleResponse";

  [@platform native]
  let simpleResponseHandler = () => {
    Lwt.return(`String("Hello from server with simple response action"));
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let simpleResponseRouteHandler = _args => simpleResponseHandler();

  let simpleResponse =
    switch%platform () {
    | Server => demoActionSimpleResponse
    | Client => (
        _ => {
          let action =
            ReactServerDOMWebpack.createServerReference(
              demoActionSimpleResponse,
              Some("simpleResponse"),
            );
          action(.);
        }
      )
    };

  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let log = (~request, message) => {
      Dream.log("Logging: %s", message);
      Lwt.return_none;
    };
  */
  // It's going to be on top to this that we are going to generate the codes bellow

  // As soon the user declare the action with a request, we pass it from the router to the handler,
  [@platform native]
  let logHandler = (~request, _args) => {
    Dream.log("Logging: Hello on server");
    Lwt.return_none;
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user declare the action with a request, we pass it from the router to the handler
  [@platform native]
  let logRouteHandler = (~request, _args) => logHandler(~request, _args);

  let log =
    switch%platform () {
    | Server => demoActionSimpleResponse
    | Client => (
        _ => {
          let action =
            ReactServerDOMWebpack.createServerReference(
              simpleResponseId,
              Some("simpleResponse"),
            );
          action(.);
        }
      )
    };
};
