With -js flag everything keeps as it is and effect extension disappears

  $ refmt --parse re --print ml input.re > input.re.ml

  $ ../standalone.exe -impl input.re.ml -js | ocamlformat - --enable-outside-detected-project --impl
  (let _ = doServerSideLogic in
   doClientSideLogic ())
  [@alert "-browser_only"]
  ;;
  
  let value =
    (let _ = doServerSideLogic in
     doClientSideLogic ())
    [@alert "-browser_only"]
  
  let universal_fn () =
    (let _ = doServerSideLogic in
     doClientSideLogic ())
    [@alert "-browser_only"]
  
  let universal_fn_with_arg1 arg1 =
    (let _ = doServerSideLogic in
     let _ = arg1 in
     doClientSideLogic ())
    [@alert "-browser_only"]

Without -js flag, the compilation to native replaces the effect expression
with a no-op effect, raises in case of wrongly applied to other than an effect.

  $ ../standalone.exe -impl input.re.ml | ocamlformat - --enable-outside-detected-project --impl
  (let _ = doClientSideLogic in
   doServerSideLogic ())
  [@alert "-browser_only"]
  ;;
  
  let value =
    (let _ = doClientSideLogic in
     doServerSideLogic ())
    [@alert "-browser_only"]
  
  let universal_fn () =
    (let _ = doClientSideLogic in
     doServerSideLogic ())
    [@alert "-browser_only"]
  
  let universal_fn_with_arg1 arg1 =
    (let _ = doClientSideLogic in
     doServerSideLogic arg1)
    [@alert "-browser_only"]
