Router.make(
  ~basePath="/app",
  [Router.route(NotePage.make, ~as_=Note, ~path="/notes/:id<NoteId.t>")],
);
