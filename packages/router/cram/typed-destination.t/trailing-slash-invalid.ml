Router.make ~basePath:"/app" ~trailingSlash:Sometimes [ Router.route Note ~page:NotePage ~path:"/notes" ]
