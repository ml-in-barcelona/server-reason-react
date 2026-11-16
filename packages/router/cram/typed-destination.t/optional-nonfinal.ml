Router.make ~basePath:"/" [ Router.route Docs ~page:Page ~path:"/docs/:rest?<string...>/raw" ]
