Router.make ~basePath:"/" ~search:{ page = Router.Search.default int 1 }
  [ Router.route Note ~page:Page ~path:"/notes" ~search:{ page = Router.Search.optional int } ]
