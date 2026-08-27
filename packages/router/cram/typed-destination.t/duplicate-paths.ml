Router.make ~basePath:"/" [
  Router.route First ~page:Page ~path:"/notes";
  Router.route Second ~page:Page ~path:"/notes"
]
