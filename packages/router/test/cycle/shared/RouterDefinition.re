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
  ~errorStatus=Attachments.AppError.status,
  ~invalidSearch=Attachments.InvalidSearch,
  ~notFound=Attachments.RootNotFound,
  [
    Router.route(Workspaces, ~page=WorkspacesPage, ~path="/workspaces"),
    Router.group(
      ~path="/workspaces/:workspaceId<WorkspaceId.t>",
      ~loader=WorkspaceLoader,
      ~loaderLabel=workspace,
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
          ~search={ filter: Router.Search.optional(Filter.t) },
          ~loader=NoteLoader,
          ~loaderLabel=noteAccess,
          ~metadata=Attachments.NoteMetadata.make,
          ~headers=Attachments.NoteHeaders.make,
        ),
        Router.route(
          EditNote,
          ~page=NotePage.Edit,
          ~path="/notes/:id<NoteId.t>/edit",
          ~search={ filter: Router.Search.optional(Filter.t) },
          ~loader=NoteLoader,
          ~loaderLabel=noteAccess,
          ~metadata=Attachments.NoteMetadata.make,
          ~headers=Attachments.NoteHeaders.make,
        ),
        Router.route(
          SearchResults,
          ~page=SearchPage,
          ~path="/search",
          ~search={
            filter: Router.Search.optional(Filter.t),
            view: Router.Search.optional(NoteId.t),
          },
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
          ~loaderLabel=member,
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
      ~target=(~workspaceId, ~id, ~search, ()) =>
      Router.Note.destination(
        ~workspaceId,
        ~id,
        ~search=
          Router.Note.search(
            ~page=search.page,
            ~searchText=?search.searchText,
            (),
          ),
        (),
      )
    ),
  ],
);
