Router.make ~basePath:"/demo/router" ~viewTransitions:true ~layout:Pages.AppLayout ~loading:Pages.GlobalLoading
  ~notFound:Pages.NotFound ~error:Pages.AppError
  ~search:{ text = Router.Search.optional string }
  [
    Router.route Home ~page:Pages.App ~path:"/";
    Router.route NewNote ~page:Pages.NewNote ~path:"/new" ~loading:Pages.NewNoteLoading;
    Router.route E2e ~page:Pages.E2e ~path:"/e2e";
    Router.route E2eLong ~page:Pages.E2eLong ~path:"/e2e/long";
    Router.route E2eOff ~page:Pages.E2eOff ~path:"/e2e/off" ~prefetch:Off;
    Router.route E2eViewport ~page:Pages.E2eViewport ~path:"/e2e/viewport" ~prefetch:Viewport;
    Router.redirect ~path:"/e2e/old" ~target:(fun ~search () -> Router.E2eLong.destination ~search ());
    Router.group ~path:"/:id<NoteId.t>" ~layout:Pages.NoteLayout ~loader:Pages.NoteLoader ~loaderLabel:note
      [
        Router.route Note ~page:Pages.Note ~path:"/" ~loading:Pages.NoteLoading;
        Router.route EditNote ~page:Pages.EditNote ~path:"/edit" ~loading:Pages.EditNoteLoading;
      ];
  ]
