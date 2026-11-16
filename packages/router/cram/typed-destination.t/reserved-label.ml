Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/:history<string>" ]
