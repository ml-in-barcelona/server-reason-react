Router.make ~basePath:"/app" ~interceptLinks:false ~viewTransitions:true [ Router.route Home ~page:HomePage ~path:"/" ]
