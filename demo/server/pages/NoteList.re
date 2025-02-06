open Lwt.Syntax;

let is_substring = (a, b) => {
  let len_a = String.length(a);
  let len_b = String.length(b);
  if (len_a > len_b) {
    false;
  } else {
    let rec check = start =>
      if (start > len_b - len_a) {
        false;
      } else if (String.sub(b, start, len_a) == a) {
        true;
      } else {
        check(start + 1);
      };
    check(0);
  };
};

[@react.async.component]
let make = (~searchText: string) => {
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
       |> List.filter((note: Note.t) =>
            is_substring(searchText, note.title)
          )
       |> List.map((note: Note.t) =>
            <li key={Int.to_string(note.id)}> <SidebarNote note /> </li>
          )
       |> React.list}
    </ul>
  };
};
