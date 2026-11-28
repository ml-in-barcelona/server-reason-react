Router.make ~basePath:"/"
  [
    Router.group ~path:"/notes" ~loader:ListLoader ~loaderLabel:data
      [ Router.route Note ~page:Page ~path:"/:id<int>" ~loader:NoteLoader ~loaderLabel:data ];
  ]
