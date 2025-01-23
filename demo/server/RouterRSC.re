module App = {
  [@react.component]
  let make = (~selectedId, ~isEditing, ~searchText) => {
    <Layout background=Theme.Color.black>
      <div className="main">
        <section className="col sidebar" key="sidebar">
          <section className="sidebar-header" key="sidebar-header">
            <img
              className="logo"
              src="logo.svg"
              width="22px"
              height="20px"
              alt=""
              role="presentation"
            />
            <strong> {React.string("React Notes")} </strong>
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
    </Layout>;
  };
};

let handler = request =>
  DreamRSC.createFromRequest(
    <App selectedId=None isEditing=false searchText="" />,
    "/static/demo/client/router.js",
    request,
  );
