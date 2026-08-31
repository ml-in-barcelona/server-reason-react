Router.make ~basePath:"/demo/hacker-news" ~layout:Pages.Layout ~loading:Pages.GlobalLoading ~notFound:Pages.NotFound
  ~error:Pages.AppError
  ~search:{ text = Router.Search.optional string }
  [
    Router.route Top ~page:Pages.Top ~path:"/" ~loader:Pages.TopLoader ~loaderAs_:stories ~loading:Pages.FeedLoading;
    Router.route New ~page:Pages.New ~path:"/new" ~loader:Pages.NewLoader ~loaderAs_:stories ~loading:Pages.FeedLoading;
    Router.route Best ~page:Pages.Best ~path:"/best" ~loader:Pages.BestLoader ~loaderAs_:stories
      ~loading:Pages.FeedLoading;
    Router.route Ask ~page:Pages.Ask ~path:"/ask" ~loader:Pages.AskLoader ~loaderAs_:stories ~loading:Pages.FeedLoading;
    Router.route Show ~page:Pages.Show ~path:"/show" ~loader:Pages.ShowLoader ~loaderAs_:stories
      ~loading:Pages.FeedLoading;
    Router.route Jobs ~page:Pages.Jobs ~path:"/jobs" ~loader:Pages.JobsLoader ~loaderAs_:stories
      ~loading:Pages.FeedLoading;
    Router.route Story ~page:Pages.Story ~path:"/item/:id<int>" ~loader:Pages.StoryLoader ~loaderAs_:storyResult
      ~loading:Pages.StoryLoading;
  ]
