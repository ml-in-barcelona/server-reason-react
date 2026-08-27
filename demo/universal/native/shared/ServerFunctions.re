module Notes = {
  [@react.server.function]
  let create = (~title: string, ~content: string): Js.Promise.t(Note.t) => {
    let note = DB.createNote(~title, ~content);
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
    switch%lwt (DB.deleteNote(id)) {
    | Ok(_) => Lwt.return("Note deleted")
    | Error(error) => Lwt.fail_with(error)
    };
  };
};

[@react.server.function]
let simpleResponse = (~name: string, ~age: int): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello %s, you are %d years old", name, age));
};

[@react.server.function]
let error = (): Js.Promise.t(string) => {
  Lwt.fail(failwith("Error from server"));
};

[@react.server.function]
let formDataFunction = (formData: Js.FormData.t): Js.Promise.t(string) => {
  let name =
    switch (formData->Js.FormData.get("name")) {
    | `String(name) => name
    | exception _ => failwith("Invalid formData.")
    };

  let response = Printf.sprintf("Form data received: %s", name);

  Lwt.return(response);
};

[@react.server.function]
let formDataWithArg =
    (timestamp: string, formData: Js.FormData.t): Js.Promise.t(string) => {
  let country =
    switch (formData->Js.FormData.get("country")) {
    | `String(country) => country
    };

  let response =
    Printf.sprintf(
      "Form data received: %s, timestamp: %s",
      country,
      timestamp,
    );

  Lwt.return(response);
};

[@react.server.function]
let optionalAction = (): Js.Promise.t(string) => {
  Lwt.return("Optional action executed!");
};

[@react.server.function]
let withOptionalGreeting =
    (~greeting: option(string)=?, ~name: string, ()): Js.Promise.t(string) => {
  let greeting = Option.value(greeting, ~default="Hello");
  Lwt.return(Printf.sprintf("%s, %s!", greeting, name));
};

[@react.server.function]
let getSessionUser = (): Js.Promise.t(string) => {
  let name =
    DreamRouter.get_cookie("demo_user") |> Option.value(~default="anonymous");
  Lwt.return("Hello, " ++ name ++ "!");
};

[@react.server.function]
let getUserAgent = (): Js.Promise.t(string) => {
  let ua =
    DreamRouter.get_header("User-Agent") |> Option.value(~default="unknown");
  Lwt.return(ua);
};

[@react.server.function]
let setSessionUser = (~name: string): Js.Promise.t(string) => {
  DreamRouter.set_cookie(~path="/", "demo_user", name);
  Lwt.return("Cookie set for " ++ name ++ "!");
};
