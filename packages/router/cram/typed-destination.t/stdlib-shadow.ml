Router.make ~basePath:"/" [ Router.route Flag ~page:Page ~path:"/:string_of_int<int>/:string_of_bool<bool>" ]
