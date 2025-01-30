open Lwt.Syntax;

[@react.async.component]
let make = () => {
  let+ notes = DB.readNotes();

  switch (notes) {
  | Error(error) =>
    <div
      className="mt-8 h-full w-full flex flex-col items-center justify-center gap-4">
      <Text size=XXLarge> "❌" </Text>
      <Text> "Couldn't read notes file" </Text>
      <Text weight=Bold> error </Text>
    </div>
  | Ok(notes) when notes->List.length == 0 =>
    <div className="mt-8">
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
