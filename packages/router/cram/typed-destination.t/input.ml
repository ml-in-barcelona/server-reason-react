Router.make ~basePath:"/app" [ Router.route Note ~page:NotePage.make ~path:"/notes/:id<NoteId.t>" ]
