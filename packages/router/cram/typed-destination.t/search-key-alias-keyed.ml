Router.make ~basePath:"/"
  [ Router.route Note ~page:Page ~path:"/note" ~search:{ target = Router.Search.optional ~key:"site" string } ]
