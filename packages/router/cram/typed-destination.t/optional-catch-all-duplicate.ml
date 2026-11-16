Router.make ~basePath:"/" [
  Router.route Index ~page:Page ~path:"/docs";
  Router.route Docs ~page:Page ~path:"/docs/:rest?<string...>"
]
