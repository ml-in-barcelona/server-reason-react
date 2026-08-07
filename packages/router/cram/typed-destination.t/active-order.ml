Router.make ~basePath:"/" [
  Router.route Leaf ~page:Page.make ~path:"/parent/leaf";
  Router.route Other ~page:Page.make ~path:"/other";
  Router.route Parent ~page:Page.make ~path:"/parent"
]
