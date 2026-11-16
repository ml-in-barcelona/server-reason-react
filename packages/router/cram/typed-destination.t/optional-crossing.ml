Router.make ~basePath:"/" [
  Router.route Left ~page:Page ~path:"/:a?<string>/x";
  Router.route Right ~page:Page ~path:"/x/:b<string>"
]
