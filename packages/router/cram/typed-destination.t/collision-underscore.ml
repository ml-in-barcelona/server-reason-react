Router.make ~basePath:"/" [ Router.route Note ~page:NotePage ~path:"/n/:_<int>" ]
