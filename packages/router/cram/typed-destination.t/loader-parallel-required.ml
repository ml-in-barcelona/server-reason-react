Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/note" ~loaderParallel:true ]
