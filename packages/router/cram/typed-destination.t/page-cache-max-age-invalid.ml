Router.make ~basePath:"/app" ~pageCacheMaxAge:30 [ Router.route Home ~page:HomePage ~path:"/" ]
