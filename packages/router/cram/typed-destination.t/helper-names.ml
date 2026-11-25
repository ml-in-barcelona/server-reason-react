Router.make ~basePath:"/"
  [
    Router.route Note ~page:Page ~path:"/n/:pattern<string>/:input<string>/:destination<string>/:searchValues<int>"
      ~search:{ q = Router.Search.optional string };
    Router.route Link ~page:Page ~path:"/link/:tryDestination<int>/:value<int>";
  ]
