Router.make(
  ~basePath="/site",
  ~error=Pages.AppError,
  ~interceptLinks=false,
  ~viewTransitions=true,
  ~pageCacheMaxAge=30.0,
  ~context=string,
  [
    Router.route(Docs, ~page=Pages.Docs, ~path="/docs/:rest?<string...>"),
    Router.route(
      DocsTopic,
      ~page=Pages.DocsTopic,
      ~path="/docs/:topic<string>",
    ),
    Router.route(
      DocsApi,
      ~page=Pages.DocsApi,
      ~path="/docs/api/:name<string>",
    ),
    Router.route(
      Account,
      ~page=Pages.Account,
      ~path="/account",
      ~loader=Pages.AccountLoader,
      ~metadata=Pages.AccountMetadata.make,
      ~headers=Pages.AccountHeaders.make,
    ),
    Router.route(Help, ~page=Pages.Help, ~path="/help/:lang?<string>"),
    Router.route(
      HelpTopic,
      ~page=Pages.HelpTopic,
      ~path="/help/:lang?<string>/topics/:topic<int>",
    ),
    Router.group(
      ~path="/settings",
      ~prefetch=Viewport,
      ~error=Pages.SettingsError,
      [
        Router.route(Settings, ~page=Pages.Settings, ~path="/"),
        Router.route(
          SettingsBilling,
          ~page=Pages.SettingsBilling,
          ~path="/billing",
          ~prefetch=Off,
        ),
        Router.group(
          ~path="/team",
          [
            Router.route(
              SettingsTeam,
              ~page=Pages.SettingsTeam,
              ~path="/",
              ~prefetch=Idle,
            ),
            Router.route(
              SettingsMembers,
              ~page=Pages.SettingsMembers,
              ~path="/members",
            ),
          ],
        ),
      ],
    ),
    Router.group(
      ~path="/reports/:reportId<string>",
      ~loader=Pages.ReportLoader,
      ~error=Pages.ReportError,
      [
        Router.route(
          Report,
          ~page=Pages.Report,
          ~path="/",
          ~loader=Pages.ReportStatsLoader,
          ~loaderParallel=true,
        ),
      ],
    ),
    Router.route(
      Note,
      ~page=Pages.Note,
      ~path="/notes/:id<int>",
      ~search={ tab: Router.Search.optional(string) },
    ),
    Router.route(
      Inspector,
      ~page=Pages.Inspector,
      ~path="/inspector",
      ~search={
        target: Router.Search.required(string),
        error: Router.Search.optional(string),
        input: Router.Search.default(string, "all"),
        hash: Router.Search.many(string),
        value: Router.Search.optional(int),
        pattern: Router.Search.optional(string),
      },
    ),
    Router.route(
      Support,
      ~page=Pages.Support,
      ~path="/support",
      ~search={
        infoPage: Router.Search.optional(~key="info-page", string),
        resourcesProjectId:
          Router.Search.default(~key="resources-projectId", int, 0),
        alpha: Router.Search.optional(~key="z", ~shallow=true, string),
        zone: Router.Search.many(~key="a-zone", string),
      },
    ),
    Router.redirect(
      ~path="/old-inspector",
      ~search={ site: Router.Search.optional(string) },
      ~target=(~search, ()) =>
      Router.Inspector.destination(
        ~search=
          Router.Inspector.search(
            ~target=Option.value(search.site, ~default="none"),
            (),
          ),
        (),
      )
    ),
  ],
);
