Router.make ~basePath:"/app" [ Router.route Note ~page:NotePage ~path:"/notes/:id<NoteId.t>" ];;

Router.make ~basePath:"/other" [ Router.route Other ~page:NotePage ~path:"/notes/:id<NoteId.t>" ]
