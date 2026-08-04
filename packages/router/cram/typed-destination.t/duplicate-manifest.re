Router.make(
  ~basePath="/app",
  [Router.route(NotePage.make, ~as_=Note, ~path="/notes/:id<NoteId.t>")],
);

Router.make(
  ~basePath="/other",
  [Router.route(NotePage.make, ~as_=Other, ~path="/notes/:id<NoteId.t>")],
);
