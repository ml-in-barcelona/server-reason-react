Router.make ~basePath:"/"
  ~search:{ revalidate = Router.Search.optional string; updateSearch = Router.Search.optional string }
  [
    Router.route Note ~page:NotePage ~path:"/notes/:id<int>" ~search:{ id = Router.Search.optional string };
    Router.route Inspector ~page:InspectorPage ~path:"/inspector"
      ~search:
        {
          target = Router.Search.required string;
          error = Router.Search.optional string;
          input = Router.Search.default string "all";
          hash = Router.Search.many string;
          value = Router.Search.default int 0;
          pattern = Router.Search.optional string;
        };
    Router.redirect ~path:"/old" ~search:{ item = Router.Search.optional string }
      ~target:(fun ~search () ->
        Router.Inspector.destination
          ~search:(Router.Inspector.search ~target:(Option.value search.item ~default:"none") ())
          ());
  ]
