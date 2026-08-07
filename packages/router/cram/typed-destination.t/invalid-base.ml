Router.make ~basePath:"/app?preview" [ Router.route Reports ~page:Page.make ~path:"/reports" ]
