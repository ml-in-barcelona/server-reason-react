Router.make ~basePath:"/app"
  [ Router.group ~path:"/assets/:parts<string...>" [ Router.route Asset ~page:AssetPage ~path:"/raw" ] ]
