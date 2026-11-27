Router.make ~basePath:"/"
  [
    Router.route Member ~page:Page ~path:"/members/:id<int>";
    Router.group ~path:"/old/:id<int>"
      [ Router.redirect ~path:"/m/:id<int>" ~target:(fun ~id () -> Router.Member.destination ~id ()) ];
  ]
