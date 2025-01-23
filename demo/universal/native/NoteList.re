open Lwt.Syntax;

let readNotes = path => {
  let* content = Lwt_io.with_file(~mode=Lwt_io.Input, path, Lwt_io.read);
  let json = Yojson.Safe.from_string(content);

  switch (json) {
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
    |> Lwt_result.return
  | _ => Lwt_result.fail("Invalid notes file format")
  };
};

[@react.async.component]
let make = (~searchText) => {
  // const notes = await (await fetch('http://localhost:4000/notes')).json();
  // WARNING: This is for demo purposes only.
  // We don't encourage this in real apps. There are far safer ways to access
  // data in a real application!
  /* const notes = (
       await db.query(
         `select * from notes where title ilike $1 order by id desc`,
         ['%' + searchText + '%']
       )
     ).rows; */
  // Now let's see how the Suspense boundary above lets us not block on this.
  // await fetch('http://localhost:4000/sleep/3000');

  let+ notes = readNotes("notes.json");

  switch (notes) {
  | Error(error) =>
    <div className="notes-empty">
      {React.string("Couldn't read notes file: " ++ error)}
    </div>
  | Ok(notes) when notes->List.length == 0 =>
    <div className="notes-empty">
      {React.string(
         searchText == ""
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
