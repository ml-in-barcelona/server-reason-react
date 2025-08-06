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
  [@react.async.component]
  let make = (~selectedId, ~isEditing, ~searchText) => {
    Lwt.return(
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
              <SearchField searchText selectedId isEditing />
            </section>
            <nav className="mt-4">
              <div className="mb-4"> <Hr /> </div>
              <div className="mb-4">
                <Button noteId=None> {React.string("Create a note")} </Button>
              </div>
              <Hr />
              <React.Suspense fallback={<NoteListSkeleton />}>
                <NoteList searchText />
              </React.Suspense>
            </nav>
          </section>
          <section key="note-viewer" className="flex-1 basis-3/4 max-w-[75%]">
            <React.Suspense fallback={<NoteSkeleton isEditing />}>
              <NoteItem selectedId isEditing />
            </React.Suspense>
          </section>
        </div>
      </DemoLayout>,
    );
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
    ~bootstrapModules=["/static/demo/RouterRSC.re.js"],
    ~layout=
      children =>
        <html lang="en">
          <head>
            <meta charSet="utf-8" />
            <link rel="stylesheet" href="/output.css" />
            <style
              dangerouslySetInnerHTML={
                "__html":
                  markdownStyles(
                    ~background=Theme.Color.gray2,
                    ~text=Theme.Color.gray12,
                  ),
              }
            />
          </head>
          <body> children </body>
        </html>,
    <App selectedId isEditing searchText />,
    request,
  );
};
