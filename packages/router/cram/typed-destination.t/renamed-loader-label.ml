Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/note" ~loader:NoteLoader ~loaderAs_:note ]
