Router.make ~basePath:"/" ~error:AppBoundary [ Router.route Note ~page:Page ~path:"/note" ]
