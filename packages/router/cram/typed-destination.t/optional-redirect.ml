Router.make ~basePath:"/"
  [ Router.redirect ~path:"/old/:rest?<string...>" ~to_:(fun ~rest:_ () -> Router.unsafeDestination "/") ]
