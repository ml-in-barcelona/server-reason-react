Router.make(
  ~basePath="/app",
  ~laoyut=NotePage.make,
  [Router.route(NotePage.make, ~as_=Note, ~path="/notes/:id<NoteId.t>")],
);
