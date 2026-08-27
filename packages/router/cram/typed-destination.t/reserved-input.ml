Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/:input<string>" ]
