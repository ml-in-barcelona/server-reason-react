Router.make ~basePath:"/app"
  [
    Router.route Docs ~page:DocsPage ~path:"/docs/:rest?<string...>";
    Router.route Help ~page:HelpPage ~path:"/help/:lang?<string>";
    Router.route HelpTopic ~page:HelpTopicPage ~path:"/help/:lang?<string>/topics/:topic<int>";
  ]
