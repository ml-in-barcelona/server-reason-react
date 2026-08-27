Router.make ~basePath:"/app" ~trailingSlash:Reject [ Router.route Note ~page:NotePage ~path:"/notes" ]
