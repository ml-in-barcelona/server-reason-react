module App = {
  [@react.component]
  let make = (~text as _) =>
    <div className="flex flex-col h-full items-center justify-center gap-2">
      <Text size=XXLarge> "🥺" </Text>
      <Text> "Click a note on the left to view something!" </Text>
    </div>;
};

module AppLayout = {
  [@react.component]
  let make = (~children, ~text as _) =>
    <DemoLayout background=Theme.Color.Gray2 mode=DemoLayout.FullScreen>
      <div className="flex flex-row gap-8 h-full">
        <section
          className="flex-1 basis-1/4 gap-4 min-w-[400px]" key="sidebar">
          <section
            className="flex flex-col gap-1 z-1 max-w-[85%] pointer-events-none mb-6"
            key="sidebar-header">
            <Text size=Large weight=Bold> "server-reason-react notes" </Text>
            <p>
              <Text color=Theme.Color.Gray10> "migrated from " </Text>
              <Link.Text
                size=Text.Small
                href="https://github.com/reactjs/server-components-demo">
                "reactjs/server-components-demo"
              </Link.Text>
              <Text color=Theme.Color.Gray10>
                " with (server)-reason-react and Melange"
              </Text>
            </p>
          </section>
          <nav className="flex flex-row gap-2" key="e2e-links">
            <Router.E2e className="layout-e2e">
              {React.string("Checks")}
            </Router.E2e>
            <Router.E2eLong className="layout-long">
              {React.string("Long page")}
            </Router.E2eLong>
          </nav>
          <section className="mt-4 mb-4 flex flex-row gap-2" key="search">
            <SearchField />
          </section>
          <nav className="mt-4">
            <div className="mb-4"> <Hr /> </div>
            <div className="mb-4">
              <CreateNoteButton>
                {React.string("Create a note")}
              </CreateNoteButton>
            </div>
            <Hr />
            <React.Suspense fallback={<NoteListSkeleton />}>
              <NoteList />
            </React.Suspense>
          </nav>
        </section>
        <main
          id="router-focus-root"
          tabIndex=(-1)
          key="note-viewer"
          className="flex-1 basis-3/4 max-w-[75%] h-full">
          children
        </main>
      </div>
    </DemoLayout>;
};

module Document = {
  [@react.component]
  let make = (~head, ~children) =>
    <html suppressHydrationWarning=true className="h-full" lang="en">
      <head>
        <meta charSet="utf-8" />
        <title> {React.string("server-reason-react notes")} </title>
        <link rel="stylesheet" href="/output.css" />
        head
      </head>
      <body suppressHydrationWarning=true className="h-full"> children </body>
    </html>;
};

module GlobalLoading = {
  [@react.component]
  let make = (~text as _) =>
    <div className="flex items-center justify-center h-full">
      <Text> "Loading..." </Text>
    </div>;
};

module AppError = {
  [@react.component]
  let make = (~text as _, ~error as _) =>
    <div className="flex flex-col h-full items-center justify-center gap-2">
      <Text size=XXLarge> "⚠️" </Text>
      <Text> "The requested note could not be loaded." </Text>
    </div>;
};

module NotFound = {
  [@react.component]
  let make = (~text as _, ~error as _) =>
    <div className="flex flex-col h-full items-center justify-center gap-2">
      <Text size=XXLarge> "😵‍💫" </Text>
      <Text> "No route matches this location." </Text>
    </div>;
};

module NewNoteLoading = {
  [@react.component]
  let make = (~text as _) => <NoteSkeleton isEditing=true />;
};

module NoteLoading = {
  [@react.component]
  let make = (~id as _, ~text as _, ~note as _) =>
    <NoteSkeleton isEditing=false />;
};

module EditNoteLoading = {
  [@react.component]
  let make = (~id as _, ~text as _, ~note as _) =>
    <NoteSkeleton isEditing=true />;
};

module NoteLoader = {
  let load = (~id, ~text as _, ()) =>
    DB.fetchNoteOption(id)
    |> Lwt.map(result =>
         switch (result) {
         | Ok(Some(note)) => Router.Loader.Data(note)
         | Ok(None) => Router.Loader.NotFound
         | Error(error) => Router.Loader.Error(error)
         }
       );
};

module NoteLayout = {
  [@react.component]
  let make = (~id as _, ~text as _, ~note as _, ~children) => children;
};

module NewNote = {
  [@react.component]
  let make = (~text as _) =>
    <NoteEditor id=None initialTitle="Untitled" initialBody="" />;
};

module Note = {
  [@react.component]
  let make = (~id as _, ~text as _, ~note) =>
    <NoteItem note isEditing=false />;
};

module EditNote = {
  [@react.component]
  let make = (~id as _, ~text as _, ~note) =>
    <NoteItem note isEditing=true />;
};

module E2e = {
  [@react.component]
  let make = (~text as _) =>
    <div className="flex flex-col gap-4 p-4" id="e2e-page">
      <h1> {React.string("Router checks")} </h1>
      <a id="plain-route" href="/demo/router/e2e/long">
        {React.string("Plain anchor to a route")}
      </a>
      <a id="plain-off" href="/demo/router/e2e/off">
        {React.string("Plain anchor to a route that refuses prefetch")}
      </a>
      <a id="plain-missing-note" href="/demo/router/999">
        {React.string("Plain anchor to a note that does not exist")}
      </a>
      <a id="plain-missing" href="/demo/router/e2e/missing.txt">
        {React.string("Plain anchor to a URL without a route")}
      </a>
      <Router.E2eOff className="link-off">
        {React.string("Prefetch off")}
      </Router.E2eOff>
      <Router.E2eLong className="link-long">
        {React.string("Long page")}
      </Router.E2eLong>
      <Router.E2e className="link-self">
        {React.string("This page")}
      </Router.E2e>
      <form id="visit-form" action={`Function(E2eActions.countVisit)}>
        <span id="visits">
          {React.string(string_of_int(E2eState.visits^))}
        </span>
        <button id="count-visit" type_="submit">
          {React.string("Count a visit")}
        </button>
      </form>
      <E2eTools />
      <div style={ReactDOM.Style.make(~height="2400px", ())} />
      <Router.E2eViewport className="link-viewport">
        {React.string("Viewport prefetch")}
      </Router.E2eViewport>
      <h2 id="section"> {React.string("Section")} </h2>
      <div style={ReactDOM.Style.make(~height="1200px", ())} />
    </div>;
};

module E2eLong = {
  [@react.component]
  let make = (~text as _) =>
    <div className="p-4" id="e2e-long">
      <h1> {React.string("Long page")} </h1>
      <Router.E2e className="long-back">
        {React.string("Checks")}
      </Router.E2e>
      <div style={ReactDOM.Style.make(~height="4000px", ())} />
      <p id="long-end"> {React.string("End")} </p>
    </div>;
};

module E2eOff = {
  [@react.component]
  let make = (~text as _) =>
    <p id="e2e-off"> {React.string("A route that is never prefetched")} </p>;
};

module E2eViewport = {
  [@react.component]
  let make = (~text as _) =>
    <p id="e2e-viewport">
      {React.string("A route prefetched near the viewport")}
    </p>;
};
