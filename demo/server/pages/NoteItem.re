open Lwt.Syntax;

[@react.async.component]
let make = (~selectedId: option(int), ~isEditing: bool) => {
  switch (selectedId) {
  | None =>
    if (isEditing) {
      Lwt.return(
        <NoteEditor noteId=None initialTitle="Untitled" initialBody="" />,
      );
    } else {
      Lwt.return(
        <div className="flex h-full items-center justify-center">
          <Text> "Click a note on the left to view something! 🥺" </Text>
        </div>,
      );
    }
  | Some(id) =>
    let+ note: result(Note.t, string) = DB.fetchNote(id);

    switch (note) {
    | Ok(note) =>
      if (isEditing) {
        <NoteEditor
          noteId={Some(note.id)}
          initialTitle={note.title}
          initialBody={note.content}
        />;
      } else {
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
          </div>
          <NotePreview key="note-preview" body={note.content} />
        </div>;
      }
    | Error(error) =>
      <div className="notes-error">
        {React.string("Couldn't read notes file: " ++ error)}
      </div>
    };
  };
};
