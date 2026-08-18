Router.make ~basePath:"/" [
  Router.route ById ~page:Page ~path:"/notes/:id<string>";
  Router.route BySlug ~page:Page ~path:"/notes/:slug<string>"
]
