Router.make ~basePath:"/" [ Router.redirect ~path:"/old" ~to_:(Note.destination ()) ]
