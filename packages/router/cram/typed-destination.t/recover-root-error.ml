Router.make ~basePath:"/" ~search:{ page = Router.Search.default int 1 } ~error:AppError [
  Router.route Note ~page:Page.make ~path:"/note"
]
