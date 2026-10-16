Router.make ~basePath:"/" [
# 1 "app/about/page.mlx"
  Router.route About ~page:Page ~path:"/about";
# 1 "app/(marketing)/about/page.mlx"
  Router.route About2 ~page:Page ~path:"/about"
]
