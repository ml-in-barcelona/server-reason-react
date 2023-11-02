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

module Sidebar = {
  let make = () => {
    <aside>
      <h3> {React.string("Archive")} </h3>
      <ul>
        <li> {React.string("May 2021")} </li>
        <li> {React.string("April 2021")} </li>
        <li> {React.string("March 2021")} </li>
        <li> {React.string("February 2021")} </li>
        <li> {React.string("January 2021")} </li>
        <li> {React.string("December 2020")} </li>
        <li> {React.string("November 2020")} </li>
        <li> {React.string("October 2020")} </li>
        <li> {React.string("September 2020")} </li>
      </ul>
    </aside>;
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

    <>
      {comments
       |> List.mapi((i, comment) =>
            <p
              key={Int.to_string(i)}
              style={ReactDOM.Style.make(
                ~border="2px solid #facedd",
                ~borderRadius="4px",
                ~padding="8px 8px",
                ~margin="2px",
                (),
              )}>
              {React.string(comment)}
            </p>
          )
       |> React.list}
    </>;
  };
};

module Layout = {
  [@react.component]
  let make = (~children) => {
    <div style={ReactDOM.Style.make(~padding="20px", ~height="100%", ())}>
      children
    </div>;
  };
};

module App = {
  let make = () => {
    <Layout>
      <nav> <a href="/"> {React.string("Home")} </a> </nav>
      <main
        style={ReactDOM.Style.make(~display="flex", ~marginTop="16px", ())}>
        <aside
          className="sidebar"
          style={ReactDOM.Style.make(~marginRight="16px", ())}>
          <Sidebar />
        </aside>
        <React.Suspense fallback={<Spinner />}>
          <article className="post">
            <h1> {React.string("Hello world")} </h1>
            <Post />
            <section className="comments">
              <h3> {React.string("Comments")} </h3>
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
};
