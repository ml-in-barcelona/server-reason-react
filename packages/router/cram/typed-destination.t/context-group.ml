Router.make ~basePath:"/"
  [ Router.group ~path:"/notes" ~context:Session.t [ Router.route Note ~page:Page ~path:"/" ] ]
