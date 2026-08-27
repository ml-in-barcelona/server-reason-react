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

module Layout = {
  [@react.component]
  let make = (~text as _, ~children) =>
    <div className="hn-app">
      <HackerNewsHeader />
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
  let make = (~stories: result(list(HackerNewsApi.story), string)) => {
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
  let make = (~feed, ~text, ~stories) =>
    <>
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
      <FeedData stories />
    </>;
};

module Top = {
  [@react.component]
  let make = (~text, ~stories) =>
    <Feed feed=HackerNewsApi.Top text stories />;
};

module New = {
  [@react.component]
  let make = (~text, ~stories) =>
    <Feed feed=HackerNewsApi.New text stories />;
};

module Best = {
  [@react.component]
  let make = (~text, ~stories) =>
    <Feed feed=HackerNewsApi.Best text stories />;
};

module Ask = {
  [@react.component]
  let make = (~text, ~stories) =>
    <Feed feed=HackerNewsApi.Ask text stories />;
};

module Show = {
  [@react.component]
  let make = (~text, ~stories) =>
    <Feed feed=HackerNewsApi.Show text stories />;
};

module Jobs = {
  [@react.component]
  let make = (~text, ~stories) =>
    <Feed feed=HackerNewsApi.Jobs text stories />;
};

let loadFeed = (feed, ~text, ()) =>
  HackerNewsApi.fetchFeed(~feed, ~query=text)
  |> Lwt.map(stories => Router.Loader.Data(stories));

module TopLoader = {
  let load = loadFeed(HackerNewsApi.Top);
};

module NewLoader = {
  let load = loadFeed(HackerNewsApi.New);
};

module BestLoader = {
  let load = loadFeed(HackerNewsApi.Best);
};

module AskLoader = {
  let load = loadFeed(HackerNewsApi.Ask);
};

module ShowLoader = {
  let load = loadFeed(HackerNewsApi.Show);
};

module JobsLoader = {
  let load = loadFeed(HackerNewsApi.Jobs);
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

module Comment = {
  [@react.component]
  let make = (~comment: HackerNewsApi.comment) => renderComment(comment);
};

module CommentsData = {
  [@react.component]
  let make = (~commentsResult: result(list(HackerNewsApi.comment), string)) =>
    switch (commentsResult) {
    | Error(error) =>
      <div className="hn-state" role="alert">
        {React.string("Could not load comments: " ++ error)}
      </div>
    | Ok([]) =>
      <div className="hn-state"> {React.string("No comments yet.")} </div>
    | Ok(comments) =>
      <ul className="hn-comments">
        {comments
         |> List.map((comment: HackerNewsApi.comment) =>
              <Comment key={Int.to_string(comment.id)} comment />
            )
         |> Array.of_list
         |> React.array}
      </ul>
    };
};

module StoryData = {
  [@react.component]
  let make =
      (
        ~storyResult: result(HackerNewsApi.story, string),
        ~comments: Js.Promise.t(React.element),
      ) => {
    switch (storyResult) {
    | Error(error) =>
      <div className="hn-state" role="alert">
        {React.string("Could not load this story: " ++ error)}
      </div>
    | Ok(story) =>
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
                 Int.to_string(story.comments)
                 ++ (story.comments == 1 ? " comment" : " comments"),
               )}
            </span>
          </div>
          {switch (story.text) {
           | Some(text) when text != "" =>
             <p className="hn-story-text"> {React.string(text)} </p>
           | _ => React.null
           }}
        </header>
        <HackerNewsComments content=comments />
      </article>
    };
  };
};

module Story = {
  [@react.component]
  let make = (~id, ~text as _, ~storyResult) => {
    let comments =
      HackerNewsApi.fetchComments(id)
      |> Lwt.map(commentsResult => <CommentsData commentsResult />);
    <StoryData storyResult comments />;
  };
};

module StoryLoader = {
  let load = (~id, ~text as _, ()) =>
    HackerNewsApi.fetchStory(id)
    |> Lwt.map(storyResult => Router.Loader.Data(storyResult));
};

module FeedLoading = {
  [@react.component]
  let make = (~text as _, ~stories as _) =>
    <Loading label="Loading stories" />;
};

module StoryLoading = {
  [@react.component]
  let make = (~id as _, ~text as _, ~storyResult as _) =>
    <Loading label="Loading story" />;
};

module GlobalLoading = {
  [@react.component]
  let make = (~text as _) => <Loading label="Loading Hacker News" />;
};

module AppError = {
  let status = (_error: string) => Router.Status.InternalServerError;

  [@react.component]
  let make = (~text as _, ~error: Router.Error.t(string)) =>
    <div className="hn-state" role="alert">
      {React.string("Hacker News could not be loaded.")}
    </div>;
};

module NotFound = {
  [@react.component]
  let make = (~text as _, ~error as _) =>
    <div className="hn-state">
      {React.string("This page does not exist.")}
    </div>;
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
            "__html": "try{var t=localStorage.getItem('hn-theme');document.documentElement.dataset.hnTheme=t||(matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light')}catch(e){}",
          }
        />
      </head>
      <body suppressHydrationWarning=true> children </body>
    </html>;
};
