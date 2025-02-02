module Post = {
  let make = () => {
    <section>
      <p>
        {React.string(
           "Notice how HTML for comments 'streams in' before the JavaScript (or React) has loaded on the page. In fact, the demo is entirely rendered in the server and doesn't use client-side JavaScript at all",
         )}
      </p>
      <p>
        {React.string("This demo is ")}
        <b> {React.string("artificially slowed down")} </b>
        {React.string(" while loading the comments data.")}
      </p>
    </section>;
  };
};

module Data = {
  let delay = 4.0;

  let fakeData = [
    "Wait, it doesn't wait for React to load?",
    "How does this even work?",
    "I like marshmallows",
    "!1!1!1! This is a comment",
    "This is actually static from the server",
    "But, imagine it's dynamic",
  ];

  let get = () => fakeData;

  let cached = ref(false);
  let destroy = () => cached := false;
  let promise = () => {
    cached.contents
      ? Lwt.return(fakeData)
      : {
        let%lwt () = Lwt_unix.sleep(delay);
        cached.contents = true;
        Lwt.return(fakeData);
      };
  };
};

module Comments = {
  [@react.async.component]
  let make = () => {
    let comments = React.Experimental.use(Data.promise());

    Lwt.return(
      <div className="flex gap-4 flex-col">
        {comments
         |> List.mapi((i, comment) =>
              <p
                key={Int.to_string(i)}
                className="font-semibold border-2 border-yellow-200 rounded-lg p-2 bg-yellow-600 text-slate-900">
                {React.string(comment)}
              </p>
            )
         |> React.list}
      </div>,
    );
  };
};

module Page = {
  [@react.component]
  let make = () => {
    <DemoLayout background=Theme.Color.Gray2>
      <main
        className={Theme.text(Theme.Color.Gray11)}
        style={ReactDOM.Style.make(~display="flex", ~marginTop="16px", ())}>
        <article className="flex gap-4 flex-col">
          <h1
            className={Cx.make([
              "text-4xl font-bold ",
              Theme.text(Theme.Color.Gray11),
            ])}>
            {React.string("Rendering React.Suspense on the server")}
          </h1>
          <Post />
          <section>
            <h3
              className={Cx.make([
                "text-2xl font-bold mb-4",
                Theme.text(Theme.Color.Gray11),
              ])}>
              {React.string("Comments")}
            </h3>
            <React.Suspense fallback={<Spinner active=true />}>
              <Comments />
            </React.Suspense>
          </section>
          <h2> {React.string("Thanks for reading!")} </h2>
        </article>
      </main>
    </DemoLayout>;
  };
};

let handler = _request => {
  Dream.stream(
    ~headers=[("Content-Type", "text/html")],
    response_stream => {
      Data.destroy();

      let pipe = data => {
        let%lwt () = Dream.write(response_stream, data);
        Dream.flush(response_stream);
      };

      let%lwt (stream, _abort) =
        ReactDOM.renderToStream(~pipe, <Document> <Page /> </Document>);

      Lwt_stream.iter_s(pipe, stream);
    },
  );
};
