With -js flag everything keeps as it is and effect extension disappears

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  React.useEffect
    (Js.log "ok";
     (None, [||]))
  
  let _ = None

Without -js flag, the compilation to native replaces the effect expression
with a no-op effect, raises in case of wrongly applied to other than an effect.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  React.useEffect0 (fun () -> None)
  
  let _ = [%ocaml.error "effect only accepts a useEffect expression"]
