Router.make ~basePath:"/"
  ~search:{ tab = Router.Search.optional ~shallow:true string }
  [
    Router.route Note ~page:Page ~path:"/notes"
      ~search:{ q = Router.Search.optional string; panel = Router.Search.optional ~key:"p" ~shallow:true string };
    Router.route Other ~page:Page ~path:"/other" ~search:{ x = Router.Search.optional ~shallow:false string };
  ]
