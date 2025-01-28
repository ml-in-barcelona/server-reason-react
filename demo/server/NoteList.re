open Lwt.Syntax;

[@react.async.component]
let make = (~searchText) => {
  let+ notes = DB.readNotes("./notes.json");

  switch (notes) {
  | Error(error) =>
    <div className="notes-error">
      <Text> {"Couldn't read notes file: " ++ error} </Text>
    </div>
  | Ok(notes) when notes->List.length == 0 =>
    <div className="notes-empty">
      <Text> "There's no notes created yet!" </Text>
    </div>
  | Ok(notes) when searchText != "" =>
    <div className="notes-empty">
      <Text> {"Couldn't find any notes titled " ++ searchText} </Text>
    </div>
  | Ok(notes) =>
    <ul>
      {notes
       |> List.map((note: Note.t) =>
            <li key={note.id}> <SidebarNote note /> </li>
          )
       |> React.list}
    </ul>
  };
};
