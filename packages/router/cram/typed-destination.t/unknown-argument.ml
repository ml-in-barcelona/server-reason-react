Router.make ~basePath:"/app" ~laoyut:NotePage
  [ Router.route Note ~page:NotePage ~path:"/notes/:id<NoteId.t>" ]
