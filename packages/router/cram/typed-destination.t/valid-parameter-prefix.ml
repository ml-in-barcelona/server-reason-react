Router.make ~basePath:"/" [
  Router.route User ~page:Page ~path:"/users/:id<string>";
  Router.route Settings ~page:Page ~path:"/users/:id<string>/settings"
]
