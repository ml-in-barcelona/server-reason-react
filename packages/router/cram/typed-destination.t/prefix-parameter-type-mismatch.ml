Router.make ~basePath:"/" [
  Router.route User ~page:Page ~path:"/users/:id<int>";
  Router.route Settings ~page:Page ~path:"/users/:id<string>/settings"
]
