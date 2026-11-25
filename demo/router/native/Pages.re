module App = {
  [@react.component]
  let make = (~search as _) =>
    <div className="flex flex-col h-full items-center justify-center gap-2">
      <Text size=XXLarge> "🥺" </Text>
      <Text> "Click a note on the left to view something!" </Text>
    </div>;
};

module AppLayout = {
  [@react.component]
  let make = (~children, ~search as _) =>
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
            <RouterReact.Link
              destination={Router.E2e.destination()}
              activeWhen=RouterReact.Subtree
              className="layout-e2e-subtree">
              {React.string("All checks")}
            </RouterReact.Link>
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
  let make = (~search as _) =>
    <div className="flex items-center justify-center h-full">
      <Text> "Loading..." </Text>
    </div>;
};

module AppError = {
  [@react.component]
  let make = (~search as _, ~error as _) =>
    <div className="flex flex-col h-full items-center justify-center gap-2">
      <Text size=XXLarge> "⚠️" </Text>
      <Text> "The requested note could not be loaded." </Text>
    </div>;
};

module NotFound = {
  [@react.component]
  let make = (~search as _, ~error as _) =>
    <div className="flex flex-col h-full items-center justify-center gap-2">
      <Text size=XXLarge> "😵‍💫" </Text>
      <Text> "No route matches this location." </Text>
    </div>;
};

module NewNoteLoading = {
  [@react.component]
  let make = (~search as _) => <NoteSkeleton isEditing=true />;
};

module NoteLoading = {
  [@react.component]
  let make = (~id as _, ~search as _, ~note as _) =>
    <NoteSkeleton isEditing=false />;
};

module EditNoteLoading = {
  [@react.component]
  let make = (~id as _, ~search as _, ~note as _) =>
    <NoteSkeleton isEditing=true />;
};

module NoteLoader = {
  let load = (~id, ~search as _, ()) =>
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
  let make = (~id as _, ~search as _, ~note as _, ~children) => children;
};

module NewNote = {
  [@react.component]
  let make = (~search as _) =>
    <NoteEditor id=None initialTitle="Untitled" initialBody="" />;
};

module Note = {
  [@react.component]
  let make = (~id as _, ~search as _, ~note) =>
    <NoteItem note isEditing=false />;
};

module EditNote = {
  [@react.component]
  let make = (~id as _, ~search as _, ~note) =>
    <NoteItem note isEditing=true />;
};

module E2eCrash = {
  [@react.component]
  let make = (~search as _): React.element =>
    failwith("the e2e page failed to render");
};

module E2e = {
  [@react.component]
  let make = (~search as _) =>
    <div className="flex flex-col gap-4 p-4" id="e2e-page">
      <h1> {React.string("Router checks")} </h1>
      <a id="plain-self" href="/demo/router/e2e">
        {React.string("Plain anchor to this page")}
      </a>
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
      <Router.E2eSlow className="link-slow">
        {React.string("Slow page")}
      </Router.E2eSlow>
      <Router.E2eGroupSlow className="link-group-slow">
        {React.string("Slow page in a group")}
      </Router.E2eGroupSlow>
      <Router.E2eGroupFast className="link-group-fast">
        {React.string("Fast page in a group")}
      </Router.E2eGroupFast>
      <E2ePending />
      <Router.E2eCrash className="link-crash">
        {React.string("A page that fails to render")}
      </Router.E2eCrash>
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
  let make = (~search as _) =>
    <div className="p-4" id="e2e-long">
      <h1> {React.string("Long page")} </h1>
      <Router.E2e className="long-back">
        {React.string("Checks")}
      </Router.E2e>
      <div
        id="long-panel"
        dataRouterScroll="e2e-long-panel"
        style={ReactDOM.Style.make(~height="200px", ~overflow="auto", ())}>
        <div style={ReactDOM.Style.make(~height="2000px", ())} />
      </div>
      <div style={ReactDOM.Style.make(~height="4000px", ())} />
      <p id="long-end"> {React.string("End")} </p>
    </div>;
};

module E2eOff = {
  [@react.component]
  let make = (~search as _) =>
    <p id="e2e-off"> {React.string("A route that is never prefetched")} </p>;
};

module E2eViewport = {
  [@react.component]
  let make = (~search as _) =>
    <p id="e2e-viewport">
      {React.string("A route prefetched near the viewport")}
    </p>;
};

module E2eSlow = {
  [@react.component]
  let make = (~search as _) =>
    <div className="p-4">
      <E2eGate name="slow" />
      <p id="e2e-slow"> {React.string("A slow page")} </p>
    </div>;
};

module E2eSearch = {
  [@react.component]
  let make = (~search: Router.E2eSearch.search) =>
    <div className="flex flex-col gap-2 p-4" id="e2e-search">
      <span id="server-view">
        {React.string(Option.value(search.view, ~default="none"))}
      </span>
      <span id="server-panel">
        {React.string(Option.value(search.panel, ~default="none"))}
      </span>
      <E2eSearchTools />
    </div>;
};

module E2eGroupLayout = {
  [@react.component]
  let make = (~search as _, ~children) =>
    <section id="e2e-group"> children </section>;
};

module E2eGroupSlow = {
  [@react.component]
  let make = (~search as _) =>
    <div>
      <E2eGate name="group-slow" />
      <p id="e2e-slow"> {React.string("A slow page in a group")} </p>
    </div>;
};

module E2eGroupFast = {
  [@react.component]
  let make = (~search as _) =>
    <p id="e2e-group-fast"> {React.string("A fast page in a group")} </p>;
};
