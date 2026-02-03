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

[@platform native]
let readNotesCached = React.cache(sleep => DB.readNotes(~sleep, ()));

module NoteList = {
  open Melange_json.Primitives;
  [@react.client.component]
  let make = (~notes: list(NestedRouter_SidebarNote.notePreview)) => {
    let { Router.url, _ } = Router.useRouter();
    let queryParams = url |> URL.searchParams;

    let searchText =
      URL.SearchParams.get(queryParams, "searchText")
      |> Option.value(~default="");

    <ul className="mt-8">
      {Array.of_list(
         notes
         |> List.filter((note: NestedRouter_SidebarNote.notePreview) =>
              is_substring(
                String.lowercase_ascii(searchText),
                String.lowercase_ascii(note.title),
              )
            )
         |> List.map((note: NestedRouter_SidebarNote.notePreview) =>
              <li key={Int.to_string(note.id)}>
                <NestedRouter_SidebarNote note />
              </li>
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
             NestedRouter_SidebarNote.id: note.id,
             title: note.title,
             content: summary,
             updated_at: lastUpdatedAt,
           };
         });

    <NoteList notes=markdownNotes />;
  };
};
