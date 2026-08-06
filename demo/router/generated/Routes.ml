Router.make ~basePath:"/demo/router" ~layout:RouterPages.AppLayout.make ~loading:RouterPages.GlobalLoading.make
  ~notFound:RouterPages.NotFound.make ~error:RouterPages.AppError
  ~search:{ searchText = Router.Search.optional string }
  [
    Router.route Home ~page:RouterPages.App.make ~path:"/";
    Router.route NewNote ~page:RouterPages.NewNote.make ~path:"/new" ~loading:RouterPages.NewNoteLoading.make;
    Router.group ~path:"/:id<NoteId.t>" ~layout:RouterPages.NoteLayout.make ~loader:RouterPages.NoteLoader.load
      ~loaderAs_:note
      [
        Router.route Note ~page:RouterPages.Note.make ~path:"/" ~loading:RouterPages.NoteLoading.make;
        Router.route EditNote ~page:RouterPages.EditNote.make ~path:"/edit" ~loading:RouterPages.EditNoteLoading.make;
      ];
  ]
