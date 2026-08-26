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

let cacheFeed = feed =>
  React.cache(text =>
    HackerNewsApi.fetchFeed(~feed, ~query=text == "" ? None : Some(text))
  );

let topFeed = cacheFeed(HackerNewsApi.Top);
let newFeed = cacheFeed(HackerNewsApi.New);
let bestFeed = cacheFeed(HackerNewsApi.Best);
let askFeed = cacheFeed(HackerNewsApi.Ask);
let showFeed = cacheFeed(HackerNewsApi.Show);
let jobsFeed = cacheFeed(HackerNewsApi.Jobs);

let fetchFeed = (feed, text) => {
  let fetch =
    switch (feed) {
    | HackerNewsApi.Top => topFeed
    | New => newFeed
    | Best => bestFeed
    | Ask => askFeed
    | Show => showFeed
    | Jobs => jobsFeed
    };
  fetch(text |> Option.value(~default=""));
};

let fetchStory = React.cache(HackerNewsApi.fetchStory);

module Header = {
  [@react.component]
  let make = (~active: option(HackerNewsApi.feed), ~text) => {
    let searchAction =
      switch (active) {
      | Some(HackerNewsApi.New) => Router.New.href()
      | Some(Best) => Router.Best.href()
      | Some(Ask) => Router.Ask.href()
      | Some(Show) => Router.Show.href()
      | Some(Jobs) => Router.Jobs.href()
      | Some(Top)
      | None => Router.Top.href()
      };
    <header className="hn-header">
      <div className="hn-header-inner">
        <Router.Top className="hn-brand">
          <span className="hn-brand-mark" ariaHidden=true>
            {React.string("Y")}
          </span>
          <span className="hn-brand-label">
            {React.string("Hacker News")}
          </span>
        </Router.Top>
        <nav className="hn-nav" ariaLabel="Hacker News feeds">
          <Router.Top
            className="hn-nav-link"
            ariaCurrent={active == Some(Top) ? "page" : "false"}>
            {React.string("Top")}
          </Router.Top>
          <Router.New
            className="hn-nav-link"
            ariaCurrent={active == Some(New) ? "page" : "false"}>
            {React.string("New")}
          </Router.New>
          <Router.Best
            className="hn-nav-link"
            ariaCurrent={active == Some(Best) ? "page" : "false"}>
            {React.string("Best")}
          </Router.Best>
          <Router.Ask
            className="hn-nav-link"
            ariaCurrent={active == Some(Ask) ? "page" : "false"}>
            {React.string("Ask")}
          </Router.Ask>
          <Router.Show
            className="hn-nav-link"
            ariaCurrent={active == Some(Show) ? "page" : "false"}>
            {React.string("Show")}
          </Router.Show>
          <Router.Jobs
            className="hn-nav-link"
            ariaCurrent={active == Some(Jobs) ? "page" : "false"}>
            {React.string("Jobs")}
          </Router.Jobs>
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
        <Router.Story id={story.id} className="hn-story-title">
          {React.string(story.title)}
        </Router.Story>
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
          <Router.Story id={story.id} className="hn-meta-link">
            {React.string(
               Int.to_string(story.comments)
               ++ (story.comments == 1 ? " comment" : " comments"),
             )}
          </Router.Story>
        </div>
      </div>
    </li>;
  };
};

module Loading = {
  [@react.component]
  let make = (~label) =>
    <div className="hn-state hn-loading">
      <Spinner active=true label />
      <span> {React.string(label)} </span>
    </div>;
};

module FeedData = {
  [@react.component]
  let make = (~feed, ~text) => {
    let stories = React.Experimental.usePromise(fetchFeed(feed, text));
    switch (stories) {
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
    };
  };
};

module Feed = {
  [@react.component]
  let make = (~feed, ~text) =>
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
      <React.Suspense fallback={<Loading label="Loading stories" />}>
        <FeedData feed text />
      </React.Suspense>
    </Shell>;
};

module Top = {
  [@react.component]
  let make = (~text) => <Feed feed=HackerNewsApi.Top text />;
};

module New = {
  [@react.component]
  let make = (~text) => <Feed feed=HackerNewsApi.New text />;
};

module Best = {
  [@react.component]
  let make = (~text) => <Feed feed=HackerNewsApi.Best text />;
};

module Ask = {
  [@react.component]
  let make = (~text) => <Feed feed=HackerNewsApi.Ask text />;
};

module Show = {
  [@react.component]
  let make = (~text) => <Feed feed=HackerNewsApi.Show text />;
};

module Jobs = {
  [@react.component]
  let make = (~text) => <Feed feed=HackerNewsApi.Jobs text />;
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

module StoryData = {
  [@react.component]
  let make = (~id) => {
    let storyResult = React.Experimental.usePromise(fetchStory(id));
    switch (storyResult) {
    | Error(error) =>
      <div className="hn-state" role="alert">
        {React.string("Could not load this story: " ++ error)}
      </div>
    | Ok({ story, comments }) =>
      <article className="hn-story-page">
        <Router.Top className="hn-back-link">
          {React.string("← Back to stories")}
        </Router.Top>
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
                 Int.to_string(countComments(comments)) ++ " loaded comments",
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
    };
  };
};

module Story = {
  [@react.component]
  let make = (~id, ~text) =>
    <Shell active=None text>
      <React.Suspense fallback={<Loading label="Loading discussion" />}>
        <StoryData id />
      </React.Suspense>
    </Shell>;
};

module GlobalLoading = {
  [@react.component]
  let make = (~text) =>
    <Shell active=None text> <Loading label="Loading Hacker News" /> </Shell>;
};

module AppError = {
  let status = (_error: string) => Router.Status.InternalServerError;

  [@react.component]
  let make = (~text, ~error: Router.Error.t(string)) =>
    <Shell active=None text>
      <div className="hn-state" role="alert">
        {React.string("Hacker News could not be loaded.")}
      </div>
    </Shell>;
};

module NotFound = {
  [@react.component]
  let make = (~text, ~error as _) =>
    <Shell active=None text>
      <div className="hn-state">
        {React.string("This page does not exist.")}
      </div>
    </Shell>;
};

module Document = {
  [@react.component]
  let make = (~children) =>
    <html suppressHydrationWarning=true lang="en" className="h-full">
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
      <body suppressHydrationWarning=true> children </body>
    </html>;
};
