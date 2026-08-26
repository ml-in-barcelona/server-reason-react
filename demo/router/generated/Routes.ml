Router.make ~basePath:"/demo/router" ~loading:Pages.GlobalLoading ~notFound:Pages.NotFound ~error:Pages.AppError
  ~search:{ text = Router.Search.optional string }
  [
    Router.group ~path:"/" ~layout:Pages.AppLayout
      [
        Router.route Home ~page:Pages.App ~path:"/";
        Router.route NewNote ~page:Pages.NewNote ~path:"/new" ~loading:Pages.NewNoteLoading;
        Router.group ~path:"/:id<NoteId.t>" ~layout:Pages.NoteLayout ~loader:Pages.NoteLoader ~loaderAs_:note
          [
            Router.route Note ~page:Pages.Note ~path:"/" ~loading:Pages.NoteLoading;
            Router.route EditNote ~page:Pages.EditNote ~path:"/edit" ~loading:Pages.EditNoteLoading;
          ];
      ];
    Router.route HackerNewsTop ~page:HackerNews.Top ~path:"/hacker-news" ~loader:HackerNews.TopLoader ~loaderAs_:stories
      ~loading:HackerNews.FeedLoading;
    Router.route HackerNewsNew ~page:HackerNews.New ~path:"/hacker-news/new" ~loader:HackerNews.NewLoader
      ~loaderAs_:stories ~loading:HackerNews.FeedLoading;
    Router.route HackerNewsBest ~page:HackerNews.Best ~path:"/hacker-news/best" ~loader:HackerNews.BestLoader
      ~loaderAs_:stories ~loading:HackerNews.FeedLoading;
    Router.route HackerNewsAsk ~page:HackerNews.Ask ~path:"/hacker-news/ask" ~loader:HackerNews.AskLoader
      ~loaderAs_:stories ~loading:HackerNews.FeedLoading;
    Router.route HackerNewsShow ~page:HackerNews.Show ~path:"/hacker-news/show" ~loader:HackerNews.ShowLoader
      ~loaderAs_:stories ~loading:HackerNews.FeedLoading;
    Router.route HackerNewsJobs ~page:HackerNews.Jobs ~path:"/hacker-news/jobs" ~loader:HackerNews.JobsLoader
      ~loaderAs_:stories ~loading:HackerNews.FeedLoading;
    Router.route HackerNewsStory ~page:HackerNews.Story ~path:"/hacker-news/item/:id<int>"
      ~loader:HackerNews.StoryLoader ~loaderAs_:storyResult ~loading:HackerNews.StoryLoading;
  ]
