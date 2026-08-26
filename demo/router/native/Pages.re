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
  let make = (~children) =>
    <html suppressHydrationWarning=true className="h-full" lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta
          name="description"
          content="Native React server rendering and router demos built with server-reason-react."
        />
        <title> {React.string("server-reason-react router demos")} </title>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
        />
        <link rel="stylesheet" href="/output.css" />
        <script
          dangerouslySetInnerHTML={
            "__html": "try{var t=localStorage.getItem('hn-theme');document.documentElement.dataset.hnTheme=t||(matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light')}catch(e){}document.addEventListener('click',function(e){var b=e.target.closest&&e.target.closest('#hn-theme-toggle');if(!b)return;var r=document.documentElement,n=r.dataset.hnTheme==='dark'?'light':'dark';r.dataset.hnTheme=n;try{localStorage.setItem('hn-theme',n)}catch(e){}})",
          }
        />
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
  let status = _ => Router.Status.InternalServerError;

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
