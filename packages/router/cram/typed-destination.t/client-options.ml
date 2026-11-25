Router.make ~basePath:"/app" ~interceptLinks:false ~viewTransitions:true ~pageCacheMaxAge:30.0 [ Router.route Home ~page:HomePage ~path:"/" ]
