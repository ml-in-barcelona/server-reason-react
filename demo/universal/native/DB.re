open Lwt.Syntax;

let repoRoot = () => {
  let exeDir = Filename.dirname(Sys.executable_name);
  let rec findRoot = dir =>
    if (Filename.basename(dir) == "_build") {
      Filename.dirname(dir);
    } else {
      let parent = Filename.dirname(dir);
      if (parent == dir) {
        Sys.getcwd();
      } else {
        findRoot(parent);
      };
    };
  findRoot(exeDir);
};

let runtimeRoot = () => {
  let (/) = Filename.concat;
  repoRoot() / "demo" / ".running";
};

let runtimeDbDir = () => {
  let (/) = Filename.concat;
  runtimeRoot() / "db";
};

let dbPath = file => {
  let (/) = Filename.concat;
  runtimeDbDir() / file;
};

let sourcePath = file => {
  let (/) = Filename.concat;
  repoRoot() / "demo" / "server" / "db" / file;
};

let readPath = path => {
  switch%lwt (Lwt_io.with_file(~mode=Lwt_io.Input, path, Lwt_io.read)) {
  | v => Lwt_result.return(v)
  | exception e =>
    Dream.log("Error reading file %s: %s", path, Printexc.to_string(e));
    Lwt.return_error(Printexc.to_string(e));
  };
};

let writePath = (path, content) => {
  switch%lwt (
    Lwt_io.with_file(~mode=Lwt_io.Output, path, c => Lwt_io.write(c, content))
  ) {
  | () => Lwt_result.return()
  | exception e =>
    Dream.log("Error writing file %s: %s", path, Printexc.to_string(e));
    Lwt.return_error(Printexc.to_string(e));
  };
};

let ensureDir = dir =>
  if (Sys.file_exists(dir)) {
    Lwt_result.return();
  } else {
    switch (Unix.mkdir(dir, 0o755)) {
    | () => Lwt_result.return()
    | exception e =>
      Dream.log(
        "Error creating directory %s: %s",
        dir,
        Printexc.to_string(e),
      );
      Lwt.return_error(Printexc.to_string(e));
    };
  };

let ensureDbDir = () => {
  let runtimeRoot = runtimeRoot();
  let runtimeDbDir = runtimeDbDir();
  switch%lwt (ensureDir(runtimeRoot)) {
  | Ok () => ensureDir(runtimeDbDir)
  | Error(e) => Lwt.return_error(e)
  };
};

let ensureDbFile = file => {
  let path = dbPath(file);
  let source = sourcePath(file);
  switch%lwt (ensureDbDir()) {
  | Error(e) => Lwt.return_error(e)
  | Ok () =>
    if (Sys.file_exists(path)) {
      Lwt_result.return();
    } else if (Sys.file_exists(source)) {
      switch%lwt (readPath(source)) {
      | Ok(content) => writePath(path, content)
      | Error(e) => Lwt.return_error(e)
      };
    } else {
      writePath(path, "[]");
    }
  };
};

let readFile = file => {
  let path = dbPath(file);
  switch%lwt (ensureDbFile(file)) {
  | Ok () => readPath(path)
  | Error(e) => Lwt.return_error(e)
  };
};

let writeFile = (file, content) => {
  let path = dbPath(file);
  switch%lwt (ensureDbDir()) {
  | Ok () => writePath(path, content)
  | Error(e) => Lwt.return_error(e)
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

let serializeNote = (note: Note.t): Yojson.Safe.t =>
  `Assoc([
    ("id", `Int(note.id)),
    ("title", `String(note.title)),
    ("content", `String(note.content)),
    ("updated_at", `Float(note.updated_at)),
  ]);

let serializeNotes = (notes: list(Note.t)): string =>
  `List(notes |> List.map(serializeNote)) |> Yojson.Safe.pretty_to_string;

let readNotesCached =
  React.cache(sleep => {
    Dream.log("[DB.readNotes] Fetching all notes from disk");
    let%lwt () =
      switch (sleep) {
      | Some(0.)
      | None => Lwt.return()
      | Some(delay) => Lwt_unix.sleep(delay)
      };

    switch%lwt (readFile("./notes.json")) {
    | Ok(json) => Lwt_result.lift(parseNotes(json))
    | Error(_) => Lwt.return_error("Error reading notes file")
    /* When something fails, treat it as an empty note db */
    | exception _error => Lwt.return_ok([])
    };
  });

let readNotes = (~sleep=None, ()) => readNotesCached(sleep);

let findOne =
  React.cache(((notes, id)) => {
    switch (notes |> List.find_opt((note: Note.t) => note.id == id)) {
    | Some(note) => Lwt_result.return(note)
    | None =>
      Lwt_result.fail("Note with id " ++ Int.to_string(id) ++ " not found")
    }
  });

let insertNote = (~title, ~content, notes) => {
  let id = List.length(notes);
  let note: Note.t = {
    id,
    title,
    content,
    updated_at: Unix.time(),
  };
  (note, [note, ...notes]);
};

let addNote = (~title, ~content) => {
  let%lwt notes = readNotes();
  let notes =
    Result.map(
      notes => {
        let (note, notes) = insertNote(~title, ~content, notes);
        (note, notes);
      },
      notes,
    );
  Lwt_result.lift(notes |> Result.map(((note, _)) => note));
};

let createNote = (~title, ~content) => {
  let%lwt notes = readNotes();
  switch (notes) {
  | Ok(notes) =>
    let (note, updatedNotes) = insertNote(~title, ~content, notes);
    switch%lwt (writeFile("./notes.json", serializeNotes(updatedNotes))) {
    | Ok () => Lwt_result.return(note)
    | Error(e) => Lwt_result.fail(e)
    };
  | Error(e) => Lwt_result.fail(e)
  };
};

let editNote = (~id, ~title, ~content) => {
  let%lwt notes = readNotes();
  let notes =
    Result.map(
      notes => {
        let notes =
          notes
          |> List.map((currentNote: Note.t) =>
               if (currentNote.id == id) {
                 {
                   ...currentNote,
                   title,
                   content,
                   updated_at: Unix.time(),
                 };
               } else {
                 currentNote;
               }
             );
        notes;
      },
      notes,
    );
  Lwt_result.lift(notes |> Result.map(notes => notes |> List.hd));
};

let deleteNote = id => {
  let%lwt notes = readNotes();
  let notes =
    Result.map(
      notes => notes |> List.filter((note: Note.t) => note.id != id),
      notes,
    );
  Lwt_result.lift(notes);
};

let fetchNoteCached =
  React.cache(((sleep, id)) => {
    Dream.log("[DB.fetchNote] Fetching note id=%d from disk", id);
    let%lwt () =
      switch (sleep) {
      | Some(delay) => Lwt_unix.sleep(delay)
      | None => Lwt.return()
      };

    let* notes = readNotes(~sleep, ());
    switch (notes) {
    | Ok(notes) => findOne((notes, id))
    | Error(e) => Lwt_result.fail(e)
    };
  });

let fetchNote = (~sleep=None, id) => fetchNoteCached((sleep, id));
