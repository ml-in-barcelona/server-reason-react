Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/notes" ~search:{ hash = Router.Search.optional string } ]
