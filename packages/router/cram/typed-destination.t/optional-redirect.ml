Router.make ~basePath:"/"
  [ Router.redirect ~path:"/old/:rest?<string...>" ~target:(fun ~rest:_ () -> Router.unsafeDestination "/") ]
