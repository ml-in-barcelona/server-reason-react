Router.make ~basePath:"/"
  [ Router.route Note ~page:Page ~path:"/notes" ~search:{ q = Router.Search.optional ~key:"\xff" string } ]
