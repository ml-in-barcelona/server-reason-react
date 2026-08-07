Router.make ~basePath:"/" [ Router.route Note ~page:Page.make ~path:"/:options<string>" ]
