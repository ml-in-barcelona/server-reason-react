switch (SearchKeyCases.failures(RouterSearchKey.isCurrent)) {
| [] => ()
| names =>
  failwith(
    "native and shared isCurrent answers differ: "
    ++ String.concat(", ", names),
  )
};

switch (SearchKeyCases.activeFailures(RouterSearchKey.isActive)) {
| [] => ()
| names =>
  failwith("native isActive answers differ: " ++ String.concat(", ", names))
};
