module Cache = {
  let db_cache = ref(None);
  let set = value => db_cache := Some(value);
  let read = () => db_cache^;
  let delete = () => db_cache := None;
};

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
    Cache.set(parseNotes(json));
    Lwt_result.lift(parseNotes(json));
  /* When something fails, treat it as an empty note db */
  | exception _error => Lwt.return_ok([])
  };
};

let findOne = (notes, id) => {
  notes |> List.find((note: Note.t) => note.id == id);
};

let fetchNote = id => {
  switch (Cache.read()) {
  | Some(Ok(notes)) => findOne(notes, id) |> Lwt_result.return
  | Some(Error(e)) => Lwt_result.fail(e)
  | None =>
    let%lwt notes = readNotes("notes.json");
    switch (notes) {
    | Ok(notes) => findOne(notes, id) |> Lwt_result.return
    | Error(e) => Lwt_result.fail(e)
    };
  };
};
