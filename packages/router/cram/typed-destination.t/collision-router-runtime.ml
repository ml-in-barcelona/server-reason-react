Router.make ~basePath:"/"
  [ Router.route RouterRuntime ~page:RuntimePage ~path:"/runtime"; Router.route Note ~page:NotePage ~path:"/n" ]
