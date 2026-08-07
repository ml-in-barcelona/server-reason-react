Router.make ~basePath:"/" [ Router.route Reports ~page:Page.make ~path:"/bad\255" ]
