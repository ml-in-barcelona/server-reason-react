open Lwt.Syntax;

[@react.async.component]
let make = (~searchText) => {
  let+ notes = DB.readNotes("./notes.json");

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
    Js.log("notes");
    <ul className="p-2">
      {notes
       |> List.map((note: Note.t) =>
            <li key={note.id}> <SidebarNote note /> </li>
          )
       |> React.list}
    </ul>;
  };
};
