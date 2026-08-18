Router.make ~basePath:"/" [
  Router.route Note ~page:Page ~path:"/notes";
  Router.redirect ~path:"/notes" ~to_:(fun () -> Router.Note.destination ());
]
