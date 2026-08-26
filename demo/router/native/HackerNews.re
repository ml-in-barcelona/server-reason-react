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

module Header = {
  [@react.component]
  let make = (~active: option(HackerNewsApi.feed), ~text) => {
    let searchAction =
      switch (active) {
      | Some(HackerNewsApi.New) => Router.HackerNewsNew.href()
      | Some(Best) => Router.HackerNewsBest.href()
      | Some(Ask) => Router.HackerNewsAsk.href()
      | Some(Show) => Router.HackerNewsShow.href()
      | Some(Jobs) => Router.HackerNewsJobs.href()
      | Some(Top)
      | None => Router.HackerNewsTop.href()
      };
    <header className="hn-header">
      <div className="hn-header-inner">
        <Router.HackerNewsTop className="hn-brand">
          <span className="hn-brand-mark" ariaHidden=true>
            {React.string("Y")}
          </span>
          <span className="hn-brand-label">
            {React.string("Hacker News")}
          </span>
        </Router.HackerNewsTop>
        <nav className="hn-nav" ariaLabel="Hacker News feeds">
          <Router.HackerNewsTop
            className="hn-nav-link"
            ariaCurrent={active == Some(Top) ? "page" : "false"}>
            {React.string("Top")}
          </Router.HackerNewsTop>
          <Router.HackerNewsNew
            className="hn-nav-link"
            ariaCurrent={active == Some(New) ? "page" : "false"}>
            {React.string("New")}
          </Router.HackerNewsNew>
          <Router.HackerNewsBest
            className="hn-nav-link"
            ariaCurrent={active == Some(Best) ? "page" : "false"}>
            {React.string("Best")}
          </Router.HackerNewsBest>
          <Router.HackerNewsAsk
            className="hn-nav-link"
            ariaCurrent={active == Some(Ask) ? "page" : "false"}>
            {React.string("Ask")}
          </Router.HackerNewsAsk>
          <Router.HackerNewsShow
            className="hn-nav-link"
            ariaCurrent={active == Some(Show) ? "page" : "false"}>
            {React.string("Show")}
          </Router.HackerNewsShow>
          <Router.HackerNewsJobs
            className="hn-nav-link"
            ariaCurrent={active == Some(Jobs) ? "page" : "false"}>
            {React.string("Jobs")}
          </Router.HackerNewsJobs>
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
        <Router.HackerNewsStory id={story.id} className="hn-story-title">
          {React.string(story.title)}
        </Router.HackerNewsStory>
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
          <Router.HackerNewsStory id={story.id} className="hn-meta-link">
            {React.string(
               Int.to_string(story.comments)
               ++ (story.comments == 1 ? " comment" : " comments"),
             )}
          </Router.HackerNewsStory>
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
  |> Lwt.map(result => Router.Loader.Data(result));

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
           <Router.HackerNewsTop className="hn-back-link">
             {React.string("← Back to stories")}
           </Router.HackerNewsTop>
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

module StoryLoader = {
  let load = (~id, ~text as _, ()) =>
    HackerNewsApi.fetchStory(id)
    |> Lwt.map(result => Router.Loader.Data(result));
};

module Skeleton = {
  [@react.component]
  let make = () =>
    <div className="hn-app">
      <Header active=None text=None />
      <main className="hn-main">
        <div
          className="hn-story-list hn-state" ariaLabel="Loading Hacker News">
          {Array.init(8, index =>
             <div key={Int.to_string(index)} className="hn-skeleton-line" />
           )
           |> React.array}
        </div>
      </main>
    </div>;
};

module FeedLoading = {
  [@react.component]
  let make = (~text as _, ~stories as _) => <Skeleton />;
};

module StoryLoading = {
  [@react.component]
  let make = (~id as _, ~text as _, ~storyResult as _) => <Skeleton />;
};
