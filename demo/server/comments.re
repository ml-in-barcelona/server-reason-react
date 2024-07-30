module Spinner = {
  let make = () => {
    <div
      role="progressbar"
      ariaBusy=true
      style={ReactDOM.Style.make(
        ~display="inline-block",
        ~transition="opacity linear 0.1s",
        ~width="20px",
        ~height="20px",
        ~border="3px solid rgba(80, 80, 80, 0.5)",
        ~borderRadius="50%",
        ~borderTopColor="#fff",
        ~animation="spin 1s ease-in-out infinite",
        (),
      )}
    />;
  };
};

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
  let delay = 1.0;

  let fakeData = [
    "Wait, it doesn't wait for React to load?",
    "How does this even work?",
    "I like marshmallows",
    "!1!1!1! This is a comment",
    "This is actually static from the server",
    "But, imagine it's dynamic",
  ];

  let cached = ref(false);
  let destroy = () => cached := false;

  let promise = () => {
    cached.contents
      ? Lwt.return(fakeData)
      : {
        cached.contents = true;
        let%lwt () = Lwt_unix.sleep(delay);
        Lwt.return(fakeData);
      };
  };

  let get = () => fakeData;
};

module Comments = {
  let make = () => {
    /* Sincronous data: let comments = Data.get(); */
    let comments = React.Experimental.use(Data.promise());

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
    </div>;
  };
};

[@react.component]
let make = () => {
  <Layout background=Theme.Color.black>
    <main
      className={Theme.text(Theme.Color.white)}
      style={ReactDOM.Style.make(~display="flex", ~marginTop="16px", ())}>
      <React.Suspense fallback={<Spinner />}>
        <article className="flex gap-4 flex-col">
          <h1
            className={Cx.make([
              "text-4xl font-bold ",
              Theme.text(Theme.Color.white),
            ])}>
            {React.string("Hello world")}
          </h1>
          <Post />
          <section>
            <h3
              className={Cx.make([
                "text-2xl font-bold mb-4",
                Theme.text(Theme.Color.white),
              ])}>
              {React.string("Comments")}
            </h3>
            <React.Suspense fallback={<Spinner />}>
              <Comments />
            </React.Suspense>
          </section>
          <h2> {React.string("Thanks for reading!")} </h2>
        </article>
      </React.Suspense>
    </main>
  </Layout>;
};
