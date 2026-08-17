Router.make ~basePath:"/demo/router" ~layout:Pages.AppLayout ~loading:Pages.GlobalLoading ~notFound:Pages.NotFound
  ~error:Pages.AppError
  ~search:{ text = Router.Search.optional string }
  [
    Router.route Home ~page:Pages.App ~path:"/";
    Router.route NewNote ~page:Pages.NewNote ~path:"/new" ~loading:Pages.NewNoteLoading;
    Router.group ~path:"/:id<NoteId.t>" ~layout:Pages.NoteLayout ~loader:Pages.NoteLoader ~loaderAs_:note
      [
        Router.route Note ~page:Pages.Note ~path:"/" ~loading:Pages.NoteLoading;
        Router.route EditNote ~page:Pages.EditNote ~path:"/edit" ~loading:Pages.EditNoteLoading;
      ];
  ]
