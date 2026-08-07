Router.make ~basePath:"/app" ~laoyut:NotePage.make
  [ Router.route Note ~page:NotePage.make ~path:"/notes/:id<NoteId.t>" ]
