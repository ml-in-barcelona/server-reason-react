Router.make ~basePath:"/" [ Router.route Member ~page:Page ~path:"/a/:id<int>/b/:id<string>" ]
