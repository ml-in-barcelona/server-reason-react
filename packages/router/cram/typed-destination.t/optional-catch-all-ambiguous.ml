Router.make ~basePath:"/" [
  Router.route Required ~page:Page ~path:"/assets/:a<string...>";
  Router.route Optional ~page:Page ~path:"/assets/:b?<string...>"
]
