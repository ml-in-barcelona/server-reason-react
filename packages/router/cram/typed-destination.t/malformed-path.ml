Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/foo:id<int>" ]
