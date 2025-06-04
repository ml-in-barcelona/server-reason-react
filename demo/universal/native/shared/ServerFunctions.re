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

let formDataId = "id/samples/formData";

switch%platform () {
| Server => ()
| Client => [%mel.raw
   {|
   // extract-server-function id/samples/formData formData.call
   ''
   |}
  ]
};

[@platform native]
let formDataHandler = (~formData: Js.FormData.t) => {
  let name =
    switch (formData->Js.FormData.get("name")) {
    | `String(name) => name
    };

  let response = Printf.sprintf("Form data received: %s", name);

  Lwt.return(response);
};

[@platform native]
let formDataRouteHandler = formData =>
  try(
    Lwt.map(
      response => React.Json(`String(response)),
      formDataHandler(~formData),
    )
  ) {
  | e => Lwt.fail(e)
  };

let formData =
  switch%platform () {
  | Server => {
      Runtime.id: formDataId,
      call: (formData: Js.FormData.t) => formDataHandler(~formData),
    }
  | Client => {
      Runtime.id: formDataId,
      call: (formData: Js.FormData.t) => {
        let action = ReactServerDOMEsbuild.createServerReference(formDataId);
        action(. formData);
      },
    }
  };

[@platform native]
FunctionReferences.register(formData.id, FormData(formDataRouteHandler));
