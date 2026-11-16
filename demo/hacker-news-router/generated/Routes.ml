Router.make ~basePath:"/demo/hacker-news" ~layout:Pages.Layout ~loading:Pages.GlobalLoading ~notFound:Pages.NotFound
  ~error:Pages.AppError ~errorStatus:Pages.AppError.status
  ~search:{ text = Router.Search.optional string }
  [
    Router.route Top ~page:Pages.Top ~path:"/" ~loader:Pages.TopLoader ~loaderLabel:stories ~loading:Pages.FeedLoading;
    Router.route New ~page:Pages.New ~path:"/new" ~loader:Pages.NewLoader ~loaderLabel:stories
      ~loading:Pages.FeedLoading;
    Router.route Best ~page:Pages.Best ~path:"/best" ~loader:Pages.BestLoader ~loaderLabel:stories
      ~loading:Pages.FeedLoading;
    Router.route Ask ~page:Pages.Ask ~path:"/ask" ~loader:Pages.AskLoader ~loaderLabel:stories
      ~loading:Pages.FeedLoading;
    Router.route Show ~page:Pages.Show ~path:"/show" ~loader:Pages.ShowLoader ~loaderLabel:stories
      ~loading:Pages.FeedLoading;
    Router.route Jobs ~page:Pages.Jobs ~path:"/jobs" ~loader:Pages.JobsLoader ~loaderLabel:stories
      ~loading:Pages.FeedLoading;
    Router.route Story ~page:Pages.Story ~path:"/item/:id<int>" ~loader:Pages.StoryLoader ~loaderLabel:storyResult
      ~loading:Pages.StoryLoading;
  ]
