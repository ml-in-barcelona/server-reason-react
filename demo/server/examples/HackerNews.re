let feedTitle = feed =>
  switch (feed) {
  | HackerNewsApi.Top => "Top stories"
  | New => "New stories"
  | Best => "Best stories today"
  | Ask => "Ask HN"
  | Show => "Show HN"
  | Jobs => "Jobs"
  };

let timeAgo = timestamp => {
  let seconds = Int.max(0, int_of_float(Unix.time() -. timestamp));
  if (seconds < 60) {
    "just now";
  } else if (seconds < 3600) {
    let minutes = seconds / 60;
    Int.to_string(minutes) ++ (minutes == 1 ? " minute ago" : " minutes ago");
  } else if (seconds < 86400) {
    let hours = seconds / 3600;
    Int.to_string(hours) ++ (hours == 1 ? " hour ago" : " hours ago");
  } else {
    let days = seconds / 86400;
    Int.to_string(days) ++ (days == 1 ? " day ago" : " days ago");
  };
};

let domain = url =>
  url
  |> Uri.of_string
  |> Uri.host
  |> Option.map(host =>
       String.starts_with(~prefix="www.", host)
         ? String.sub(host, 4, String.length(host) - 4) : host
     );

let basePath = Routes.hackerNews;

let feedPath = feed =>
  switch (feed) {
  | HackerNewsApi.Top => basePath
  | New => basePath ++ "/new"
  | Best => basePath ++ "/best"
  | Ask => basePath ++ "/ask"
  | Show => basePath ++ "/show"
  | Jobs => basePath ++ "/jobs"
  };

let storyPath = id => basePath ++ "/item/" ++ Int.to_string(id);

