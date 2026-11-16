Router.make ~basePath:"/" [ Router.redirect ~path:"/old" ~target:(fun () -> Router.Note.destination ()) ~permanent:"yes" ]
