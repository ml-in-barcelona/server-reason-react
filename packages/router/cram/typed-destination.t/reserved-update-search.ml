Router.make ~basePath:"/" ~search:{ updateSearch = Router.Search.optional string } [
  Router.route Note ~page:Page ~path:"/note"
]
