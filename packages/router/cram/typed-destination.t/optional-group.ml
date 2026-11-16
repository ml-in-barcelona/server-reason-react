Router.make ~basePath:"/"
  [ Router.group ~path:"/:lang?<string>" [ Router.route About ~page:Page ~path:"/about" ] ]
