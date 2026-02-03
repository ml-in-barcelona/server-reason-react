let markdownStyles = (~background, ~text) => {
  Printf.sprintf(
    {|
.markdown h1 {
  font-size: 2.25rem;
  font-weight: bold;
  line-height: 2.5;
}

.markdown h2 {
  font-size: 1.875rem;
  font-weight: bold;
  line-height: 2.5;
}

.markdown h3 {
  font-size: 1.5rem;
  font-weight: bold;
  line-height: 2.5;
}

.markdown h4 {
  font-size: 1.25rem;
  font-weight: bold;
  line-height: 2.5;
}

.markdown h5 {
  font-size: 1.125rem;
  font-weight: bold;
  line-height: 2.5;
}

.markdown h6 {
  font-size: 1rem;
  font-weight: bold;
  line-height: 2.5;
}

.markdown p {
  font-size: 1rem;
  margin-bottom: 1rem;
}

.markdown ul, .markdown ol {
  padding-left: 2rem;
  margin-bottom: 1rem;
}

.markdown li {
  margin-bottom: 0.5rem;
}

.markdown blockquote {
  border-left: 4px solid %s;
  padding-left: 1rem;
  margin: 1.5rem 0;
  font-style: italic;
}

.markdown pre {
  padding: 1rem;
  margin: 1.5rem 0;
  background-color: %s;
  color: %s;
  border-radius: 0.375rem;
}

.markdown code {
  display: block;
  margin: 1rem;
  padding-left: 1rem;
  padding-right: 1rem;
  font-family: monospace;
  background-color: %s;
  color: %s;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
}
|},
    background,
    background,
    text,
    background,
    text,
  );
};

module App = {
  [@react.component]
  let make = (~query as _) => {
    <div className="flex flex-col h-full items-center justify-center gap-2">
      <Text size=XXLarge> "🥺" </Text>
      <Text> "Click a note on the left to view something!" </Text>
    </div>;
  };
};

module AppLayout = {
  [@react.component]
  let make = (~children) => {
    <DemoLayout background=Theme.Color.Gray2 mode=FullScreen>
      <div className="flex flex-row gap-8">
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
          <section
            className="mt-4 mb-4 flex flex-row gap-2"
            role="menubar"
            key="menubar">
            <NestedRouter_SearchField />
          </section>
          <nav className="mt-4">
            <div className="mb-4"> <Hr /> </div>
            <div className="mb-4">
              <NestedRouter_CreateNoteButton>
                {React.string("Create a note")}
              </NestedRouter_CreateNoteButton>
            </div>
            <Hr />
            <React.Suspense fallback={<NoteListSkeleton />}>
              <NestedRouter_NoteList />
            </React.Suspense>
          </nav>
        </section>
        <section key="note-viewer" className="flex-1 basis-3/4 max-w-[75%]">
          children
        </section>
      </div>
    </DemoLayout>;
  };
};

module Document = {
  [@react.component]
  let make = (~children) =>
    <html suppressHydrationWarning=true>
      <head>
        <meta charSet="utf-8" />
        <style
          dangerouslySetInnerHTML={
            "__html":
              markdownStyles(
                ~background=Theme.Color.gray2,
                ~text=Theme.Color.gray12,
              ),
          }
        />
        <link rel="stylesheet" href="/output.css" />
      </head>
      <body suppressHydrationWarning=true> children </body>
    </html>;
};

module GlobalLoading = {
  [@react.component]
  let make = () => {
    <div className="flex items-center justify-center h-full">
      <Text> "Loading..." </Text>
    </div>;
  };
};

module NotFound = {
  [@react.component]
  let make = (~path) => {
    <div className="flex flex-col h-full items-center justify-center gap-2">
      <Text size=XXLarge> "😵‍💫" </Text>
      <Text> {"No route matches " ++ path} </Text>
    </div>;
  };
};

module NoteLoading = {
  [@react.component]
  let make = () => <NoteSkeleton isEditing=false />;
};

module NoteEditLoading = {
  [@react.component]
  let make = () => <NoteSkeleton isEditing=true />;
};

module PassThroughLayout = {
  [@react.component]
  let make = (~children, ~params as _) => children;
};

module NewNotePage = {
  [@react.component]
  let make = (~params as _, ~query as _) => {
    <React.Suspense fallback={<NoteSkeleton isEditing=true />}>
      <NestedRouter_NoteItem selectedId=None isEditing=true />
    </React.Suspense>;
  };
};

module NotePage = {
  [@react.component]
  let make = (~params, ~query as _) => {
    let selectedId =
      DynamicParams.find("id", params) |> Option.map(int_of_string);
    let isEditing = false;
    <React.Suspense fallback={<NoteSkeleton isEditing />}>
      <NestedRouter_NoteItem selectedId isEditing />
    </React.Suspense>;
  };
};

module EditNotePage = {
  [@react.component]
  let make = (~params, ~query as _) => {
    let selectedId =
      DynamicParams.find("id", params) |> Option.map(int_of_string);
    let isEditing = true;
    <React.Suspense fallback={<NoteSkeleton isEditing />}>
      <NestedRouter_NoteItem selectedId isEditing />
    </React.Suspense>;
  };
};

/* <Link href=RoutesRegistry.lola> */

let routeDefinitions: RouterRSC.t =
  RouterRSC.make(
    ~layout=(module AppLayout),
    ~page=(module App),
    ~notFound=(module NotFound),
    ~loading=(module GlobalLoading),
    [
      RouterRSC.route(
        ~path="/new",
        ~page=(module NewNotePage),
        ~loading=(module NoteEditLoading),
        [],
        (),
      ),
      RouterRSC.route(
        ~path="/:id",
        ~layout=(module PassThroughLayout),
        ~page=(module NotePage),
        ~loading=(module NoteLoading),
        [
          RouterRSC.route(
            ~path="/edit",
            ~page=(module EditNotePage),
            ~loading=(module NoteEditLoading),
            [],
            (),
          ),
        ],
        (),
      ),
    ],
  );
