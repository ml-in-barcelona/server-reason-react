Router.make ~basePath:"/app" [ Router.redirect ~path:"/old" ~to_:(Home.destination ()) ~prefetch:Off ]
