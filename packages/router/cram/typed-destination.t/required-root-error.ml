Router.make ~basePath:"/" ~search:{ page = Router.Search.required int } ~error:AppError
  [ Router.route Home ~page:Page.make ~path:"/" ]
