Router.make ~basePath:"/" ~search:{ q = Router.Search.optional string }
  [
    Router.route Home ~page:HomePage ~path:"/";
    Router.route Results ~page:ResultsPage ~path:"/results" ~search:{ page = Router.Search.default int 1 };
  ]
