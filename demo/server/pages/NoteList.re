open Lwt.Syntax;

[@react.async.component]
let make = () => {
  let+ notes = DB.readNotes();

  switch (notes) {
  | Error(error) =>
    <div className="notes-error">
      <Text> {"Couldn't read notes file: " ++ error} </Text>
    </div>
  | Ok(notes) when notes->List.length == 0 =>
    <div className="notes-empty">
      <Text> "There's no notes created yet!" </Text>
    </div>
  | Ok(notes) =>
    <ul className="mt-8">
      {notes
       |> List.map((note: Note.t) =>
            <li key={Int.to_string(note.id)}> <SidebarNote note /> </li>
          )
       |> React.list}
    </ul>
  };
};
