Router.make ~basePath:"/" [
  Router.route Note ~page:Page ~path:"/notes";
  Router.redirect ~path:"/old-notes" ~to_:(fun () -> Router.Note.destination ()) ~permanent:true;
  Router.redirect ~path:"/older-notes" ~to_:(fun () -> Router.Note.destination ())
]
