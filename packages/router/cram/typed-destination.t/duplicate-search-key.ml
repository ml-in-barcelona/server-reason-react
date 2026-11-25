Router.make ~basePath:"/"
  [
    Router.route Note ~page:Page ~path:"/notes"
      ~search:{ siteTarget = Router.Search.optional ~key:"target" string; target = Router.Search.optional string };
  ]
