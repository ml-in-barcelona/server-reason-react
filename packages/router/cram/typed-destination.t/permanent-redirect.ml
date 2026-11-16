Router.make ~basePath:"/" [
  Router.route Note ~page:Page ~path:"/notes";
  Router.redirect ~path:"/old-notes" ~target:(fun () -> Router.Note.destination ()) ~permanent:true;
  Router.redirect ~path:"/older-notes" ~target:(fun () -> Router.Note.destination ())
]
