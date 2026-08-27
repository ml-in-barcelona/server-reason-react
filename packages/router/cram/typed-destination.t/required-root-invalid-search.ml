Router.make ~basePath:"/" ~search:{ page = Router.Search.required int } ~error:AppError
  ~invalidSearch:InvalidSearch [ Router.route Home ~page:Page ~path:"/" ]
