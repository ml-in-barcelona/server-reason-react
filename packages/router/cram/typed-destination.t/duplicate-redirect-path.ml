Router.make ~basePath:"/" [
  Router.route Note ~page:Page ~path:"/notes";
  Router.redirect ~path:"/notes" ~target:(fun () -> Router.Note.destination ());
]
