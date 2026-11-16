Router.make ~basePath:"/" [
  Router.route Plain ~page:Page ~path:"/x";
  Router.route Prefixed ~page:Page ~path:"/:a?<string>/x"
]
