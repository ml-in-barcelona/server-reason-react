Router.make ~basePath:"/demo/router" ~layout:Pages.AppLayout.make ~loading:Pages.GlobalLoading.make
  ~notFound:Pages.NotFound.make ~error:Pages.AppError
  ~search:{ searchText = Router.Search.optional string }
  [
    Router.route Home ~page:Pages.App.make ~path:"/";
    Router.route NewNote ~page:Pages.NewNote.make ~path:"/new" ~loading:Pages.NewNoteLoading.make;
    Router.group ~path:"/:id<NoteId.t>" ~layout:Pages.NoteLayout.make ~loader:Pages.NoteLoader.load ~loaderAs_:note
      [
        Router.route Note ~page:Pages.Note.make ~path:"/" ~loading:Pages.NoteLoading.make;
        Router.route EditNote ~page:Pages.EditNote.make ~path:"/edit" ~loading:Pages.EditNoteLoading.make;
      ];
  ]
