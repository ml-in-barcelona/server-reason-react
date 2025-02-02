open Lwt.Syntax;

let readFile = file => {
  let (/) = Filename.concat;
  let path = Sys.getcwd() / "demo" / "server" / "db" / file;
  switch%lwt (Lwt_io.with_file(~mode=Lwt_io.Input, path, Lwt_io.read)) {
  | v => Lwt_result.return(v)
  | exception e =>
    Dream.log("Error reading file %s: %s", path, Printexc.to_string(e));
    Lwt.return_error(Printexc.to_string(e));
  };
};

let parseNote = (note: Yojson.Safe.t): option(Note.t) =>
  switch (note) {
  | `Assoc(fields) =>
    let id =
      fields |> List.assoc("id") |> Yojson.Safe.to_string |> int_of_string;
    let title = fields |> List.assoc("title") |> Yojson.Safe.Util.to_string;
    let content =
      fields |> List.assoc("content") |> Yojson.Safe.Util.to_string;
    let updated_at =
      fields
      |> List.assoc("updated_at")
      |> Yojson.Safe.to_string
      |> float_of_string;
    Some({
      id,
      title,
      content,
      updated_at,
    });
  | _ => None
  };

let parseNotes = json => {
  switch (Yojson.Safe.from_string(json)) {
  | `List(notes) => notes |> List.filter_map(parseNote) |> Result.ok
  | _ => Result.error("Invalid notes file format")
  | exception _ => Result.error("Invalid JSON format format")
  };
};

module Cache = {
  let db_cache = ref(None);
  let set = value => db_cache := Some(value);
  let read = () => db_cache^;
  let delete = () => db_cache := None;
};

let readNotes = () => {
  switch (Cache.read()) {
  | Some(Ok(notes)) => Lwt_result.return(notes)
  | Some(Error(e)) => Lwt_result.fail(e)
  | None =>
    switch%lwt (readFile("./notes.json")) {
    | Ok(json) =>
      Cache.set(parseNotes(json));
      Lwt_result.lift(parseNotes(json));
    | Error(_) => Lwt.return_error("Error reading notes file")
    }
  /* When something fails, treat it as an empty note db */
  | exception _error => Lwt.return_ok([])
  };
};

let findOne = (notes, id) => {
  switch (notes |> List.find_opt((note: Note.t) => note.id == id)) {
  | Some(note) => Lwt_result.return(note)
  | None =>
    Lwt_result.fail("Note with id " ++ Int.to_string(id) ++ " not found")
  };
};

let fetchNote = id => {
  switch (Cache.read()) {
  | Some(Ok(notes)) => findOne(notes, id)
  | Some(Error(e)) => Lwt_result.fail(e)
  | None =>
    let* notes = readNotes();
    switch (notes) {
    | Ok(notes) => findOne(notes, id)
    | Error(e) => Lwt_result.fail(e)
    };
  };
};
