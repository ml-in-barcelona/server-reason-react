Router.make ~basePath:"/demo/hacker-news" ~loading:Pages.GlobalLoading ~notFound:Pages.NotFound ~error:Pages.AppError
  ~search:{ text = Router.Search.optional string }
  [
    Router.route Top ~page:Pages.Top ~path:"/";
    Router.route New ~page:Pages.New ~path:"/new";
    Router.route Best ~page:Pages.Best ~path:"/best";
    Router.route Ask ~page:Pages.Ask ~path:"/ask";
    Router.route Show ~page:Pages.Show ~path:"/show";
    Router.route Jobs ~page:Pages.Jobs ~path:"/jobs";
    Router.route Story ~page:Pages.Story ~path:"/item/:id<int>";
  ]
