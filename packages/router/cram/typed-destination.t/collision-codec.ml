Router.make ~basePath:"/"
  [ Router.route NoteId ~page:NoteIdPage ~path:"/ids"; Router.route Note ~page:NotePage ~path:"/n/:id<NoteId.t>" ]
