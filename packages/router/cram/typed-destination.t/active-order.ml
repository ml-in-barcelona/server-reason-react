Router.make ~basePath:"/" [
  Router.route Leaf ~page:Page ~path:"/parent/leaf";
  Router.route Other ~page:Page ~path:"/other";
  Router.route Parent ~page:Page ~path:"/parent"
]
