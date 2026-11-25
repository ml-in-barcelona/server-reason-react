Router.make ~basePath:"/"
  [ Router.route Page ~page:PagePage ~path:"/p/:max_int<int>" ~search:{ limit = Router.Search.default int max_int } ]
