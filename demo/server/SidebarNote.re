[@react.component]
let make = (~note: Note.t) => {
  let lastUpdatedAt =
    if (Date.is_today(note.updated_at)) {
      Date.format_time(note.updated_at);
    } else {
      Date.format_date(note.updated_at);
    };

  let summary =
    note.content |> Markdown.extract_text |> Markdown.summarize(~words=20);

  <SidebarNoteContent
    id={note.id}
    title={note.title}
    expandedChildren={
      <p className="sidebar-note-excerpt">
        {switch (String.trim(summary)) {
         | "" => <i> {React.string("(No content)")} </i>
         | s => React.string(s)
         }}
      </p>
    }>
    <header className="sidebar-note-header">
      <strong> {React.string(note.title)} </strong>
      <small> {React.string(lastUpdatedAt)} </small>
    </header>
  </SidebarNoteContent>;
};
