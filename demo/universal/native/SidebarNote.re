[@platform native]
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
      <div className="mt-2">
        {switch (String.trim(summary)) {
         | "" => <i> {React.string("(No content)")} </i>
         | s => <Text size=Small color=Theme.Color.Gray11> s </Text>
         }}
      </div>
    }>
    <header
      className={Cx.make(["max-w-[85%] flex flex-col gap-2"])}
      style={ReactDOM.Style.make(~zIndex="1", ())}>
      <Text size=Large weight=Bold> {note.title} </Text>
      <Text size=Small> lastUpdatedAt </Text>
    </header>
  </SidebarNoteContent>;
};
