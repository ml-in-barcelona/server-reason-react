Router.make ~basePath:"/app" [ Router.route Home ~page:HomePage ~path:"/" ~prefetch:Eager ]
