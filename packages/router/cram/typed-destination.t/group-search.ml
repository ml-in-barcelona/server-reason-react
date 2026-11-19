Router.make ~basePath:"/"
  [
    Router.group ~path:"/workspaces" ~search:{ filter = Router.Search.optional string }
      [ Router.route Workspace ~page:Page ~path:"/" ];
  ]
