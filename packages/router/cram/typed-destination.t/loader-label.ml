Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/note" ~loader:NoteLoader ~loaderLabel:note ]
