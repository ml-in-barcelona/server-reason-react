Router.make ~basePath:"/app" [ Router.route Asset ~page:AssetPage ~path:"/:parts<string...>/raw" ]
