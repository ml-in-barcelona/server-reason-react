Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/:destination<string>" ]
