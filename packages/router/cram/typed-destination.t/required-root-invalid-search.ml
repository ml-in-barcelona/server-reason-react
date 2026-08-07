Router.make ~basePath:"/" ~search:{ page = Router.Search.required int } ~error:AppError
  ~invalidSearch:InvalidSearch.make [ Router.route Home ~page:Page.make ~path:"/" ]
