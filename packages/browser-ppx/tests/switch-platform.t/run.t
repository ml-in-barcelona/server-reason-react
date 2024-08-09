With -js flag everything keeps as it is and effect extension disappears

  $ refmt --parse re --print ml input.re > input.re.ml

  $ ../standalone.exe -impl input.re.ml -js | ocamlformat - --enable-outside-detected-project --impl
  doClientSideLogic ()
  
  let value = doClientSideLogic ()
  let universal_fn () = doClientSideLogic ()
  let universal_fn_with_arg1 arg1 = doClientSideLogic ()

Without -js flag, the compilation to native replaces the effect expression
with a no-op effect, raises in case of wrongly applied to other than an effect.

  $ ../standalone.exe -impl input.re.ml | ocamlformat - --enable-outside-detected-project --impl
  doServerSideLogic ()
  
  let value = doServerSideLogic ()
  let universal_fn () = doServerSideLogic ()
  let universal_fn_with_arg1 arg1 = doServerSideLogic arg1
