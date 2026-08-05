Router.make(
  ~basePath="/app",
  [Router.route(Note, ~page=NotePage.make, ~path="/notes/:id<NoteId.t>")],
);

Router.make(
  ~basePath="/other",
  [Router.route(Other, ~page=NotePage.make, ~path="/notes/:id<NoteId.t>")],
);
