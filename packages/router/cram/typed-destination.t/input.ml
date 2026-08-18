Router.make ~basePath:"/app"
  [
    Router.route Note ~page:NotePage ~path:"/notes/:id<NoteId.t>";
    Router.route Flag ~page:FlagPage ~path:"/flags/:name<string>/:enabled<bool>";
    Router.route Asset ~page:AssetPage ~path:"/assets/:parts<string...>";
    Router.redirect ~path:"/old-notes/:id<NoteId.t>" ~search:{ legacy = Router.Search.optional string }
      ~to_:(fun ~id ~legacy:_ () -> Router.Note.destination ~id ());
  ]
