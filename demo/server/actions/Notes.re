let delayed_value = (~ms, value) => {
  let%lwt () = Lwt_unix.sleep(Int.to_float(ms) /. 1000.0);
  Lwt.return(value);
};

let createNoteResponse = note => {
  React.Json(
    Note.(
      `Assoc([
        ("id", `Int(note.id)),
        ("title", `String(note.title)),
        ("content", `String(note.content)),
        ("updated_at", `Float(note.updated_at)),
      ])
    ),
  );
};

let create = body => {
  let body = Yojson.Basic.from_string(body);

  let title =
    body |> Yojson.Basic.Util.member("title") |> Yojson.Basic.Util.to_string;
  let content =
    body |> Yojson.Basic.Util.member("content") |> Yojson.Basic.Util.to_string;
  let note = DB.addNote(~title, ~content);
  let%lwt response =
    switch%lwt (note) {
    | Ok(note) => Lwt.return(createNoteResponse(note))
    | Error(e) => Lwt.return(React.Json(`String(e)))
    };

  let%lwt response = delayed_value(~ms=1000, response);
  Lwt.return(response);
};

let edit = body => {
  let body = Yojson.Basic.from_string(body);

  let id = body |> Yojson.Basic.Util.member("id") |> Yojson.Basic.Util.to_int;
  let title =
    body |> Yojson.Basic.Util.member("title") |> Yojson.Basic.Util.to_string;
  let content =
    body |> Yojson.Basic.Util.member("content") |> Yojson.Basic.Util.to_string;
  let note = DB.editNote(~id, ~title, ~content);
  let%lwt response =
    switch%lwt (note) {
    | Ok(note) => Lwt.return(createNoteResponse(note))
    | Error(e) => Lwt.return(React.Json(`String(e)))
    };

  let%lwt response = delayed_value(~ms=1000, response);
  Lwt.return(response);
};

let delete = body => {
  let body = Yojson.Basic.from_string(body);
  let id = body |> Yojson.Basic.Util.member("id") |> Yojson.Basic.Util.to_int;
  let _ = DB.deleteNote(id);
  let response = React.Json(`String("Note deleted"));

  let%lwt response = delayed_value(~ms=1000, response);
  Lwt.return(response);
};
