Router.make ~basePath:"/"
  [ Router.route Fun ~page:FunPage ~path:"/fun"; Router.route Note ~page:NotePage ~path:"/n/:id<string>" ]
