open Melange_json.Primitives;

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
};

[@react.server.function]
let simpleResponse = (~name: string, ~age: int): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello %s, you are %d years old", name, age));
};

[@react.server.function]
let error = (): Js.Promise.t(string) => {
  // Uncomment to see that it also works with Lwt.fail
  Lwt.fail(
    failwith("Error from server"),
    // failwith(
    //   "Error from server",
    // );
  );
};

[@react.server.function]
let formDataFunction = (formData: Js.FormData.t): Js.Promise.t(string) => {
  let (name, lastName, age) =
    switch (
      formData->Js.FormData.get("name"),
      formData->Js.FormData.get("lastName"),
      formData->Js.FormData.get("age"),
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

  Lwt.return(response);
};
