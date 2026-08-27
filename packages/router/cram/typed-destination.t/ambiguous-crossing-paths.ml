Router.make ~basePath:"/" [
  Router.route Left ~page:Page ~path:"/foo/:id<string>";
  Router.route Right ~page:Page ~path:"/:slug<string>/bar"
]
