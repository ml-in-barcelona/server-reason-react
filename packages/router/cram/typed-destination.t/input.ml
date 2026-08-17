Router.make ~basePath:"/app" [ Router.route Note ~page:NotePage ~path:"/notes/:id<NoteId.t>" ]
