Router.make ~basePath:"/app" ~viewTransitions:"yes" [ Router.route Home ~page:HomePage ~path:"/" ]