module Header = {
  [@react.component]
  let make = (~active: option(HackerNewsApi.feed), ~text) => {
    let searchAction =
      switch (active) {
      | Some(feed) => feedPath(feed)
      | None => basePath
      };
    <header className="hn-header">
      <div className="hn-header-inner">
        <a className="hn-brand" href=basePath>
          <span className="hn-brand-mark" ariaHidden=true>
            {React.string("Y")}
          </span>
          <span className="hn-brand-label">
            {React.string("Hacker News")}
          </span>
        </a>
        <nav className="hn-nav" ariaLabel="Hacker News feeds">
          <a
            href={feedPath(Top)}
            className="hn-nav-link"
            ariaCurrent={active == Some(Top) ? "page" : "false"}>
            {React.string("Top")}
          </a>
          <a
            href={feedPath(New)}
            className="hn-nav-link"
            ariaCurrent={active == Some(New) ? "page" : "false"}>
            {React.string("New")}
          </a>
          <a
            href={feedPath(Best)}
            className="hn-nav-link"
            ariaCurrent={active == Some(Best) ? "page" : "false"}>
            {React.string("Best")}
          </a>
          <a
            href={feedPath(Ask)}
            className="hn-nav-link"
            ariaCurrent={active == Some(Ask) ? "page" : "false"}>
            {React.string("Ask")}
          </a>
          <a
            href={feedPath(Show)}
            className="hn-nav-link"
            ariaCurrent={active == Some(Show) ? "page" : "false"}>
            {React.string("Show")}
          </a>
          <a
            href={feedPath(Jobs)}
            className="hn-nav-link"
            ariaCurrent={active == Some(Jobs) ? "page" : "false"}>
            {React.string("Jobs")}
          </a>
        </nav>
        <div className="hn-tools">
          <form
            className="hn-search"
            role="search"
            method_="get"
            action={`String(searchAction)}>
            <label className="sr-only" htmlFor="hn-search-input">
              {React.string("Search Hacker News")}
            </label>
            <span className="hn-search-icon" ariaHidden=true>
              {React.string("⌕")}
            </span>
            <input
              id="hn-search-input"
              name="text"
              type_="search"
              placeholder="Search stories"
              defaultValue={text |> Option.value(~default="")}
            />
          </form>
          <button
            id="hn-theme-toggle"
            type_="button"
            className="hn-theme-toggle"
            ariaLabel="Toggle color theme">
            <span className="hn-theme-light" ariaHidden=true>
              {React.string("☾")}
            </span>
            <span className="hn-theme-dark" ariaHidden=true>
              {React.string("☀")}
            </span>
          </button>
        </div>
      </div>
    </header>;
  };
};

module Shell = {
  [@react.component]
  let make = (~active, ~text, ~children) =>
    <div className="hn-app">
      <Header active text />
      <main id="router-focus-root" tabIndex=(-1) className="hn-main">
        children
      </main>
    </div>;
};

module StoryRow = {
  [@react.component]
  let make = (~rank, ~story: HackerNewsApi.story) => {
    let title =
      switch (story.url) {
      | Some(url) =>
        <a
          className="hn-story-title" href=url target="_blank" rel="noreferrer">
          {React.string(story.title)}
          {switch (domain(url)) {
           | Some(domain) =>
             <span className="hn-domain">
               {React.string("(" ++ domain ++ ")")}
             </span>
           | None => React.null
           }}
        </a>
      | None =>
        <a href={storyPath(story.id)} className="hn-story-title">
          {React.string(story.title)}
        </a>
      };

    <li className="hn-story-row">
      <span className="hn-rank"> {React.int(rank)} </span>
      <div>
        title
        <div className="hn-story-meta">
          <span>
            {React.string(Int.to_string(story.points) ++ " points")}
          </span>
          <span>
            {React.string(
               "by " ++ story.author ++ " " ++ timeAgo(story.createdAt),
             )}
          </span>
          <a href={storyPath(story.id)} className="hn-meta-link">
            {React.string(
               Int.to_string(story.comments)
               ++ (story.comments == 1 ? " comment" : " comments"),
             )}
          </a>
        </div>
      </div>
    </li>;
  };
};

module Feed = {
  [@react.component]
  let make =
      (~feed, ~text, ~stories: result(list(HackerNewsApi.story), string)) => {
    <Shell active={Some(feed)} text>
      <div className="hn-feed-heading">
        <h1>
          {React.string(
             switch (text) {
             | Some(query) => "Search results for “" ++ query ++ "”"
             | None => feedTitle(feed)
             },
           )}
        </h1>
        <p> {React.string("Live data from the Hacker News Algolia API")} </p>
      </div>
      {switch (stories) {
       | Error(error) =>
         <div className="hn-state" role="alert">
           {React.string("Could not load Hacker News: " ++ error)}
         </div>
       | Ok([]) =>
         <div className="hn-state"> {React.string("No stories found.")} </div>
       | Ok(stories) =>
         <ol className="hn-story-list">
           {stories
            |> List.mapi((index, story: HackerNewsApi.story) =>
                 <StoryRow
                   key={Int.to_string(story.id)}
                   rank={index + 1}
                   story
                 />
               )
            |> Array.of_list
            |> React.array}
         </ol>
       }}
    </Shell>;
  };
};

let rec renderComment = (comment: HackerNewsApi.comment) =>
  <li key={Int.to_string(comment.id)} className="hn-comment">
    <div className="hn-comment-meta">
      {React.string(comment.author ++ " · " ++ timeAgo(comment.createdAt))}
    </div>
    <p className="hn-comment-body"> {React.string(comment.text)} </p>
    {switch (comment.children) {
     | [] => React.null
     | children =>
       <ul className="hn-comment-children">
         {children |> List.map(renderComment) |> Array.of_list |> React.array}
       </ul>
     }}
  </li>;

let rec countComment = (comment: HackerNewsApi.comment) =>
  1
  + List.fold_left(
      (total, child) => total + countComment(child),
      0,
      comment.children,
    );

let countComments = comments =>
  List.fold_left(
    (total, comment) => total + countComment(comment),
    0,
    comments,
  );

module Comment = {
  [@react.component]
  let make = (~comment: HackerNewsApi.comment) => renderComment(comment);
};

module Story = {
  [@react.component]
  let make =
      (
        ~id as _,
        ~text,
        ~storyResult: result(HackerNewsApi.storyPage, string),
      ) => {
    <Shell active=None text>
      {switch (storyResult) {
       | Error(error) =>
         <div className="hn-state" role="alert">
           {React.string("Could not load this story: " ++ error)}
         </div>
       | Ok({ story, comments }) =>
         <article className="hn-story-page">
           <a href=basePath className="hn-back-link">
             {React.string("← Back to stories")}
           </a>
           <header className="hn-story-summary">
             <h1>
               {switch (story.url) {
                | Some(url) =>
                  <a
                    className="hn-story-title"
                    href=url
                    target="_blank"
                    rel="noreferrer">
                    {React.string(story.title)}
                  </a>
                | None => React.string(story.title)
                }}
             </h1>
             <div className="hn-story-meta">
               <span>
                 {React.string(Int.to_string(story.points) ++ " points")}
               </span>
               <span>
                 {React.string(
                    "by " ++ story.author ++ " " ++ timeAgo(story.createdAt),
                  )}
               </span>
               <span>
                 {React.string(
                    Int.to_string(countComments(comments))
                    ++ " loaded comments",
                  )}
               </span>
             </div>
             {switch (story.text) {
              | Some(text) when text != "" =>
                <p className="hn-story-text"> {React.string(text)} </p>
              | _ => React.null
              }}
           </header>
           <h2 className="hn-comments-heading">
             {React.string("Discussion")}
           </h2>
           {switch (comments) {
            | [] =>
              <div className="hn-state">
                {React.string("No comments yet.")}
              </div>
            | comments =>
              <ul className="hn-comments">
                {comments
                 |> List.map((comment: HackerNewsApi.comment) =>
                      <Comment key={Int.to_string(comment.id)} comment />
                    )
                 |> Array.of_list
                 |> React.array}
              </ul>
            }}
         </article>
       }}
    </Shell>;
  };
};

module Document = {
  [@react.component]
  let make = (~children) =>
    <html lang="en" className="h-full">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta
          name="description"
          content="A server-rendered Hacker News reader built with server-reason-react."
        />
        <title> {React.string("Hacker News · server-reason-react")} </title>
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
      <body> children </body>
    </html>;
};

let render = page =>
  Dream.html(ReactDOM.renderToString(<Document> page </Document>));

let feedHandler = (feed, request) => {
  let text = Dream.query(request, "text");
  let%lwt stories = HackerNewsApi.fetchFeed(~feed, ~query=text);
  render(<Feed feed text stories />);
};

let topHandler = feedHandler(HackerNewsApi.Top);
let newHandler = feedHandler(HackerNewsApi.New);
let bestHandler = feedHandler(HackerNewsApi.Best);
let askHandler = feedHandler(HackerNewsApi.Ask);
let showHandler = feedHandler(HackerNewsApi.Show);
let jobsHandler = feedHandler(HackerNewsApi.Jobs);

let storyHandler = request => {
  let id = Dream.param(request, "id") |> int_of_string_opt;
  let%lwt storyResult =
    switch (id) {
    | Some(id) => HackerNewsApi.fetchStory(id)
    | None => Lwt_result.fail("Hacker News story id must be a number")
    };
  render(
    <Story id={id |> Option.value(~default=0)} text=None storyResult />,
  );
};
