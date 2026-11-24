Router.make ~basePath:"/" [ Router.route Note ~page:NotePage ~path:"/n/:tryDestination<int>" ]
