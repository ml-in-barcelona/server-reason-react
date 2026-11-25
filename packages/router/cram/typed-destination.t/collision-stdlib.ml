Router.make ~basePath:"/"
  [ Router.route Stdlib ~page:StdlibPage ~path:"/stdlib"; Router.route Note ~page:NotePage ~path:"/n/:id<int>" ]
