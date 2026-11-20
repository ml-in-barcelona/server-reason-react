Router.make ~basePath:"/" ~context:Session.t [ Router.route Note ~page:Page ~path:"/note/:context<string>" ]
