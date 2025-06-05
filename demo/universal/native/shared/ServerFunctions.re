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
  let name =
    Js.FormData.get(formData, "name")
    |> (
      fun
      | `String(name) => name
    );
  let age =
    Js.FormData.get(formData, "age")
    |> (
      fun
      | `String(age) => age
    );

  Lwt.return(Printf.sprintf("Hello %s, you are %s years old", name, age));
};
