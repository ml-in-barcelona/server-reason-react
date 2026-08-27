module NoteView = {
  [@react.component]
  let make = (~note: Note.t) => {
    let id = NoteId.make(note.id);

    <div className="h-full">
      <div
        className="flex flex-row items-center w-full mb-8 justify-between gap-4">
        <div className="flex flex-col items-left gap-4">
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
        <EditButton noteId=id> {React.string("Edit")} </EditButton>
        <DeleteNoteButton id />
      </div>
      <NotePreview key="note-preview" body={Markdown.toHTML(note.content)} />
    </div>;
  };
};

[@react.component]
let make = (~note: Note.t, ~isEditing: bool) =>
  isEditing
    ? <NoteEditor
        id={Some(NoteId.make(note.id))}
        initialTitle={note.title}
        initialBody={note.content}
      />
    : <NoteView note />;
