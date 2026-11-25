Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/notes" ~search:{ type = Router.Search.optional string } ]
