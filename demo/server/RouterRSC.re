module App = {
  [@react.component]
  let make = (~selectedId, ~isEditing, ~searchText) => {
    <DemoLayout background=Theme.Color.black mode=FullScreen>
      <section key="note-viewer" className="flex-1 basis-3/4">
        <React.Suspense fallback={<NoteSkeleton isEditing />}>
          <NoteItem selectedId isEditing />
        </React.Suspense>
      </section>
      <div className="flex flex-row gap-8">
        <section className="flex-1 basis-1/4 gap-4" key="sidebar">
          <section
            className="flex flex-col gap-1 z-1 max-w-[85%] pointer-events-none"
            key="sidebar-header">
            <Text size=XLarge weight=Bold> "React Notes" </Text>
            <Text> "migrated to (server)-reason-react and Melange" </Text>
          </section>
          <section className="sidebar-menu" role="menubar" key="menubar">
            <SearchField />
            <EditButton noteId=None> {React.string("New")} </EditButton>
          </section>
          <nav>
            <React.Suspense fallback={<NoteListSkeleton />}>
              <NoteList searchText />
            </React.Suspense>
          </nav>
        </section>
      </div>
    </DemoLayout>;
  };
};

let handler = request =>
  DreamRSC.createFromRequest(
    <App selectedId=None isEditing=false searchText="" />,
    "/static/demo/client/router.js",
    request,
  );
