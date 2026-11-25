Router.make ~basePath:"/" ~search:{ infoPage = Router.Search.optional ~key:"info-page" string }
  [ Router.route Note ~page:Page ~path:"/notes" ~search:{ page = Router.Search.default ~key:"info-page" int 1 } ]
