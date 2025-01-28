module App = {
  [@react.component]
  let make = (~selectedId, ~isEditing, ~searchText) => {
    <DemoLayout background=Theme.Color.black mode=FullScreen>
      <div className="flex flex-row gap-8">
        <section
          className="flex-1 basis-1/4 gap-4 min-w-[300px]" key="sidebar">
          <section
            className="flex flex-col gap-1 z-1 max-w-[85%] pointer-events-none mb-6"
            key="sidebar-header">
            <Text size=XLarge weight=Bold> "React Notes" </Text>
            <Text> "migrated to (server)-reason-react and Melange" </Text>
          </section>
          /* <section className="sidebar-menu" role="menubar" key="menubar">
               <SearchField />
               <EditButton noteId=None> {React.string("New")} </EditButton>
             </section> */
          <Hr />
          <nav className="mt-4">
            <React.Suspense fallback={<NoteListSkeleton />}>
              <NoteList searchText />
            </React.Suspense>
          </nav>
          <Hr />
          <Counter initial=3 />
        </section>
        <section key="note-viewer" className="flex-1 basis-3/4">
          <React.Suspense fallback={<NoteSkeleton isEditing />}>
            <NoteItem selectedId isEditing />
          </React.Suspense>
        </section>
      </div>
    </DemoLayout>;
  };
};

let handler = request => {
  let selectedId =
    Dream.query(request, "selectedId")
    |> Option.map(string => int_of_string_opt(string))
    |> Option.value(~default=None);
  let isEditing =
    Dream.query(request, "isEditing")
    |> Option.map(v => v == "true")
    |> Option.value(~default=false);
  let searchText =
    Dream.query(request, "searchText") |> Option.value(~default="");
  DreamRSC.createFromRequest(
    <App selectedId isEditing searchText />,
    "/static/demo/client/router.js",
    request,
  );
};
