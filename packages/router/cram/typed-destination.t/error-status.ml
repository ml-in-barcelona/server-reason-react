Router.make ~basePath:"/" ~error:AppBoundary ~errorStatus:AppError.status [ Router.route Note ~page:Page ~path:"/note" ]
