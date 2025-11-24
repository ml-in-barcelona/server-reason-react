open Melange_json.Primitives;

[@deriving json]
type notePreview = {
  id: int,
  title: string,
  content: string,
  updated_at: string,
};

[@react.client.component]
let make = (~note: notePreview) => {
  <NestedRouter_SidebarNoteContent
    id={note.id}
    expandedChildren={
      <div className="mt-2">
        {switch (String.trim(note.content)) {
         | "" => <i> {React.string("(No content)")} </i>
         | s => <Text size=Small color=Theme.Color.Gray11> s </Text>
         }}
      </div>
    }>
    <header
      className={Cx.make(["max-w-[85%] flex flex-col gap-2"])}
      style={ReactDOM.Style.make(~zIndex="1", ())}>
      <Text size=Large weight=Bold> {note.title} </Text>
      <Text size=Small> {note.updated_at} </Text>
    </header>
  </NestedRouter_SidebarNoteContent>;
};
