module App = {
  [@react.component]
  let make = (~selectedId, ~isEditing, ~searchText) => {
    <DemoLayout background=Theme.Color.black mode=FullScreen>
      <div className="main">
        <section className="col sidebar" key="sidebar">
          <section className="sidebar-header" key="sidebar-header">
            <strong> {React.string("React Notes")} </strong>
            <span>
              {React.string("migrated to (server)-reason-react and Melange")}
            </span>
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
        <section key="note-viewer" className="col note-viewer">
          <React.Suspense fallback={<NoteSkeleton isEditing />}>
            <NoteItem selectedId isEditing />
          </React.Suspense>
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
