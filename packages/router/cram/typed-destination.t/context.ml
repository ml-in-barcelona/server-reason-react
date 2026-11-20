Router.make ~basePath:"/" ~context:Session.t ~metadata:RootMetadata.make
  [
    Router.route Note ~page:Page ~path:"/note/:id<int>" ~loader:NoteLoader ~headers:NoteHeaders.make;
    Router.route About ~page:About ~path:"/about";
    Router.redirect ~path:"/old" ~target:(fun () -> Router.About.destination ());
  ]
