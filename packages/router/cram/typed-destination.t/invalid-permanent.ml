Router.make ~basePath:"/" [ Router.redirect ~path:"/old" ~to_:(fun () -> Router.Note.destination ()) ~permanent:"yes" ]
