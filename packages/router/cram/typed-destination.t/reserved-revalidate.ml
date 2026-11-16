Router.make ~basePath:"/" ~search:{ revalidate = Router.Search.optional string } [
  Router.route Note ~page:Page ~path:"/note"
]
