Router.make ~basePath:"/" ~search:{ infoPage = Router.Search.optional ~key:"info-page" string }
  [
    Router.route Inspector ~page:InspectorPage ~path:"/inspector"
      ~search:
        {
          siteTarget = Router.Search.optional ~key:"target" string;
          target = Router.Search.default ~key:"site" string "all";
          kind = Router.Search.required ~key:"type" string;
          tags = Router.Search.many ~key:"tag" int;
        };
    Router.redirect ~path:"/old" ~search:{ oldTarget = Router.Search.optional ~key:"target" string }
      ~target:(fun ~search () ->
        Router.Inspector.destination
          ~search:(Router.Inspector.search ~kind:(Option.value search.oldTarget ~default:"none") ())
          ());
  ]
