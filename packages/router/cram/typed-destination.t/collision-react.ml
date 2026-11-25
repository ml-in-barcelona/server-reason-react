Router.make ~basePath:"/"
  [ Router.route React ~page:ReactPage ~path:"/react"; Router.route Note ~page:NotePage ~path:"/n" ]
