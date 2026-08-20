Router.make ~basePath:"/"
  [
    Router.route Left ~page:LeftPage ~path:"/foo/:left<string...>";
    Router.route Right ~page:RightPage ~path:"/:scope<string>/bar/:right<string...>";
  ]
