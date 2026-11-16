Router.make ~basePath:"/app" [ Router.redirect ~path:"/old" ~target:(Home.destination ()) ~prefetch:Off ]
