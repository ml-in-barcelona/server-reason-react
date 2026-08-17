Router.make ~basePath:"/app" [ Router.route Note ~page:Page ~path:"/note" ~loader:NoteLoader.load ]
