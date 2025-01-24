open Lwt.Syntax;

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
  | json => Lwt_result.lift(parseNotes(json))
  /* When something fails, treat it as an empty note db */
  | exception _error => Lwt.return_ok([])
  };
};

[@react.async.component]
let make = (~searchText) => {
  let+ notes = readNotes("./notes.json");

  switch (notes) {
  | Error(error) =>
    <div className="notes-error">
      {React.string("Couldn't read notes file: " ++ error)}
    </div>
  | Ok(notes) when notes->List.length == 0 =>
    <div className="notes-empty">
      {React.string(
         searchText != ""
           ? "Couldn't find any notes titled " ++ searchText
           : "No notes created yet!",
       )}
    </div>
  | Ok(notes) =>
    <ul className="notes-list">
      {notes
       |> List.map((note: Note.t) =>
            <li key={note.id}> <SidebarNote note /> </li>
          )
       |> React.list}
    </ul>
  };
};
