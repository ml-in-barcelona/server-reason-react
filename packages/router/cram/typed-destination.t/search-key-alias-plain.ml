Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/note" ~search:{ target = Router.Search.optional string } ]
