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
let formDataRouteHandler = (_, formData) =>
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
FunctionReferences.register(formDataId, FormData(formDataRouteHandler));

switch%platform () {
| Server => ()
| Client => [%mel.raw
   {|
    // extract-server-function id/samples/formDataWithArg formDataWithArg.call
    ''
    |}
  ]
};

let formDataWithArgId = "id/samples/formDataWithArg";

[@platform native]
let formDataWithArgHandler = (timestamp: string, ~formData: Js.FormData.t) => {
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

  Lwt.return(React.Json(`String(response)));
};

[@platform native]
let formDataWithArgRouteHandler = (args, formData: Js.FormData.t) => {
  let timestamp =
    switch (args) {
    | [|`String(timestamp)|] => timestamp
    | _ => ""
    };

  try%lwt(formDataWithArgHandler(timestamp, ~formData)) {
  | exn => Lwt.fail(exn)
  };
};

let formDataWithArg =
  switch%platform () {
  | Server => {
      Runtime.id: formDataWithArgId,
      call: (timestamp: string, formData: Js.FormData.t) =>
        formDataWithArgHandler(timestamp, ~formData),
    }
  | Client => {
      Runtime.id: formDataWithArgId,
      call: (timestamp: string, formData: Js.FormData.t) => {
        let action =
          ReactServerDOMEsbuild.createServerReference(formDataWithArgId);
        action(. timestamp, formData);
      },
    }
  };

[@platform native]
FunctionReferences.register(
  formDataWithArgId,
  FormData(formDataWithArgRouteHandler),
);
