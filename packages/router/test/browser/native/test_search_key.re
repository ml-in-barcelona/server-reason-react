switch (SearchKeyCases.failures(RouterSearchKey.isCurrent)) {
| [] => ()
| names =>
  failwith(
    "native and shared isCurrent answers differ: "
    ++ String.concat(", ", names),
  )
};
