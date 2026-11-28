Router.make ~basePath:"/" [ Router.route Note ~page:Page ~path:"/notes/:note<int>" ~loader:NoteLoader ~loaderLabel:note ]
