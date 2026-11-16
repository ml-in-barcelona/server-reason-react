Router.make ~basePath:"/" [ Router.route Pair ~page:Page ~path:"/docs/:a?<string>/:b?<string>" ]
