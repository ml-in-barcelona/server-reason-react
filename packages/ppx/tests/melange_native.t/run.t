  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  external init : keycloak -> param:initParam -> init = "init" [@@mel.send]
  external makeInitParam : onLoad:string -> unit -> initParam = "" [@@mel.obj]
  
  let keycloak _ = raise (Failure "called Melange external @mel from native")
