include Melange_json.Primitives;

module Notes = {
  [@react.server.function]
  let create = (~title: string, ~content: string): Js.Promise.t(Note.t) => {
    let note = DB.addNote(~title, ~content);
    let%lwt response =
      switch%lwt (note) {
      | Ok(note) => Lwt.return(note)
      | Error(e) => failwith(e)
      };
    Lwt.return(response);
  };

  [@react.server.function]
  let edit =
      (~id: int, ~title: string, ~content: string): Js.Promise.t(Note.t) => {
    let note = DB.editNote(~id, ~title, ~content);
    let%lwt response =
      switch%lwt (note) {
      | Ok(note) => Lwt.return(note)
      | Error(e) => failwith(e)
      };

    Lwt.return(response);
  };
  [@react.server.function]
  let delete_ = (~id: int): Js.Promise.t(string) => {
    let _ = DB.deleteNote(id);
    Lwt.return("Note deleted");
  };

  module Registers = {
    [@platform native]
    ServerReference.register(create.id, createRouteHandler);

    [@platform native]
    ServerReference.register(edit.id, editRouteHandler);

    [@platform native]
    ServerReference.register(delete_.id, delete_RouteHandler);
  };
};

module Samples = {
  [@react.server.function]
  let simpleResponse = (~name: string, ~age: int): Js.Promise.t(string) => {
    Lwt.return(Printf.sprintf("Hello %s, you are %d years old", name, age));
  };

  [@react.server.function]
  let error = (): Js.Promise.t(string) => {
    // Uncomment to see that it also works with Lwt.fail
    // Lwt.fail(failwith("Error from server"));
    failwith(
      "Error from server",
    );
  };

  let formDataId = "id/samples/formData";

  [@platform native]
  let formDataRouteHandler = formData => {
    let (name, lastName, age) =
      switch (
        formData->FormData.get("name"),
        formData->FormData.get("lastName"),
        formData->FormData.get("age"),
      ) {
      | (`String(name), `String(lastName), `String(age)) => (
          name,
          lastName,
          age,
        )
      | exception _ => failwith("Invalid formData.")
      };

    let response =
      Printf.sprintf("Form data received: %s, %s, %s", name, lastName, age);

    Lwt.return(React.Json(`String(response)));
  };

  let formData =
    switch%platform () {
    | Server => {
        Runtime.id: formDataId,
        call: ((. formData: FormData.t) => formDataRouteHandler(formData)),
      }
    | Client => {
        Runtime.id: formDataId,
        call: (
          (. formData: Js.FormData.t) => {
            let action =
              ReactServerDOMEsbuild.createServerReference(formDataId);
            action(. formData);
          }
        ),
      }
    };

  module Registers = {
    [@platform native]
    ServerReference.register(simpleResponse.id, simpleResponseRouteHandler);

    [@platform native]
    ServerReference.register(error.id, errorRouteHandler);

    [@platform native]
    ServerReference.registerForm(formDataId, formDataRouteHandler);
  };
};
