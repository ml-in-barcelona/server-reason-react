let db_cache = ref(None);

let readFile = file => {
  let (/) = Filename.concat;
  let path = Sys.getcwd() / "demo" / "server" / "db" / file;
  Lwt_io.with_file(~mode=Lwt_io.Input, path, Lwt_io.read);
};

let _createFile = (path, content: string) => {
  Lwt_io.with_file(
    ~mode=Lwt_io.Output,
    path,
    oc => {
      let%lwt () = Lwt_io.write(oc, content);
      let%lwt () = Lwt_io.flush(oc);
      Lwt.return();
    },
  );
};

let parseNotes = json => {
  switch (Yojson.Safe.from_string(json)) {
  | `List(notes) =>
    notes
    |> List.filter_map(note =>
         switch (note) {
         | `Assoc(fields) =>
           Some(
             {
               id: fields |> List.assoc("id") |> Yojson.Safe.to_string,
               title: fields |> List.assoc("title") |> Yojson.Safe.to_string,
               content:
                 fields |> List.assoc("content") |> Yojson.Safe.to_string,
               updated_at:
                 fields
                 |> List.assoc("updated_at")
                 |> Yojson.Safe.to_string
                 |> float_of_string,
             }: Note.t,
           )
         | _ => None
         }
       )
    |> Result.ok
  | _ => Result.error("Invalid notes file format")
  };
};

let readNotes = path => {
  switch%lwt (readFile(path)) {
  | json =>
    db_cache := Some(parseNotes(json));
    Lwt_result.lift(parseNotes(json));
  /* When something fails, treat it as an empty note db */
  | exception _error => Lwt.return_ok([])
  };
};

let fetchNote = id => {
  switch (db_cache^) {
  | Some(Ok(notes)) =>
    notes |> List.find((note: Note.t) => note.id == id) |> Lwt_result.return
  | Some(Error(e)) => Lwt_result.fail(e)
  | None => Lwt_result.fail("note not found")
  };
};
