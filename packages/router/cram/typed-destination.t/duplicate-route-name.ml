Router.make ~basePath:"/" [ Router.route Member ~page:Page ~path:"/a"; Router.route Member ~page:Page ~path:"/b" ]
