Router.make ~basePath:"/base"
  [
    Router.route Scalars ~page:Pages.Scalars ~path:"/s/:i<int>/:s<string>/:b<bool>/:c<Code.t>";
    Router.route Optional ~page:Pages.Optional ~path:"/o/:i?<int>/x/y/:s?<string>";
    Router.route Rest ~page:Pages.Rest ~path:"/r/:parts<string...>";
    Router.route Loaded ~page:Pages.Loaded ~path:"/l" ~loader:Pages.L ~loaderLabel:data;
    Router.route OptRest ~page:Pages.OptRest ~path:"/q/:lead<int>/:rest?<string...>";
  ]
