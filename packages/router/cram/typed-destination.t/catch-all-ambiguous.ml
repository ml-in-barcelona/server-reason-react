Router.make ~basePath:"/app"
  [
    Router.route Left ~page:LeftPage ~path:"/assets/:a<string...>";
    Router.route Right ~page:RightPage ~path:"/assets/:b<string...>";
  ]
