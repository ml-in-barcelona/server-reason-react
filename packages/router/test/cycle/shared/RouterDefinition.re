Router.make(
  ~basePath="/fixture",
  ~search={
    page: Router.Search.default(int, 1),
    searchText: Router.Search.optional(string),
  },
  ~layout=Attachments.RootLayout,
  ~loading=Attachments.RootLoading,
  ~metadata=Attachments.RootMetadata.make,
  ~headers=Attachments.RootHeaders.make,
  ~error=Attachments.AppError,
  ~invalidSearch=Attachments.InvalidSearch,
  ~notFound=Attachments.RootNotFound,
  [
    Router.route(Workspaces, ~page=WorkspacesPage, ~path="/workspaces"),
    Router.group(
      ~path="/workspaces/:workspaceId<WorkspaceId.t>",
      ~search={ filter: Router.Search.optional(Filter.t) },
      ~loader=WorkspaceLoader,
      ~loaderAs_=workspace,
      ~layout=Attachments.WorkspaceLayout,
      ~metadata=Attachments.WorkspaceMetadata.make,
      ~headers=Attachments.WorkspaceHeaders.make,
      ~error=Attachments.WorkspaceBoundary,
      ~notFound=Attachments.WorkspaceNotFound,
      [
        Router.route(
          Note,
          ~page=NotePage,
          ~path="/notes/:id<NoteId.t>",
          ~loader=NoteLoader,
          ~loaderAs_=noteAccess,
          ~metadata=Attachments.NoteMetadata.make,
          ~headers=Attachments.NoteHeaders.make,
        ),
        Router.route(
          EditNote,
          ~page=NotePage,
          ~path="/notes/:id<NoteId.t>/edit",
          ~loader=NoteLoader,
          ~loaderAs_=noteAccess,
          ~metadata=Attachments.NoteMetadata.make,
          ~headers=Attachments.NoteHeaders.make,
        ),
        Router.route(
          SearchResults,
          ~page=SearchPage,
          ~path="/search",
          ~search={ view: Router.Search.optional(NoteId.t) },
        ),
      ],
    ),
    Router.group(
      ~path="/teams/:teamId<WorkspaceId.t>",
      ~layout=Attachments.TeamLayout,
      ~error=Attachments.TeamBoundary,
      ~notFound=Attachments.TeamNotFound,
      [
        Router.route(Team, ~page=TeamPage, ~path="/"),
        Router.route(
          TeamMember,
          ~page=TeamMemberPage,
          ~path="/members",
          ~loader=MemberLoader,
          ~loaderAs_=member,
        ),
      ],
    ),
    Router.route(Asset, ~page=AssetPage, ~path="/assets/:parts<string...>"),
    Router.route(
      Scalar,
      ~page=ScalarPage,
      ~path="/scalar/:scalarId<ScalarId.t>",
    ),
    Router.redirect(
      ~path="/legacy/:workspaceId<WorkspaceId.t>/notes/:id<NoteId.t>",
      ~to_=(~workspaceId, ~id, ~page, ~searchText, ()) =>
      Router.Note.destination(~workspaceId, ~id, ~page, ~searchText?, ())
    ),
  ],
);
