Router.make ~basePath:"/"
  [
    Router.route Five ~page:FivePage ~path:"/:a?<int>/a1/b1/:b?<int>/a2/b2/:c?<int>/a3/b3/:d?<int>/a4/b4/:e?<int>/a5/b5";
  ]
