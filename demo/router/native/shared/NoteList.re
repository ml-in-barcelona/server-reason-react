[@platform native]
let readNotesCached = React.cache(sleep => DB.readNotes(~sleep, ()));

module NoteList = {
  [@react.client.component]
  let make = (~notes: list(SidebarNote.notePreview)) => {
    let { Router.searchText } = Router.useSearch();
    let searchText = searchText |> Option.value(~default="");

    <ul className="mt-8">
      {Array.of_list(
         notes
         |> List.filter((note: SidebarNote.notePreview) =>
              TextSearch.contains(
                ~needle=String.lowercase_ascii(searchText),
                ~haystack=String.lowercase_ascii(note.title),
              )
            )
         |> List.map((note: SidebarNote.notePreview) =>
              <li key={NoteId.to_string(note.id)}> <SidebarNote note /> </li>
            ),
       )
       |> React.array}
    </ul>;
  };
};

[@platform native]
[@react.async.component]
let make = () => {
  open Lwt.Syntax;
  let+ notes = readNotesCached(None);

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
    let markdownNotes =
      notes
      |> List.map(note => {
           let summary =
             note.Note.content
             |> Markdown.extract_text
             |> Markdown.summarize(~words=20);

           let lastUpdatedAt =
             if (Date.is_today(note.updated_at)) {
               Date.format_time(note.updated_at);
             } else {
               Date.format_date(note.updated_at);
             };

           {
             SidebarNote.id: NoteId.ofInt(note.id),
             title: note.title,
             content: summary,
             updated_at: lastUpdatedAt,
           };
         });

    <NoteList notes=markdownNotes />;
  };
};
