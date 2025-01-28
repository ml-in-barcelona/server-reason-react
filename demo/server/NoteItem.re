open Lwt.Syntax;

module NotePreview = {
  [@react.component]
  let make = (~body: string) => {
    <div> {React.string(body)} </div>;
  };
};

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
        <div className="note">
          <div className="note-header">
            <h1 className="note-title"> {React.string(note.title)} </h1>
            <div className="note-menu" role="menubar">
              <Text size=Small role="status"> "Last updated on " </Text>
              /* ++ DateFns.format(updatedAt, "d MMM yyyy 'at' h:mm bb"), */
              <EditButton noteId={Some(note.id)}>
                {React.string("Edit")}
              </EditButton>
            </div>
          </div>
          <NotePreview body={note.content} />
        </div>;
      }
    | Error(error) =>
      <div className="notes-error">
        {React.string("Couldn't read notes file: " ++ error)}
      </div>
    };
  };
};
