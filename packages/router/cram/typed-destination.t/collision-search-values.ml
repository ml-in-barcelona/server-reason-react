Router.make ~basePath:"/"
  [ Router.route Note ~page:NotePage ~path:"/n/:searchValues<int>" ~search:{ q = Router.Search.optional string } ]
