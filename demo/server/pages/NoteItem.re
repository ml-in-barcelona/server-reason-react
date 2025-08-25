open Lwt.Syntax;

module NoteView = {
  [@react.component]
  let make = (~note: Note.t) => {
    <div className="h-full">
      <div
        className="flex flex-row items-center w-full mb-8 justify-between gap-4">
        <div className="flex flex-col items-left gap-4" role="menubar">
          <h1
            className={Cx.make([
              "text-4xl font-bold",
              Theme.text(Theme.Color.Gray12),
            ])}>
            {React.string(note.title)}
          </h1>
          <Text size=Small role="status" color=Theme.Color.Gray10>
            {"Last updated on " ++ Date.format_date(note.updated_at)}
          </Text>
        </div>
        <Button noteId={Some(note.id)}> {React.string("Edit")} </Button>
        <DeleteNoteButton noteId={note.id} />
      </div>
      <NotePreview key="note-preview" body={Markdown.toHTML(note.content)} />
    </div>;
  };
};

[@react.async.component]
let make =
    (~selectedId: option(int), ~isEditing: bool, ~sleep: option(float)) => {
  switch (selectedId) {
  | None when isEditing =>
    Lwt.return(
      <NoteEditor noteId=None initialTitle="Untitled" initialBody="" />,
    )
  | None =>
    Lwt.return(
      <div className="flex flex-col h-full items-center justify-center gap-2">
        <Text size=XXLarge> "🥺" </Text>
        <Text> "Click a note on the left to view something!" </Text>
      </div>,
    )
  | Some(id) =>
    let+ note: result(Note.t, string) = DB.fetchNote(~sleep, id);

    switch (note) {
    | Ok(note) when !isEditing => <NoteView note />
    | Ok(note) =>
      <NoteEditor
        noteId={Some(note.id)}
        initialTitle={note.title}
        initialBody={note.content}
      />
    | Error(error) =>
      <div className="h-full w-full flex items-center justify-center">
        <div
          className="h-full w-full flex flex-col items-center justify-center gap-4">
          <Text size=XXLarge> "❌" </Text>
          <Text> "There's an error while loading a single note" </Text>
          <Text weight=Bold> error </Text>
        </div>
      </div>
    };
  };
};
